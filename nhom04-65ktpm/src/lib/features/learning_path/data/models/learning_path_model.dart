import 'package:flutter/foundation.dart';

import 'daily_task_model.dart';
import 'skill_scores.dart';

/// 3 chặng ôn tập của lộ trình B1.
enum LearningPhase {
  foundation,
  focus,
  review;

  String get key => name;

  String get labelVi {
    switch (this) {
      case LearningPhase.foundation:
        return 'Củng cố nền tảng';
      case LearningPhase.focus:
        return 'Luyện kỹ năng trọng tâm';
      case LearningPhase.review:
        return 'Tổng ôn & Thi thử';
    }
  }

  static LearningPhase fromKey(String? value) {
    return LearningPhase.values.firstWhere(
      (phase) => phase.name == value,
      orElse: () => LearningPhase.foundation,
    );
  }
}

/// Kế hoạch học tập trong 1 ngày.
class DayPlan {
  const DayPlan({
    required this.dayIndex,
    required this.date,
    required this.focusSkill,
    required this.totalMinutes,
    required this.tasks,
  });

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    final rawTasks = json['tasks'] as List<dynamic>? ?? const [];
    return DayPlan(
      dayIndex: (json['dayIndex'] as num?)?.round() ?? 1,
      date: json['date'] as String? ?? '',
      focusSkill: SkillType.fromKey(json['focusSkill'] as String?),
      totalMinutes: (json['totalMinutes'] as num?)?.round() ?? 0,
      tasks: rawTasks
          .map((item) => DailyTask.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  final int dayIndex;
  final String date;
  final SkillType focusSkill;
  final int totalMinutes;
  final List<DailyTask> tasks;

  bool get isCompleted =>
      tasks.isNotEmpty && tasks.every((task) => task.isCompleted);

  int get completedMinutes => tasks
      .where((task) => task.isCompleted)
      .fold(0, (sum, task) => sum + task.estimatedMinutes);

  double get completionRate {
    if (tasks.isEmpty) return 0;
    final doneCount = tasks.where((task) => task.isCompleted).length;
    return doneCount / tasks.length;
  }

  DayPlan copyWith({
    int? dayIndex,
    String? date,
    SkillType? focusSkill,
    int? totalMinutes,
    List<DailyTask>? tasks,
  }) {
    return DayPlan(
      dayIndex: dayIndex ?? this.dayIndex,
      date: date ?? this.date,
      focusSkill: focusSkill ?? this.focusSkill,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      tasks: tasks ?? this.tasks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayIndex': dayIndex,
      'date': date,
      'focusSkill': focusSkill.key,
      'totalMinutes': totalMinutes,
      'tasks': tasks.map((task) => task.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DayPlan &&
        other.dayIndex == dayIndex &&
        other.date == date &&
        other.focusSkill == focusSkill &&
        other.totalMinutes == totalMinutes &&
        listEquals(other.tasks, tasks);
  }

  @override
  int get hashCode =>
      Object.hash(dayIndex, date, focusSkill, totalMinutes, Object.hashAll(tasks));
}

/// Kế hoạch học tập theo từng tuần.
class WeekPlan {
  const WeekPlan({
    required this.weekNumber,
    required this.title,
    required this.phase,
    required this.days,
  });

  factory WeekPlan.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'] as List<dynamic>? ?? const [];
    return WeekPlan(
      weekNumber: (json['weekNumber'] as num?)?.round() ?? 1,
      title: json['title'] as String? ?? '',
      phase: LearningPhase.fromKey(json['phase'] as String?),
      days: rawDays
          .map((item) => DayPlan.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  final int weekNumber;
  final String title;
  final LearningPhase phase;
  final List<DayPlan> days;

  bool get isCompleted =>
      days.isNotEmpty && days.every((day) => day.isCompleted);

  double get completionRate {
    final allTasks = days.expand((day) => day.tasks).toList();
    if (allTasks.isEmpty) return 0;
    final doneCount = allTasks.where((task) => task.isCompleted).length;
    return doneCount / allTasks.length;
  }

  WeekPlan copyWith({
    int? weekNumber,
    String? title,
    LearningPhase? phase,
    List<DayPlan>? days,
  }) {
    return WeekPlan(
      weekNumber: weekNumber ?? this.weekNumber,
      title: title ?? this.title,
      phase: phase ?? this.phase,
      days: days ?? this.days,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekNumber': weekNumber,
      'title': title,
      'phase': phase.key,
      'days': days.map((day) => day.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeekPlan &&
        other.weekNumber == weekNumber &&
        other.title == title &&
        other.phase == phase &&
        listEquals(other.days, days);
  }

  @override
  int get hashCode =>
      Object.hash(weekNumber, title, phase, Object.hashAll(days));
}

/// Toàn bộ lộ trình ôn luyện B1 cá nhân hóa (users/{uid}/learning_paths/{planId}).
class LearningPath {
  const LearningPath({
    this.planId = 'active_plan',
    required this.startDate,
    required this.examDate,
    required this.dailyMinutes,
    required this.initialScores,
    required this.currentScores,
    required this.currentWeek,
    required this.totalWeeks,
    required this.completionRate,
    required this.updatedAt,
    required this.weeks,
    this.savedTourIds = const [],
  });

  factory LearningPath.fromJson(Map<String, dynamic> json) {
    final rawWeeks = json['weeks'] as List<dynamic>? ?? const [];
    final rawSavedTours = json['savedTourIds'] as List<dynamic>? ?? const [];
    return LearningPath(
      planId: json['planId'] as String? ?? 'active_plan',
      startDate: json['startDate'] as String? ?? '',
      examDate: json['examDate'] as String? ?? '',
      dailyMinutes: (json['dailyMinutes'] as num?)?.round() ?? 45,
      initialScores: SkillScores.fromJson(
        Map<String, dynamic>.from(json['initialScores'] as Map? ?? const {}),
      ),
      currentScores: SkillScores.fromJson(
        Map<String, dynamic>.from(json['currentScores'] as Map? ?? const {}),
      ),
      currentWeek: (json['currentWeek'] as num?)?.round() ?? 1,
      totalWeeks: (json['totalWeeks'] as num?)?.round() ?? rawWeeks.length,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      weeks: rawWeeks
          .map((item) => WeekPlan.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      savedTourIds: rawSavedTours.map((item) => item.toString()).toList(),
    );
  }

  final String planId;
  final String startDate;
  final String examDate;
  final int dailyMinutes;
  final SkillScores initialScores;
  final SkillScores currentScores;
  final int currentWeek;
  final int totalWeeks;
  final double completionRate;
  final DateTime updatedAt;
  final List<WeekPlan> weeks;
  final List<String> savedTourIds;

  /// Tính lại tỷ lệ hoàn thành tổng thể dựa trên toàn bộ nhiệm vụ hiện có.
  LearningPath recalculateCompletion({DateTime? now}) {
    final allTasks = weeks
        .expand((week) => week.days)
        .expand((day) => day.tasks)
        .toList();
    final rate = allTasks.isEmpty
        ? 0.0
        : allTasks.where((task) => task.isCompleted).length / allTasks.length;

    return copyWith(
      completionRate: double.parse(rate.toStringAsFixed(4)),
      updatedAt: (now ?? DateTime.now()).toUtc(),
    );
  }

  LearningPath copyWith({
    String? planId,
    String? startDate,
    String? examDate,
    int? dailyMinutes,
    SkillScores? initialScores,
    SkillScores? currentScores,
    int? currentWeek,
    int? totalWeeks,
    double? completionRate,
    DateTime? updatedAt,
    List<WeekPlan>? weeks,
    List<String>? savedTourIds,
  }) {
    return LearningPath(
      planId: planId ?? this.planId,
      startDate: startDate ?? this.startDate,
      examDate: examDate ?? this.examDate,
      dailyMinutes: dailyMinutes ?? this.dailyMinutes,
      initialScores: initialScores ?? this.initialScores,
      currentScores: currentScores ?? this.currentScores,
      currentWeek: currentWeek ?? this.currentWeek,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      completionRate: completionRate ?? this.completionRate,
      updatedAt: updatedAt ?? this.updatedAt,
      weeks: weeks ?? this.weeks,
      savedTourIds: savedTourIds ?? this.savedTourIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'startDate': startDate,
      'examDate': examDate,
      'dailyMinutes': dailyMinutes,
      'initialScores': initialScores.toJson(),
      'currentScores': currentScores.toJson(),
      'currentWeek': currentWeek,
      'totalWeeks': totalWeeks,
      'completionRate': completionRate,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'weeks': weeks.map((week) => week.toJson()).toList(),
      'savedTourIds': savedTourIds,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LearningPath &&
        other.planId == planId &&
        other.startDate == startDate &&
        other.examDate == examDate &&
        other.dailyMinutes == dailyMinutes &&
        other.initialScores == initialScores &&
        other.currentScores == currentScores &&
        other.currentWeek == currentWeek &&
        other.totalWeeks == totalWeeks &&
        other.completionRate == completionRate &&
        other.updatedAt == updatedAt &&
        listEquals(other.weeks, weeks) &&
        listEquals(other.savedTourIds, savedTourIds);
  }

  @override
  int get hashCode => Object.hash(
    planId,
    startDate,
    examDate,
    dailyMinutes,
    initialScores,
    currentScores,
    currentWeek,
    totalWeeks,
    completionRate,
    updatedAt,
    Object.hashAll(weeks),
    Object.hashAll(savedTourIds),
  );
}
