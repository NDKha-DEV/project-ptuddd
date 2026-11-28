import '../data/models/exam_models.dart';
import '../data/models/exercise.dart';

/// Danh mục bài tập dựng từ ngân hàng đề: mỗi phần thi là một bài luyện kỹ năng,
/// mỗi bộ đề là một bài thi thử tổng hợp.
class ExerciseCatalog {
  ExerciseCatalog(this.sets) {
    for (final set in sets) {
      for (final section in set.sections) {
        _byId[section.id] = Exercise(
          id: section.id,
          kind: ExerciseKind.practice,
          examSet: set,
          sections: [section],
        );
      }
      final mockId = Exercise.mockIdOf(set);
      _byId[mockId] = Exercise(
        id: mockId,
        kind: ExerciseKind.mockTest,
        examSet: set,
        sections: set.sections,
      );
    }
  }

  final List<ExamSet> sets;
  final Map<String, Exercise> _byId = {};

  Exercise? byId(String id) => _byId[id];

  List<Exercise> practiceFor(ExamSkill skill) => [
    for (final set in sets)
      if (set.sectionOf(skill) != null) _byId[set.sectionOf(skill)!.id]!,
  ];

  List<Exercise> get mockTests => [
    for (final set in sets) _byId[Exercise.mockIdOf(set)]!,
  ];

  /// Tổng số câu hỏi chấm tự động trong ngân hàng (Nghe + Đọc).
  int get questionCount => sets.fold(0, (sum, set) => sum + set.questionCount);
}
