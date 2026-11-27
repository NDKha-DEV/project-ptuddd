class HabitModel {
  final String id;
  final String title;
  final String description;
  final int dailyGoalMinutes;
  final DateTime createdAt;

  const HabitModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dailyGoalMinutes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dailyGoalMinutes': dailyGoalMinutes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      dailyGoalMinutes: map['dailyGoalMinutes'] as int? ?? 30,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}