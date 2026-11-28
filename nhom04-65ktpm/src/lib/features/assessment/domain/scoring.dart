import '../../exercises/data/models/exam_models.dart';
import '../data/models/exercise_attempt.dart';
import 'rubrics.dart';

/// Chấm điểm thuần Dart, không phụ thuộc giao diện.
class Scoring {
  Scoring._();

  /// Ngưỡng ước tính đạt B1 (thang 0..100) dùng để hiển thị nhận xét.
  static const passPercent = 50;

  /// Chấm tự động một phần Nghe/Đọc từ đáp án đã chọn.
  static SkillResult gradeObjective(
    ExamSection section,
    Map<String, int> answers,
  ) {
    final questions = section.questions;
    final correct = questions.where((q) => q.isCorrect(answers[q.id])).length;
    return SkillResult(
      skill: section.skill,
      earned: correct,
      possible: questions.length,
    );
  }

  /// Cộng điểm rubric của mọi đề trong phần Viết/Nói.
  /// Tiêu chí chưa chấm tính 0 điểm.
  static SkillResult gradeProductive(
    ExamSection section,
    Map<String, Map<String, int>> rubric,
  ) {
    final criteria = B1Rubrics.forSkill(section.skill);
    var earned = 0;
    var possible = 0;
    for (final task in section.tasks) {
      final marks = rubric[task.id] ?? const {};
      for (final criterion in criteria) {
        final points = marks[criterion.id] ?? 0;
        earned += points.clamp(0, criterion.maxPoints);
        possible += criterion.maxPoints;
      }
    }
    return SkillResult(
      skill: section.skill,
      earned: earned,
      possible: possible,
    );
  }

  static List<SkillResult> gradeSections(
    List<ExamSection> sections, {
    required Map<String, int> answers,
    required Map<String, Map<String, int>> rubric,
  }) {
    return [
      for (final section in sections)
        section.skill.isAutoGraded
            ? gradeObjective(section, answers)
            : gradeProductive(section, rubric),
    ];
  }

  static int countWords(String text) =>
      RegExp(r"[A-Za-z0-9']+").allMatches(text).length;

  static String verdictVi(int scorePercent) {
    if (scorePercent >= 80) return 'Rất tốt – vượt mức B1';
    if (scorePercent >= 65) return 'Khá – đạt B1 ổn định';
    if (scorePercent >= passPercent) return 'Đạt ngưỡng B1 (ước tính)';
    if (scorePercent >= 35) return 'Gần đạt – cần luyện thêm';
    return 'Chưa đạt – nên ôn lại nền tảng';
  }
}
