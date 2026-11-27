import 'skill_scores.dart';

/// Trạng thái hoàn thành của một nhiệm vụ trong ngày.
enum TaskStatus {
  pending,
  completed;

  String get key => name;

  static TaskStatus fromKey(String? value) {
    return TaskStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => TaskStatus.pending,
    );
  }
}

/// Module đích mà nhiệm vụ điều hướng tới (M2 tài liệu hoặc M3 bài tập).
enum TargetModule {
  m2,
  m3;

  String get key => this == TargetModule.m2 ? 'M2' : 'M3';

  static TargetModule fromKey(String? value) {
    return value?.toUpperCase() == 'M2' ? TargetModule.m2 : TargetModule.m3;
  }
}

/// Một nhiệm vụ học tập trong ngày thuộc lộ trình M4.
class DailyTask {
  const DailyTask({
    required this.taskId,
    required this.title,
    required this.skill,
    required this.targetModule,
    required this.targetResourceId,
    required this.estimatedMinutes,
    this.status = TaskStatus.pending,
    this.completedAt,
  });

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    final completedRaw = json['completedAt'] as String?;
    return DailyTask(
      taskId: json['taskId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      skill: SkillType.fromKey(json['skill'] as String?),
      targetModule: TargetModule.fromKey(json['targetModule'] as String?),
      targetResourceId: json['targetResourceId'] as String? ?? '',
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.round() ?? 15,
      status: TaskStatus.fromKey(json['status'] as String?),
      completedAt: completedRaw != null ? DateTime.tryParse(completedRaw) : null,
    );
  }

  final String taskId;
  final String title;
  final SkillType skill;
  final TargetModule targetModule;
  final String targetResourceId;
  final int estimatedMinutes;
  final TaskStatus status;
  final DateTime? completedAt;

  bool get isCompleted => status == TaskStatus.completed;

  DailyTask copyWith({
    String? taskId,
    String? title,
    SkillType? skill,
    TargetModule? targetModule,
    String? targetResourceId,
    int? estimatedMinutes,
    TaskStatus? status,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return DailyTask(
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      skill: skill ?? this.skill,
      targetModule: targetModule ?? this.targetModule,
      targetResourceId: targetResourceId ?? this.targetResourceId,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      status: status ?? this.status,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'title': title,
      'skill': skill.key,
      'targetModule': targetModule.key,
      'targetResourceId': targetResourceId,
      'estimatedMinutes': estimatedMinutes,
      'status': status.key,
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyTask &&
        other.taskId == taskId &&
        other.title == title &&
        other.skill == skill &&
        other.targetModule == targetModule &&
        other.targetResourceId == targetResourceId &&
        other.estimatedMinutes == estimatedMinutes &&
        other.status == status &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode => Object.hash(
    taskId,
    title,
    skill,
    targetModule,
    targetResourceId,
    estimatedMinutes,
    status,
    completedAt,
  );
}
