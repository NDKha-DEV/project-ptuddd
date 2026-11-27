import 'skill_scores.dart';

/// Xếp loại năng lực sơ bộ theo từng kỹ năng trong đặc tả M4.
enum SkillLevelTier {
  needsFoundation,
  intermediate,
  good;

  static SkillLevelTier fromScore(int score) {
    if (score < 45) return SkillLevelTier.needsFoundation;
    if (score < 70) return SkillLevelTier.intermediate;
    return SkillLevelTier.good;
  }

  String get labelVi {
    switch (this) {
      case SkillLevelTier.needsFoundation:
        return 'Cần củng cố nền tảng';
      case SkillLevelTier.intermediate:
        return 'Trung bình – cần luyện tập đều';
      case SkillLevelTier.good:
        return 'Khá tốt – duy trì & nâng cao';
    }
  }
}

/// Câu hỏi trắc nghiệm rút gọn cho bước Mini Diagnostic (khảo sát đầu vào B1).
class MiniDiagnosticQuestion {
  const MiniDiagnosticQuestion({
    required this.id,
    required this.skill,
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  final String id;
  final SkillType skill;
  final String prompt;
  final List<String> options;
  final int correctIndex;

  bool isCorrect(int? selectedIndex) =>
      selectedIndex != null && selectedIndex == correctIndex;
}

/// Đầu ra chuẩn hóa từ bài khảo sát đầu vào B1 (InitialAssessmentResult).
class InitialAssessmentResult {
  const InitialAssessmentResult({
    required this.examDate,
    required this.dailyMinutes,
    required this.scores,
    required this.skippedMiniQuiz,
    required this.assessedAt,
  });

  factory InitialAssessmentResult.fromJson(Map<String, dynamic> json) {
    return InitialAssessmentResult(
      examDate: json['examDate'] as String? ?? '',
      dailyMinutes: (json['dailyMinutes'] as num?)?.round() ?? 45,
      scores: SkillScores.fromJson(
        Map<String, dynamic>.from(json['scores'] as Map? ?? const {}),
      ),
      skippedMiniQuiz: json['skippedMiniQuiz'] as bool? ?? false,
      assessedAt:
          DateTime.tryParse(json['assessedAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  final String examDate;
  final int dailyMinutes;
  final SkillScores scores;
  final bool skippedMiniQuiz;
  final DateTime assessedAt;

  SkillLevelTier tierOf(SkillType skill) =>
      SkillLevelTier.fromScore(scores.scoreOf(skill));

  Map<String, dynamic> toJson() {
    return {
      'examDate': examDate,
      'dailyMinutes': dailyMinutes,
      'scores': scores.toJson(),
      'skippedMiniQuiz': skippedMiniQuiz,
      'assessedAt': assessedAt.toUtc().toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InitialAssessmentResult &&
        other.examDate == examDate &&
        other.dailyMinutes == dailyMinutes &&
        other.scores == scores &&
        other.skippedMiniQuiz == skippedMiniQuiz &&
        other.assessedAt == assessedAt;
  }

  @override
  int get hashCode =>
      Object.hash(examDate, dailyMinutes, scores, skippedMiniQuiz, assessedAt);
}
