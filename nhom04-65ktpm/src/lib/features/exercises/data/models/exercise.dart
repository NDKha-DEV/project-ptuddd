import 'exam_models.dart';

enum ExerciseKind { practice, mockTest }

/// Bài tập mở được qua `AppRoutes.exerciseDetail(id)`.
///
/// - Luyện kỹ năng: `id` = id phần thi, ví dụ `ex_listen_01`, `ex_read_03`.
/// - Thi thử tổng hợp: `id` = `mock_<số đề>`, ví dụ `mock_01`.
class Exercise {
  const Exercise({
    required this.id,
    required this.kind,
    required this.examSet,
    required this.sections,
  });

  final String id;
  final ExerciseKind kind;
  final ExamSet examSet;
  final List<ExamSection> sections;

  static String mockIdOf(ExamSet set) => set.id.replaceFirst('set_', 'mock_');

  bool get isMock => kind == ExerciseKind.mockTest;

  /// Kỹ năng chính của bài luyện; thi thử trả về null.
  ExamSkill? get skill => isMock ? null : sections.first.skill;

  String get title => isMock
      ? 'Thi thử – ${examSet.title}'
      : '${sections.first.skill.labelVi} – ${examSet.title}';

  int get durationMinutes =>
      sections.fold(0, (sum, section) => sum + section.durationMinutes);

  List<ExamSkill> get skills => [for (final s in sections) s.skill];

  int get questionCount =>
      sections.fold(0, (sum, section) => sum + section.questions.length);

  int get taskCount =>
      sections.fold(0, (sum, section) => sum + section.tasks.length);
}
