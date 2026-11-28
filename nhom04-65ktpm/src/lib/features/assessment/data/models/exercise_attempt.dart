import '../../../exercises/data/models/exam_models.dart';

/// Kết quả một kỹ năng trong lần làm bài.
///
/// Nghe/Đọc: `earned`/`possible` là số câu đúng/tổng câu.
/// Viết/Nói: `earned`/`possible` là điểm rubric tự đánh giá.
class SkillResult {
  const SkillResult({
    required this.skill,
    required this.earned,
    required this.possible,
  });

  factory SkillResult.fromJson(ExamSkill skill, Map<String, dynamic> json) {
    return SkillResult(
      skill: skill,
      earned: (json['earned'] as num?)?.toInt() ?? 0,
      possible: (json['possible'] as num?)?.toInt() ?? 0,
    );
  }

  final ExamSkill skill;
  final int earned;
  final int possible;

  /// Điểm thang 0..100, làm tròn.
  int get scorePercent => possible == 0 ? 0 : (earned * 100 / possible).round();

  Map<String, dynamic> toJson() => {
    'earned': earned,
    'possible': possible,
    'scorePercent': scorePercent,
  };
}

/// Một lần làm bài, lưu tại `users/{uid}/attempts/{attemptId}` (đề cương mục 9.6).
///
/// M4 đọc `skill`, `scorePercent`, `durationMinutes`; với thi thử `skill` = `mock`
/// và điểm từng kỹ năng nằm trong `skillResults`.
class ExerciseAttempt {
  const ExerciseAttempt({
    required this.id,
    required this.exerciseId,
    required this.setId,
    required this.isMock,
    required this.startedAt,
    required this.completedAt,
    required this.skillResults,
    this.answers = const {},
    this.responses = const {},
    this.rubric = const {},
    this.timedOut = false,
  });

  factory ExerciseAttempt.fromJson(Map<String, dynamic> json) {
    final results = Map<String, dynamic>.from(
      json['skillResults'] as Map? ?? const {},
    );
    return ExerciseAttempt(
      id: json['id'] as String,
      exerciseId: json['exerciseId'] as String? ?? '',
      setId: json['setId'] as String? ?? '',
      isMock: json['skill'] == mockSkillKey,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: DateTime.parse(json['completedAt'] as String),
      skillResults: [
        for (final entry in results.entries)
          SkillResult.fromJson(
            ExamSkill.fromKey(entry.key),
            Map<String, dynamic>.from(entry.value as Map),
          ),
      ],
      answers: Map<String, int>.from(
        (json['answers'] as Map? ?? const {}).map(
          (k, v) => MapEntry(k as String, (v as num).toInt()),
        ),
      ),
      responses: Map<String, String>.from(
        json['responses'] as Map? ?? const {},
      ),
      rubric: (json['rubric'] as Map? ?? const {}).map(
        (k, v) => MapEntry(
          k as String,
          Map<String, int>.from(
            (v as Map).map((c, p) => MapEntry(c as String, (p as num).toInt())),
          ),
        ),
      ),
      timedOut: json['timedOut'] as bool? ?? false,
    );
  }

  static const mockSkillKey = 'mock';

  final String id;
  final String exerciseId;
  final String setId;
  final bool isMock;
  final DateTime startedAt;
  final DateTime completedAt;
  final List<SkillResult> skillResults;

  /// questionId -> chỉ số phương án đã chọn.
  final Map<String, int> answers;

  /// taskId -> bài viết của người học (Viết) hoặc ghi chú (Nói).
  final Map<String, String> responses;

  /// taskId -> (criterionId -> điểm 0..3).
  final Map<String, Map<String, int>> rubric;
  final bool timedOut;

  String get skillKey => isMock ? mockSkillKey : skillResults.first.skill.key;

  int get durationSeconds => completedAt.difference(startedAt).inSeconds;

  /// Số phút học (làm tròn lên, tối thiểu 1) để M5 cộng dồn.
  int get durationMinutes {
    final minutes = (durationSeconds / 60).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  /// Điểm tổng: trung bình điểm các kỹ năng có trong lần làm.
  int get scorePercent {
    if (skillResults.isEmpty) return 0;
    final total = skillResults.fold(0, (sum, r) => sum + r.scorePercent);
    return (total / skillResults.length).round();
  }

  SkillResult? resultOf(ExamSkill skill) {
    for (final result in skillResults) {
      if (result.skill == skill) return result;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'exerciseId': exerciseId,
    'setId': setId,
    'skill': skillKey,
    'scorePercent': scorePercent,
    'durationMinutes': durationMinutes,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'completedAt': completedAt.toUtc().toIso8601String(),
    'skillResults': {for (final r in skillResults) r.skill.key: r.toJson()},
    'answers': answers,
    'responses': responses,
    'rubric': rubric,
    'timedOut': timedOut,
  };
}
