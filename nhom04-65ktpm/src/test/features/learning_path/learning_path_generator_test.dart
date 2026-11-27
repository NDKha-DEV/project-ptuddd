import 'package:flutter_test/flutter_test.dart';

import 'package:tlu_b1_daily/features/learning_path/data/models/daily_task_model.dart';
import 'package:tlu_b1_daily/features/learning_path/data/models/learning_path_model.dart';
import 'package:tlu_b1_daily/features/learning_path/data/models/skill_scores.dart';
import 'package:tlu_b1_daily/features/learning_path/domain/services/learning_path_generator.dart';

void main() {
  const generator = LearningPathGenerator();
  final start = DateTime(2026, 11, 20);

  group('LearningPathGenerator - quỹ thời gian 30/45/60 phút', () {
    for (final minutes in [30, 45, 60]) {
      test('tổng phút mỗi ngày khớp đúng mục tiêu $minutes phút', () {
        final plan = generator.generate(
          LearningPathInput(
            startDate: start,
            examDate: start.add(const Duration(days: 28)),
            dailyMinutes: minutes,
            skillScores: SkillScores(
              listening: 50,
              reading: 60,
              writing: 45,
              speaking: 40,
            ),
          ),
        );

        expect(plan.dailyMinutes, minutes);
        expect(plan.totalWeeks, 4);

        for (final week in plan.weeks) {
          for (final day in week.days) {
            final taskSum = day.tasks.fold<int>(
              0,
              (sum, task) => sum + task.estimatedMinutes,
            );
            expect(day.totalMinutes, minutes);
            expect(taskSum, minutes);
          }
        }
      });
    }
  });

  group('LearningPathGenerator - biên examDate & chia chặng', () {
    test('sát ngày thi (< 7 ngày) kích hoạt chế độ nước rút 7 ngày', () {
      final plan = generator.generate(
        LearningPathInput(
          startDate: start,
          examDate: start.add(const Duration(days: 4)),
          dailyMinutes: 45,
          skillScores: SkillScores.baseline(),
        ),
      );

      expect(plan.totalWeeks, 1);
      expect(plan.weeks.first.days.length, 7);
      expect(plan.weeks.first.phase, LearningPhase.review);
      expect(plan.weeks.first.title, contains('nước rút 7 ngày'));
    });

    test('trung hạn 4 tuần và dài hạn 12 tuần có đủ 3 chặng', () {
      final midPlan = generator.generate(
        LearningPathInput(
          startDate: start,
          examDate: start.add(const Duration(days: 28)),
          dailyMinutes: 45,
          skillScores: SkillScores.baseline(),
        ),
      );
      expect(midPlan.totalWeeks, 4);
      expect(
        midPlan.weeks.map((w) => w.phase).toSet(),
        {LearningPhase.foundation, LearningPhase.focus, LearningPhase.review},
      );

      final longPlan = generator.generate(
        LearningPathInput(
          startDate: start,
          examDate: start.add(const Duration(days: 84)),
          dailyMinutes: 60,
          skillScores: SkillScores.baseline(),
        ),
      );
      expect(longPlan.totalWeeks, 12);
      expect(longPlan.weeks.first.phase, LearningPhase.foundation);
      expect(longPlan.weeks.last.phase, LearningPhase.review);
    });
  });

  group('LearningPathGenerator - ưu tiên kỹ năng yếu & cân bằng tuần', () {
    test('kỹ năng điểm thấp nhất nhận nhiều ngày trọng tâm hơn và mỗi tuần đủ 4 kỹ năng', () {
      final plan = generator.generate(
        LearningPathInput(
          startDate: start,
          examDate: start.add(const Duration(days: 14)),
          dailyMinutes: 45,
          skillScores: SkillScores(
            listening: 85,
            reading: 80,
            writing: 75,
            speaking: 20,
          ),
        ),
      );

      for (final week in plan.weeks) {
        final counts = <SkillType, int>{
          for (final skill in SkillType.coreSkills) skill: 0,
        };
        for (final day in week.days) {
          counts[day.focusSkill] = (counts[day.focusSkill] ?? 0) + 1;
        }

        // Mỗi tuần (7 ngày) đều có tối thiểu 1 ngày cho mỗi kỹ năng.
        for (final skill in SkillType.coreSkills) {
          expect(counts[skill], greaterThanOrEqualTo(1));
        }
        // Speaking (20 điểm) phải được ưu tiên nhiều nhất.
        expect(counts[SkillType.speaking], greaterThan(counts[SkillType.listening]!));
      }
    });
  });

  group('LearningPathGenerator - tái cân bằng khi có điểm mới từ M3', () {
    test('bảo toàn ngày đã completed và chỉ tái lập các ngày pending', () {
      final initial = generator.generate(
        LearningPathInput(
          startDate: start,
          examDate: start.add(const Duration(days: 14)),
          dailyMinutes: 45,
          skillScores: SkillScores(
            listening: 70,
            reading: 70,
            writing: 70,
            speaking: 70,
          ),
        ),
      );

      // Đánh dấu ngày 1 đã hoàn thành.
      final day1 = initial.weeks.first.days.first;
      final completedDay1 = day1.copyWith(
        tasks: day1.tasks
            .map(
              (t) => t.copyWith(
                status: TaskStatus.completed,
                completedAt: DateTime.utc(2026, 11, 20, 20, 0),
              ),
            )
            .toList(),
      );
      final modifiedWeek1 = initial.weeks.first.copyWith(
        days: [completedDay1, ...initial.weeks.first.days.skip(1)],
      );
      final planWithDoneDay1 = initial.copyWith(
        weeks: [modifiedWeek1, ...initial.weeks.skip(1)],
      );

      // M3 trả về điểm Listening thấp (20%) -> newScore = 0.4*70 + 0.6*20 = 40 (<60).
      final rebalanced = generator.applyAttemptAndRebalance(
        currentPlan: planWithDoneDay1,
        skill: SkillType.listening,
        attemptPercent: 20,
        currentDate: DateTime(2026, 11, 21),
      );

      expect(rebalanced.currentScores.listening, 40);
      expect(rebalanced.weeks.first.days.first, completedDay1);
      expect(rebalanced.weeks.first.days.first.isCompleted, isTrue);
      // Các ngày tương lai chuyển sang ưu tiên Listening nhiều hơn.
      final futureFocusSkills = rebalanced.weeks
          .expand((w) => w.days)
          .skip(1)
          .map((d) => d.focusSkill)
          .toList();
      expect(
        futureFocusSkills.where((s) => s == SkillType.listening).length,
        greaterThanOrEqualTo(3),
      );
    });
  });
}
