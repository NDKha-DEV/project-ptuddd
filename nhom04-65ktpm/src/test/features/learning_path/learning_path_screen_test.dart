import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlu_b1_daily/features/learning_path/data/models/daily_task_model.dart';
import 'package:tlu_b1_daily/features/learning_path/data/models/skill_scores.dart';
import 'package:tlu_b1_daily/features/learning_path/data/repositories/learning_path_repository.dart';
import 'package:tlu_b1_daily/features/learning_path/presentation/providers/learning_path_provider.dart';
import 'package:tlu_b1_daily/features/learning_path/presentation/screens/learning_path_screen.dart';

void main() {
  late LearningPathRepository repository;
  late LearningPathProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = LearningPathRepository(firebaseReady: false);
    provider = LearningPathProvider(
      repository: repository,
      nowProvider: () => DateTime(2026, 11, 23, 9, 0),
    );
  });

  Widget buildSubject({
    ValueChanged<DailyTask>? onOpenTask,
    VoidCallback? onOpenSurvey,
    VoidCallback? onOpenTours,
  }) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        home: LearningPathScreen(
          onOpenTask: onOpenTask,
          onOpenSurvey: onOpenSurvey,
          onOpenTours: onOpenTours,
        ),
      ),
    );
  }

  group('LearningPathScreen', () {
    testWidgets('hiển thị trạng thái chưa có lộ trình và nút bắt đầu khảo sát', (
      tester,
    ) async {
      var surveyOpened = false;
      var toursOpened = false;

      await tester.pumpWidget(
        buildSubject(
          onOpenSurvey: () => surveyOpened = true,
          onOpenTours: () => toursOpened = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có lộ trình B1 cá nhân'), findsOneWidget);
      await tester.tap(find.text('Bắt đầu khảo sát tạo lộ trình'));
      await tester.pump();
      expect(surveyOpened, isTrue);

      await tester.tap(find.textContaining('Tour dẫn tiếng Anh'));
      await tester.pump();
      expect(toursOpened, isTrue);
    });

    testWidgets('hiển thị lộ trình theo tuần, chuyển tuần, tick hoàn thành và mở nhiệm vụ', (
      tester,
    ) async {
      await provider.loadInitialData();
      await provider.createPlanFromAssessment(
        examDate: DateTime(2026, 12, 21), // 4 tuần
        dailyMinutes: 30,
        confidenceLevels: const {
          SkillType.listening: 2,
          SkillType.reading: 4,
          SkillType.writing: 3,
          SkillType.speaking: 1,
        },
        skipMiniQuiz: true,
      );

      DailyTask? openedTask;
      await tester.pumpWidget(
        buildSubject(onOpenTask: (task) => openedTask = task),
      );
      await tester.pumpAndSettle();

      expect(find.text('Còn 28 ngày tới kỳ thi B1'), findsOneWidget);
      expect(find.text('Tiến độ tổng thể: 0%'), findsOneWidget);
      expect(find.text('Tuần 1'), findsOneWidget);
      expect(find.text('Hôm nay'), findsOneWidget);

      // Tick hoàn thành nhiệm vụ đầu tiên của ngày hôm nay
      final verticalScroll = find.byType(Scrollable).first;
      final firstCheckbox = find.byType(Checkbox).first;
      await tester.scrollUntilVisible(
        firstCheckbox,
        200,
        scrollable: verticalScroll,
      );
      await tester.pumpAndSettle();
      await tester.tap(firstCheckbox);
      await tester.pumpAndSettle();
      expect(provider.activePlan!.completionRate, greaterThan(0));

      // Bấm Học ngay để kiểm tra callback điều hướng M2/M3
      final learnNow = find.text('Học ngay').first;
      await tester.scrollUntilVisible(
        learnNow,
        150,
        scrollable: verticalScroll,
      );
      await tester.pumpAndSettle();
      await tester.tap(learnNow);
      await tester.pump();
      expect(openedTask, isNotNull);

      // Chuyển sang Tuần 2
      final week2 = find.text('Tuần 2');
      await tester.scrollUntilVisible(
        week2,
        -200,
        scrollable: verticalScroll,
      );
      await tester.pumpAndSettle();
      await tester.tap(week2);
      await tester.pumpAndSettle();
      expect(provider.selectedWeekNumber, 2);
      expect(find.textContaining('Ngày 8'), findsOneWidget);
    });

    testWidgets('mở bottom sheet Phân tích 4 kỹ năng hiển thị SkillSummaryCard', (
      tester,
    ) async {
      await provider.loadInitialData();
      await provider.createPlanFromAssessment(
        examDate: DateTime(2026, 12, 21),
        dailyMinutes: 45,
        confidenceLevels: const {
          SkillType.listening: 2,
          SkillType.reading: 4,
          SkillType.writing: 3,
          SkillType.speaking: 1,
        },
        skipMiniQuiz: true,
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Phân tích 4 kỹ năng'));
      await tester.pumpAndSettle();

      expect(find.text('Phân tích 4 kỹ năng B1'), findsOneWidget);
      expect(find.text('Ưu tiên'), findsOneWidget);
    });
  });
}
