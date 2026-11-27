import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tlu_b1_daily/features/learning_path/data/models/daily_task_model.dart';
import 'package:tlu_b1_daily/features/learning_path/data/models/learning_path_model.dart';
import 'package:tlu_b1_daily/features/learning_path/data/models/skill_scores.dart';
import 'package:tlu_b1_daily/features/learning_path/presentation/widgets/day_task_card.dart';
import 'package:tlu_b1_daily/features/learning_path/presentation/widgets/skill_summary_card.dart';
import 'package:tlu_b1_daily/features/learning_path/presentation/widgets/week_selector.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('SkillSummaryCard', () {
    testWidgets('hiển thị điểm 4 kỹ năng, nhãn ưu tiên kỹ năng yếu nhất và delta', (
      tester,
    ) async {
      final initial = SkillScores(
        listening: 35,
        reading: 60,
        writing: 50,
        speaking: 72,
      );
      final current = SkillScores(
        listening: 40,
        reading: 60,
        writing: 50,
        speaking: 72,
      );

      await tester.pumpWidget(
        wrap(SkillSummaryCard(currentScores: current, initialScores: initial)),
      );

      expect(find.text('Phân tích 4 kỹ năng B1'), findsOneWidget);
      expect(find.text('Nghe'), findsOneWidget);
      expect(find.text('40/100'), findsOneWidget);
      expect(find.text('+5'), findsOneWidget);
      expect(find.text('Ưu tiên'), findsOneWidget);
      expect(find.text('Cần củng cố nền tảng'), findsOneWidget);
      expect(find.text('Khá tốt – duy trì & nâng cao'), findsOneWidget);
    });
  });

  group('WeekSelector', () {
    testWidgets('hiển thị danh sách tuần và gọi callback khi chọn tuần khác', (
      tester,
    ) async {
      final weeks = [
        WeekPlan(
          weekNumber: 1,
          title: 'Tuần 1',
          phase: LearningPhase.foundation,
          days: [
            DayPlan(
              dayIndex: 1,
              date: '2026-11-23',
              focusSkill: SkillType.listening,
              totalMinutes: 30,
              tasks: const [
                DailyTask(
                  taskId: 't1',
                  title: 'Task 1',
                  skill: SkillType.listening,
                  targetModule: TargetModule.m3,
                  targetResourceId: 'ex_1',
                  estimatedMinutes: 30,
                  status: TaskStatus.completed,
                ),
              ],
            ),
          ],
        ),
        const WeekPlan(
          weekNumber: 2,
          title: 'Tuần 2',
          phase: LearningPhase.focus,
          days: [],
        ),
      ];

      int? tappedWeek;
      await tester.pumpWidget(
        wrap(
          WeekSelector(
            weeks: weeks,
            selectedWeekNumber: 1,
            currentWeekNumber: 1,
            onWeekSelected: (week) => tappedWeek = week,
          ),
        ),
      );

      expect(find.text('Tuần 1'), findsOneWidget);
      expect(find.text('Hoàn thành'), findsOneWidget);
      expect(find.text('Tuần 2'), findsOneWidget);

      await tester.tap(find.text('Tuần 2'));
      await tester.pump();
      expect(tappedWeek, 2);
    });
  });

  group('DayTaskCard', () {
    testWidgets('mở rộng ngày hôm nay, kích hoạt toggle checkbox và nút Học ngay', (
      tester,
    ) async {
      const day = DayPlan(
        dayIndex: 1,
        date: '2026-11-23',
        focusSkill: SkillType.vocabulary,
        totalMinutes: 30,
        tasks: [
          DailyTask(
            taskId: 'w1_d1_t1',
            title: 'Từ vựng B1 chủ đề Sinh hoạt',
            skill: SkillType.vocabulary,
            targetModule: TargetModule.m2,
            targetResourceId: 'mat_vocab_01',
            estimatedMinutes: 15,
          ),
          DailyTask(
            taskId: 'w1_d1_t2',
            title: 'Luyện Nghe Part 1',
            skill: SkillType.listening,
            targetModule: TargetModule.m3,
            targetResourceId: 'ex_listen_01',
            estimatedMinutes: 15,
          ),
        ],
      );

      DailyTask? toggledTask;
      DailyTask? openedTask;

      await tester.pumpWidget(
        wrap(
          DayTaskCard(
            day: day,
            isToday: true,
            onToggleTask: (task) => toggledTask = task,
            onOpenTask: (task) => openedTask = task,
          ),
        ),
      );

      expect(find.text('Ngày 1 · 2026-11-23'), findsOneWidget);
      expect(find.text('Hôm nay'), findsOneWidget);
      expect(find.text('Từ vựng B1 chủ đề Sinh hoạt'), findsOneWidget);
      expect(find.text('M2 Tài liệu'), findsOneWidget);
      expect(find.text('M3 Bài tập'), findsOneWidget);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      expect(toggledTask?.taskId, 'w1_d1_t1');

      await tester.tap(find.text('Học ngay').last);
      await tester.pump();
      expect(openedTask?.taskId, 'w1_d1_t2');
    });
  });
}
