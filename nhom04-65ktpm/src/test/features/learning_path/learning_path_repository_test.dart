import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlu_b1_daily/features/learning_path/data/models/assessment_result_model.dart';
import 'package:tlu_b1_daily/features/learning_path/data/models/skill_scores.dart';
import 'package:tlu_b1_daily/features/learning_path/data/repositories/learning_path_repository.dart';
import 'package:tlu_b1_daily/features/learning_path/domain/services/learning_path_generator.dart';

void main() {
  late LearningPathRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = LearningPathRepository(firebaseReady: false);
  });

  group('LearningPathRepository - chế độ offline/guest', () {
    test('lưu, tải và xóa lộ trình qua SharedPreferences', () async {
      const generator = LearningPathGenerator();
      final plan = generator.generate(
        LearningPathInput(
          startDate: DateTime(2026, 11, 20),
          examDate: DateTime(2026, 12, 18),
          dailyMinutes: 45,
          skillScores: SkillScores.baseline(),
        ),
      );

      expect(await repository.loadActivePlan('guest'), isNull);

      await repository.saveActivePlan('guest', plan);
      final loaded = await repository.loadActivePlan('guest');
      expect(loaded, isNotNull);
      expect(loaded!.totalWeeks, plan.totalWeeks);
      expect(loaded.dailyMinutes, 45);

      await repository.clearActivePlan('guest');
      expect(await repository.loadActivePlan('guest'), isNull);
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

      await repository.saveAssessment('guest', result);
      final loaded = await repository.loadLatestAssessment('guest');
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
        'guest',
        tours.first.tourId,
      );
      expect(afterSave, contains(tours.first.tourId));

      final afterRemove = await repository.toggleSavedTour(
        'guest',
        tours.first.tourId,
      );
      expect(afterRemove, isNot(contains(tours.first.tourId)));
    });
  });
}
