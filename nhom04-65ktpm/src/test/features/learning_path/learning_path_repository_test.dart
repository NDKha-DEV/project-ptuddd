import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlu_b1_daily/features/learning_path/data/models/assessment_result_model.dart';
import 'package:tlu_b1_daily/features/learning_path/data/models/skill_scores.dart';
import 'package:tlu_b1_daily/features/learning_path/data/repositories/learning_path_repository.dart';
import 'package:tlu_b1_daily/features/learning_path/domain/services/learning_path_generator.dart';

void main() {
  late LearningPathRepository repository;
  const testUid = 'supabase-user-01';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = LearningPathRepository(supabaseReady: false);
  });

  group('LearningPathRepository - lưu trữ cục bộ & trạng thái Supabase', () {
    test('chưa khởi tạo Supabase thì supabaseClient null và canSyncRemote false', () {
      expect(repository.supabaseReady, isFalse);
      expect(repository.supabaseClient, isNull);
      expect(repository.canSyncRemote(testUid), isFalse);
      expect(repository.canSyncRemote(''), isFalse);
    });

    test('lưu, tải và xóa lộ trình qua SharedPreferences theo uid', () async {
      const generator = LearningPathGenerator();
      final plan = generator.generate(
        LearningPathInput(
          startDate: DateTime(2026, 11, 20),
          examDate: DateTime(2026, 12, 18),
          dailyMinutes: 45,
          skillScores: SkillScores.baseline(),
        ),
      );

      expect(await repository.loadActivePlan(testUid), isNull);

      await repository.saveActivePlan(testUid, plan);
      final loaded = await repository.loadActivePlan(testUid);
      expect(loaded, isNotNull);
      expect(loaded!.totalWeeks, plan.totalWeeks);
      expect(loaded.dailyMinutes, 45);

      // Tách biệt dữ liệu giữa các tài khoản Supabase khác nhau
      expect(await repository.loadActivePlan('supabase-user-02'), isNull);

      await repository.clearActivePlan(testUid);
      expect(await repository.loadActivePlan(testUid), isNull);
    });

    test('lưu và tải kết quả khảo sát đầu vào', () async {
      final result = InitialAssessmentResult(
        examDate: '2026-12-20',
        dailyMinutes: 30,
        scores: SkillScores(
          listening: 55,
          reading: 60,
          writing: 45,
          speaking: 40,
        ),
        skippedMiniQuiz: false,
        assessedAt: DateTime.utc(2026, 11, 22, 10, 0),
      );

      await repository.saveAssessment(testUid, result);
      final loaded = await repository.loadLatestAssessment(testUid);
      expect(loaded, result);
    });

    test('trả về danh sách tài liệu, bài tập, tour mẫu và lưu quan tâm tour', () async {
      final materials = await repository.fetchAvailableMaterials();
      final exercises = await repository.fetchAvailableExercises();
      final tours = await repository.fetchEnglishTours();
      final questions = repository.getMiniDiagnosticQuestions();

      expect(materials, isNotEmpty);
      expect(exercises, isNotEmpty);
      expect(tours, isNotEmpty);
      expect(questions.length, 10);

      final afterSave = await repository.toggleSavedTour(
        testUid,
        tours.first.tourId,
      );
      expect(afterSave, contains(tours.first.tourId));

      final afterRemove = await repository.toggleSavedTour(
        testUid,
        tours.first.tourId,
      );
      expect(afterRemove, isNot(contains(tours.first.tourId)));
    });
  });
}
