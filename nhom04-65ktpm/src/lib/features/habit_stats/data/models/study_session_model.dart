class StudySessionModel {
  final String id;
  final DateTime startedAt;
  final int durationMinutes;
  final bool isCompleted;

  const StudySessionModel({
    required this.id,
    required this.startedAt,
    required this.durationMinutes,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'durationMinutes': durationMinutes,
      'isCompleted': isCompleted,
    };
  }

  factory StudySessionModel.fromMap(Map<String, dynamic> map) {
    return StudySessionModel(
      id: map['id'] as String,
      startedAt: DateTime.parse(map['startedAt'] as String),
      durationMinutes: map['durationMinutes'] as int? ?? 0,
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }
}