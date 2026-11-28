import '../../exercises/data/models/exam_models.dart';
import '../data/models/exercise_attempt.dart';

/// Thống kê một kỹ năng qua toàn bộ lịch sử làm bài (gồm cả thi thử).
class SkillStat {
  const SkillStat({required this.skill, required this.scores});

  final ExamSkill skill;

  /// Điểm các lần làm, cũ trước mới sau.
  final List<int> scores;

  int get attempts => scores.length;
  bool get hasData => scores.isNotEmpty;
  int? get latest => hasData ? scores.last : null;
  int? get best => hasData ? scores.reduce((a, b) => a > b ? a : b) : null;

  int? get average =>
      hasData ? (scores.reduce((a, b) => a + b) / scores.length).round() : null;

  /// Tối đa 5 lần gần nhất để vẽ xu hướng.
  List<int> get recent =>
      scores.length <= 5 ? scores : scores.sublist(scores.length - 5);

  /// Chênh lệch lần gần nhất so với trung bình các lần trước đó.
  int? get trend {
    if (scores.length < 2) return null;
    final previous = scores.sublist(0, scores.length - 1);
    final avg = previous.reduce((a, b) => a + b) / previous.length;
    return (scores.last - avg).round();
  }
}

class SkillStatsSummary {
  const SkillStatsSummary(this.stats, {required this.totalAttempts});

  factory SkillStatsSummary.fromAttempts(List<ExerciseAttempt> attempts) {
    final sorted = [...attempts]
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    return SkillStatsSummary({
      for (final skill in ExamSkill.values)
        skill: SkillStat(
          skill: skill,
          scores: [
            for (final attempt in sorted)
              if (attempt.resultOf(skill) case final result?)
                result.scorePercent,
          ],
        ),
    }, totalAttempts: attempts.length);
  }

  final Map<ExamSkill, SkillStat> stats;
  final int totalAttempts;

  SkillStat of(ExamSkill skill) => stats[skill]!;

  /// Kỹ năng có điểm trung bình thấp nhất trong số kỹ năng đã làm; null nếu chưa có dữ liệu.
  ExamSkill? get weakestSkill {
    ExamSkill? weakest;
    var min = 101;
    for (final stat in stats.values) {
      final avg = stat.average;
      if (avg != null && avg < min) {
        min = avg;
        weakest = stat.skill;
      }
    }
    return weakest;
  }

  /// Kỹ năng chưa làm lần nào.
  List<ExamSkill> get untouchedSkills => [
    for (final stat in stats.values)
      if (!stat.hasData) stat.skill,
  ];
}
