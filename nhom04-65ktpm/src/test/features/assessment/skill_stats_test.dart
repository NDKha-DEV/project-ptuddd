import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_b1_daily/features/assessment/data/models/exercise_attempt.dart';
import 'package:tlu_b1_daily/features/assessment/domain/skill_stats.dart';
import 'package:tlu_b1_daily/features/exercises/data/models/exam_models.dart';

ExerciseAttempt _attempt(
  String id,
  DateTime at,
  Map<ExamSkill, (int, int)> results, {
  bool mock = false,
}) {
  return ExerciseAttempt(
    id: id,
    exerciseId: id,
    setId: 'set_01',
    isMock: mock,
    startedAt: at.subtract(const Duration(minutes: 10)),
    completedAt: at,
    skillResults: [
      for (final e in results.entries)
        SkillResult(skill: e.key, earned: e.value.$1, possible: e.value.$2),
    ],
  );
}

void main() {
  group('SkillStatsSummary', () {
    test('thống kê theo kỹ năng, tính cả điểm từ thi thử', () {
      final summary = SkillStatsSummary.fromAttempts([
        _attempt('a', DateTime.utc(2026, 11, 1), {ExamSkill.reading: (6, 12)}),
        _attempt('b', DateTime.utc(2026, 11, 3), {ExamSkill.reading: (9, 12)}),
        _attempt('c', DateTime.utc(2026, 11, 2), {
          ExamSkill.listening: (2, 8),
          ExamSkill.reading: (12, 12),
        }, mock: true),
      ]);
      final reading = summary.of(ExamSkill.reading);
      expect(reading.scores, [50, 100, 75]); // theo thời gian
      expect(reading.average, 75);
      expect(reading.best, 100);
      expect(reading.latest, 75);
      expect(reading.trend, 0);
      expect(summary.weakestSkill, ExamSkill.listening);
      expect(
        summary.untouchedSkills,
        containsAll([ExamSkill.writing, ExamSkill.speaking]),
      );
    });

    test('chưa có dữ liệu thì không có kỹ năng yếu', () {
      final summary = SkillStatsSummary.fromAttempts(const []);
      expect(summary.weakestSkill, isNull);
      expect(summary.of(ExamSkill.writing).hasData, isFalse);
    });

    test('xu hướng chỉ lấy 5 lần gần nhất', () {
      final summary = SkillStatsSummary.fromAttempts([
        for (var i = 0; i < 7; i++)
          _attempt('x$i', DateTime.utc(2026, 11, i + 1), {
            ExamSkill.listening: (i, 8),
          }),
      ]);
      expect(summary.of(ExamSkill.listening).recent.length, 5);
    });
  });
}
