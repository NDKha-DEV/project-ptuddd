import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlu_b1_daily/features/learning_path/data/models/daily_task_model.dart';
import 'package:tlu_b1_daily/features/learning_path/data/models/skill_scores.dart';
import 'package:tlu_b1_daily/features/learning_path/data/repositories/learning_path_repository.dart';
import 'package:tlu_b1_daily/features/learning_path/presentation/providers/learning_path_provider.dart';

void main() {
  late LearningPathRepository repository;
  late DateTime fakeNow;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = LearningPathRepository(firebaseReady: false);
    fakeNow = DateTime(2026, 11, 23, 9, 0);
  });

  LearningPathProvider createProvider({String uid = 'guest'}) {
    return LearningPathProvider(
      repository: repository,
      nowProvider: () => fakeNow,
      initialUid: uid,
    );
  }

  group('LearningPathProvider - tính điểm khảo sát', () {
    test('skipMiniQuiz dùng thẳng điểm quy đổi từ mức tự tin 1..5', () {
      final scores = LearningPathProvider.computeAssessmentScores(
        confidenceLevels: const {
          SkillType.listening: 1, // 25
          SkillType.reading: 3, // 55
          SkillType.writing: 4, // 70
          SkillType.speaking: 5, // 85
        },
        quizAnswers: const {},
        questions: repository.getMiniDiagnosticQuestions(),
        skipMiniQuiz: true,
      );

      expect(scores.listening, 25);
      expect(scores.reading, 55);
      expect(scores.writing, 70);
      expect(scores.speaking, 85);
    });

    test('có làm mini-quiz sẽ kết hợp 40% tự tin + 60% điểm quiz theo từng kỹ năng', () {
      final questions = repository.getMiniDiagnosticQuestions();
      // Trả lời đúng toàn bộ câu hỏi trong mini-quiz -> quizPercent = 100
      final allCorrectAnswers = {
        for (final q in questions) q.id: q.correctIndex,
      };

      final scores = LearningPathProvider.computeAssessmentScores(
        confidenceLevels: const {
          SkillType.listening: 2, // 40 -> 0.4*40 + 0.6*100 = 76
          SkillType.reading: 3, // 55 -> 0.4*55 + 0.6*100 = 82
          SkillType.writing: 1, // 25 -> 0.4*25 + 0.6*100 = 70
          SkillType.speaking: 5, // 85 -> 0.4*85 + 0.6*100 = 94
        },
        quizAnswers: allCorrectAnswers,
        questions: questions,
        skipMiniQuiz: false,
      );

      expect(scores.listening, 76);
      expect(scores.reading, 82);
      expect(scores.writing, 70);
      expect(scores.speaking, 94);
    });
  });

  group('LearningPathProvider - luồng dữ liệu & thao tác lộ trình', () {
    test('loadInitialData tải tour, câu hỏi khảo sát và chưa có lộ trình ban đầu', () async {
      final provider = createProvider();
      await provider.loadInitialData();

      expect(provider.isLoading, isFalse);
      expect(provider.hasActivePlan, isFalse);
      expect(provider.tours, isNotEmpty);
      expect(provider.miniDiagnosticQuestions.length, 10);
      expect(provider.daysUntilExam, isNull);
    });

    test('createPlanFromAssessment tạo, lưu lộ trình và tính daysUntilExam chính xác', () async {
      final provider = createProvider();
      await provider.loadInitialData();

      final plan = await provider.createPlanFromAssessment(
        examDate: DateTime(2026, 12, 21), // +28 ngày -> 4 tuần
        dailyMinutes: 45,
        confidenceLevels: const {
          SkillType.listening: 2,
          SkillType.reading: 4,
          SkillType.writing: 3,
          SkillType.speaking: 1,
        },
        skipMiniQuiz: true,
      );

      expect(plan, isNotNull);
      expect(provider.hasActivePlan, isTrue);
      expect(provider.activePlan!.totalWeeks, 4);
      expect(provider.activePlan!.dailyMinutes, 45);
      expect(provider.daysUntilExam, 28);
      expect(provider.selectedWeekNumber, 1);

      // Tạo provider mới cùng uid để kiểm tra đã lưu bền vững vào repository.
      final reloaded = createProvider();
      await reloaded.loadInitialData();
      expect(reloaded.hasActivePlan, isTrue);
      expect(reloaded.activePlan!.examDate, '2026-12-21');
      expect(reloaded.latestAssessment, isNotNull);
    });

    test('toggleTaskCompletion cập nhật completionRate, callback và giữ lại sau reload', () async {
      final provider = createProvider();
      await provider.createPlanFromAssessment(
        examDate: DateTime(2026, 12, 7),
        dailyMinutes: 30,
        confidenceLevels: const {
          SkillType.listening: 2,
          SkillType.reading: 3,
          SkillType.writing: 3,
          SkillType.speaking: 2,
        },
        skipMiniQuiz: true,
      );

      final firstTask = provider.activePlan!.weeks.first.days.first.tasks.first;
      DailyTask? callbackTask;
      bool? callbackCompleted;

      await provider.toggleTaskCompletion(
        firstTask.taskId,
        onTaskToggled: (task, completed) {
          callbackTask = task;
          callbackCompleted = completed;
        },
      );

      expect(callbackTask?.taskId, firstTask.taskId);
      expect(callbackCompleted, isTrue);
      expect(provider.activePlan!.completionRate, greaterThan(0));
      expect(
        provider.activePlan!.weeks.first.days.first.tasks.first.isCompleted,
        isTrue,
      );

      // Mở lại (un-complete)
      await provider.toggleTaskCompletion(firstTask.taskId);
      expect(provider.activePlan!.completionRate, 0.0);
    });

    test('applyExerciseAttempt cập nhật điểm M3 và bảo toàn ngày đã hoàn thành', () async {
      final provider = createProvider();
      await provider.createPlanFromAssessment(
        examDate: DateTime(2026, 12, 21),
        dailyMinutes: 45,
        confidenceLevels: const {
          SkillType.listening: 4, // 70
          SkillType.reading: 4, // 70
          SkillType.writing: 3, // 55
          SkillType.speaking: 3, // 55
        },
        skipMiniQuiz: true,
      );

      // Hoàn thành toàn bộ ngày 1 trước khi nhận kết quả thấp từ M3.
      for (final task in provider.activePlan!.weeks.first.days.first.tasks) {
        await provider.toggleTaskCompletion(task.taskId);
      }
      expect(provider.activePlan!.weeks.first.days.first.isCompleted, isTrue);

      await provider.applyExerciseAttempt(
        skill: SkillType.listening,
        scorePercent: 20, // 0.4*70 + 0.6*20 = 40 < 60 -> kích hoạt tái cân bằng
      );

      expect(provider.activePlan!.currentScores.listening, 40);
      expect(provider.activePlan!.weeks.first.days.first.isCompleted, isTrue);
    });

    test('rescheduleSettings và resetPlan hoạt động đúng', () async {
      final provider = createProvider();
      await provider.createPlanFromAssessment(
        examDate: DateTime(2026, 12, 21),
        dailyMinutes: 30,
        confidenceLevels: const {
          SkillType.listening: 3,
          SkillType.reading: 3,
          SkillType.writing: 3,
          SkillType.speaking: 3,
        },
        skipMiniQuiz: true,
      );

      await provider.rescheduleSettings(
        dailyMinutes: 60,
        examDate: DateTime(2026, 12, 14),
      );
      expect(provider.activePlan!.dailyMinutes, 60);
      expect(provider.activePlan!.examDate, '2026-12-14');

      await provider.resetPlan();
      expect(provider.hasActivePlan, isFalse);
      expect(provider.selectedWeekNumber, 1);
    });

    test('toggleSavedTour, lọc tour cuối tuần và syncUid tách dữ liệu theo user', () async {
      final provider = createProvider(uid: 'user_a');
      await provider.loadInitialData();

      final firstTourId = provider.tours.first.tourId;
      await provider.toggleSavedTour(firstTourId);
      expect(provider.isTourSaved(firstTourId), isTrue);

      provider.setWeekendToursOnly(true);
      expect(provider.filteredTours.every((t) => t.isWeekend), isTrue);

      await provider.syncUid('user_b');
      expect(provider.uid, 'user_b');
      expect(provider.isTourSaved(firstTourId), isFalse);
    });
  });
}
