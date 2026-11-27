import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/services/learning_path_generator.dart';
import '../models/assessment_result_model.dart';
import '../models/daily_task_model.dart';
import '../models/english_tour_model.dart';
import '../models/learning_path_model.dart';
import '../models/skill_scores.dart';

/// Kho lưu trữ dữ liệu cho M4 (Firestore khi online + SharedPreferences fallback khi offline/guest).
class LearningPathRepository {
  LearningPathRepository({
    this.firebaseReady = false,
    this.firestore,
  });

  final bool firebaseReady;
  final FirebaseFirestore? firestore;

  bool _canUseFirestore(String uid) =>
      firebaseReady && uid.isNotEmpty && uid != 'guest';

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  String _planKey(String uid, String planId) => 'm4_plan_${uid}_$planId';
  String _assessmentKey(String uid) => 'm4_assessment_$uid';
  String _savedToursKey(String uid) => 'm4_saved_tours_$uid';

  /// Tải lộ trình đang hoạt động của sinh viên.
  Future<LearningPath?> loadActivePlan(
    String uid, {
    String planId = 'active_plan',
  }) async {
    if (_canUseFirestore(uid)) {
      try {
        final doc = await _db
            .collection(FirestoreCollections.users)
            .doc(uid)
            .collection(FirestoreCollections.learningPaths)
            .doc(planId)
            .get();
        if (doc.exists && doc.data() != null) {
          final plan = LearningPath.fromJson(doc.data()!);
          await _savePlanLocally(uid, plan);
          return plan;
        }
      } catch (_) {
        // Fallback sang bộ nhớ cục bộ nếu mất mạng hoặc chưa cấu hình rules.
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_planKey(uid, planId));
    if (raw == null || raw.isEmpty) return null;
    return LearningPath.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  /// Lưu lộ trình vào local cache và đồng bộ Firestore nếu đã đăng nhập Firebase.
  Future<void> saveActivePlan(String uid, LearningPath plan) async {
    await _savePlanLocally(uid, plan);

    if (_canUseFirestore(uid)) {
      try {
        await _db
            .collection(FirestoreCollections.users)
            .doc(uid)
            .collection(FirestoreCollections.learningPaths)
            .doc(plan.planId)
            .set(plan.toJson());
      } catch (_) {
        // Giữ bản local để không làm gián đoạn trải nghiệm offline.
      }
    }
  }

  Future<void> _savePlanLocally(String uid, LearningPath plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planKey(uid, plan.planId), jsonEncode(plan.toJson()));
  }

  /// Xóa lộ trình hiện tại để người dùng khảo sát lại từ đầu.
  Future<void> clearActivePlan(
    String uid, {
    String planId = 'active_plan',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_planKey(uid, planId));

    if (_canUseFirestore(uid)) {
      try {
        await _db
            .collection(FirestoreCollections.users)
            .doc(uid)
            .collection(FirestoreCollections.learningPaths)
            .doc(planId)
            .delete();
      } catch (_) {
        // Bỏ qua lỗi mạng khi xóa bản remote.
      }
    }
  }

  /// Lưu và tải kết quả khảo sát đầu vào gần nhất.
  Future<void> saveAssessment(
    String uid,
    InitialAssessmentResult result,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_assessmentKey(uid), jsonEncode(result.toJson()));
  }

  Future<InitialAssessmentResult?> loadLatestAssessment(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_assessmentKey(uid));
    if (raw == null || raw.isEmpty) return null;
    return InitialAssessmentResult.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  /// Lấy danh sách học liệu M2 phục vụ gắn link nhiệm vụ.
  Future<List<LearningResourceRef>> fetchAvailableMaterials() async {
    if (firebaseReady) {
      try {
        final snapshot = await _db
            .collection(FirestoreCollections.b1Materials)
            .limit(30)
            .get();
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return LearningResourceRef(
              id: doc.id,
              title: data['title'] as String? ?? 'Tài liệu B1',
              skill: SkillType.fromKey(data['skill'] as String?),
              targetModule: TargetModule.m2,
            );
          }).toList();
        }
      } catch (_) {
        // Fallback sang bộ tài liệu mẫu.
      }
    }
    return _sampleMaterials;
  }

  /// Lấy danh sách bài tập M3 phục vụ gắn link nhiệm vụ.
  Future<List<LearningResourceRef>> fetchAvailableExercises() async {
    if (firebaseReady) {
      try {
        final snapshot = await _db
            .collection(FirestoreCollections.b1Exercises)
            .limit(30)
            .get();
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return LearningResourceRef(
              id: doc.id,
              title: data['title'] as String? ?? 'Bài tập B1',
              skill: SkillType.fromKey(data['skill'] as String?),
              targetModule: TargetModule.m3,
            );
          }).toList();
        }
      } catch (_) {
        // Fallback sang bộ bài tập mẫu.
      }
    }
    return _sampleExercises;
  }

  /// Lấy danh sách tour dẫn tiếng Anh / CLB giao lưu tại Hà Nội.
  Future<List<EnglishTour>> fetchEnglishTours() async {
    if (firebaseReady) {
      try {
        final snapshot = await _db
            .collection(FirestoreCollections.englishTours)
            .get();
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs
              .map(
                (doc) => EnglishTour.fromJson({
                  'tourId': doc.id,
                  ...doc.data(),
                }),
              )
              .toList();
        }
      } catch (_) {
        // Fallback sang danh sách tour mẫu.
      }
    }
    return _sampleTours;
  }

  /// Lấy danh sách ID tour đã lưu quan tâm.
  Future<List<String>> loadSavedTourIds(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_savedToursKey(uid)) ?? const [];
  }

  /// Thêm hoặc bỏ lưu quan tâm một tour tiếng Anh.
  Future<List<String>> toggleSavedTour(String uid, String tourId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = List<String>.from(
      prefs.getStringList(_savedToursKey(uid)) ?? const [],
    );
    if (current.contains(tourId)) {
      current.remove(tourId);
    } else {
      current.add(tourId);
    }
    await prefs.setStringList(_savedToursKey(uid), current);

    final activePlan = await loadActivePlan(uid);
    if (activePlan != null) {
      await saveActivePlan(uid, activePlan.copyWith(savedTourIds: current));
    }
    return current;
  }

  /// Bộ 10 câu kiểm tra nhanh năng lực nền tảng B1 (Mini Diagnostic).
  List<MiniDiagnosticQuestion> getMiniDiagnosticQuestions() =>
      _miniDiagnosticQuestions;

  static const List<LearningResourceRef> _sampleMaterials = [
    LearningResourceRef(
      id: 'mat_vocab_01',
      title: 'Từ vựng chủ đề Sinh hoạt & Học tập B1',
      skill: SkillType.vocabulary,
      targetModule: TargetModule.m2,
    ),
    LearningResourceRef(
      id: 'mat_vocab_02',
      title: 'Từ vựng chủ đề Du lịch & Giao tiếp Hà Nội',
      skill: SkillType.vocabulary,
      targetModule: TargetModule.m2,
    ),
    LearningResourceRef(
      id: 'mat_grammar_01',
      title: 'Ngữ pháp cốt lõi: Thì & Mệnh đề quan hệ B1',
      skill: SkillType.reading,
      targetModule: TargetModule.m2,
    ),
    LearningResourceRef(
      id: 'mat_listen_01',
      title: 'Chiến lược nghe hiểu hội thoại & thông báo ngắn B1',
      skill: SkillType.listening,
      targetModule: TargetModule.m2,
    ),
    LearningResourceRef(
      id: 'mat_write_01',
      title: 'Mẫu câu & bố cục viết Email/Thư B1 Thủy Lợi',
      skill: SkillType.writing,
      targetModule: TargetModule.m2,
    ),
    LearningResourceRef(
      id: 'mat_speak_01',
      title: 'Dàn ý trả lời Nói Part 1–3 chủ đề quen thuộc',
      skill: SkillType.speaking,
      targetModule: TargetModule.m2,
    ),
  ];

  static const List<LearningResourceRef> _sampleExercises = [
    LearningResourceRef(
      id: 'ex_listen_01',
      title: 'Luyện Nghe Part 1 – Hội thoại ngắn B1',
      skill: SkillType.listening,
      targetModule: TargetModule.m3,
    ),
    LearningResourceRef(
      id: 'ex_read_01',
      title: 'Luyện Đọc hiểu – Tìm ý chính & từ đồng nghĩa',
      skill: SkillType.reading,
      targetModule: TargetModule.m3,
    ),
    LearningResourceRef(
      id: 'ex_write_01',
      title: 'Luyện Viết đoạn văn ngắn & Email B1',
      skill: SkillType.writing,
      targetModule: TargetModule.m3,
    ),
    LearningResourceRef(
      id: 'ex_speak_01',
      title: 'Thực hành Nói theo chủ đề & checklist phát âm',
      skill: SkillType.speaking,
      targetModule: TargetModule.m3,
    ),
  ];

  static const List<EnglishTour> _sampleTours = [
    EnglishTour(
      tourId: 'tour_hanoi_free_walking_01',
      title: 'Hanoi Free Walking Tour – Khu phố cổ & Hồ Hoàn Kiếm',
      organizer: 'Hanoi Kids / CLB Hướng dẫn viên tình nguyện',
      scheduleText: 'Thứ Bảy & Chủ Nhật hằng tuần, 08:30 – 11:30',
      location: 'Tượng đài Lý Thái Tổ, Hoàn Kiếm, Hà Nội',
      levelRecommended: 'A2–B1',
      samplePhrases: [
        'Welcome to Hanoi! Let me introduce a bit about this historic area.',
        'Would you like me to explain the story behind Ngoc Son Temple?',
        'Feel free to ask me any questions about local street food!',
      ],
      sourceUrl: 'https://hanoikids.org',
      lastVerifiedAt: '2026-11-18',
    ),
    EnglishTour(
      tourId: 'tour_tlu_speaking_club_02',
      title: 'CLB Giao tiếp Tiếng Anh Cuối Tuần – Công viên Thống Nhất',
      organizer: 'Nhóm Sinh viên Giao lưu Ngoại ngữ Hà Nội',
      scheduleText: 'Chủ Nhật hằng tuần, 15:00 – 17:00',
      location: 'Cổng chính Công viên Thống Nhất, Hai Bà Trưng, Hà Nội',
      levelRecommended: 'B1',
      samplePhrases: [
        'Hi there! What brings you to Hanoi this season?',
        'How long have you been travelling around Vietnam?',
      ],
      sourceUrl: 'https://example.org/tlu-english-club',
      lastVerifiedAt: '2026-11-18',
    ),
    EnglishTour(
      tourId: 'tour_temple_literature_03',
      title: 'Thực hành dẫn tour Văn Miếu – Quốc Tử Giám',
      organizer: 'Hanoi Free Private Tour Guide',
      scheduleText: 'Thứ Năm & Thứ Bảy, 09:00 – 11:30',
      location: '58 Quốc Tử Giám, Đống Đa, Hà Nội',
      levelRecommended: 'B1–B2',
      samplePhrases: [
        'This is the Temple of Literature, Vietnam’s first national university.',
        'It was built in 1070 under the Ly Dynasty.',
      ],
      sourceUrl: 'https://example.org/hanoi-temple-tour',
      lastVerifiedAt: '2026-11-18',
    ),
  ];

  static const List<MiniDiagnosticQuestion> _miniDiagnosticQuestions = [
    MiniDiagnosticQuestion(
      id: 'q1',
      skill: SkillType.reading,
      prompt: 'Choose the best word: "She ____ to the library every afternoon."',
      options: ['go', 'goes', 'going', 'gone'],
      correctIndex: 1,
    ),
    MiniDiagnosticQuestion(
      id: 'q2',
      skill: SkillType.reading,
      prompt: '"Notice: The exam room opens at 7:30." What does it mean?',
      options: [
        'Students can enter at 7:30.',
        'The exam finishes at 7:30.',
        'The room is closed all day.',
        'Students must leave at 7:30.',
      ],
      correctIndex: 0,
    ),
    MiniDiagnosticQuestion(
      id: 'q3',
      skill: SkillType.reading,
      prompt: 'Find the synonym of "essential" in academic B1 reading:',
      options: ['optional', 'necessary', 'difficult', 'expensive'],
      correctIndex: 1,
    ),
    MiniDiagnosticQuestion(
      id: 'q4',
      skill: SkillType.listening,
      prompt:
          'Audio script: "Could you turn down the volume? I am studying." The speaker wants:',
      options: [
        'louder music',
        'quieter sound',
        'a new radio',
        'to go outside',
      ],
      correctIndex: 1,
    ),
    MiniDiagnosticQuestion(
      id: 'q5',
      skill: SkillType.listening,
      prompt:
          'Audio script: "The train to Hai Phong departs from Platform 3 at 8:15." When does it leave?',
      options: ['7:45', '8:00', '8:15', '8:30'],
      correctIndex: 2,
    ),
    MiniDiagnosticQuestion(
      id: 'q6',
      skill: SkillType.listening,
      prompt:
          'Audio script: "I forgot my umbrella, so I got wet on the way to class." Why did he get wet?',
      options: [
        'He lost his bag.',
        'It rained and he had no umbrella.',
        'He swam in the pool.',
        'The bus was late.',
      ],
      correctIndex: 1,
    ),
    MiniDiagnosticQuestion(
      id: 'q7',
      skill: SkillType.writing,
      prompt: 'Which closing is most suitable for a semi-formal email to a teacher?',
      options: ['See ya!', 'Best regards,', 'Bye bye,', 'Yours madly,'],
      correctIndex: 1,
    ),
    MiniDiagnosticQuestion(
      id: 'q8',
      skill: SkillType.writing,
      prompt: 'Complete the sentence: "Although it was raining, ____."',
      options: [
        'but we went out',
        'we still attended the seminar',
        'so we stayed home',
        'because we were tired',
      ],
      correctIndex: 1,
    ),
    MiniDiagnosticQuestion(
      id: 'q9',
      skill: SkillType.speaking,
      prompt: 'In B1 Speaking Part 1, how should you answer "Where do you live?"',
      options: [
        'Just say "Hanoi."',
        'Give a 2–3 sentence answer with a reason or detail.',
        'Stay silent for 10 seconds.',
        'Ask the examiner back immediately.',
      ],
      correctIndex: 1,
    ),
    MiniDiagnosticQuestion(
      id: 'q10',
      skill: SkillType.speaking,
      prompt: 'Which phrase helps you buy time naturally while thinking in Speaking?',
      options: [
        'That is an interesting question, let me think for a moment.',
        'I do not know anything.',
        'Next question please.',
        'No comment.',
      ],
      correctIndex: 0,
    ),
  ];
}
