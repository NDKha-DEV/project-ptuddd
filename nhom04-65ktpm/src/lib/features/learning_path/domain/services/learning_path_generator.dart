import 'dart:math' as math;

import '../../data/models/daily_task_model.dart';
import '../../data/models/learning_path_model.dart';
import '../../data/models/skill_scores.dart';

/// Tham chiếu nhẹ tới tài liệu (M2) hoặc bài tập (M3) để thuật toán gắn vào DailyTask.
class LearningResourceRef {
  const LearningResourceRef({
    required this.id,
    required this.title,
    required this.skill,
    required this.targetModule,
  });

  final String id;
  final String title;
  final SkillType skill;
  final TargetModule targetModule;
}

/// Đầu vào cho thuật toán sinh lộ trình M4.
class LearningPathInput {
  const LearningPathInput({
    required this.startDate,
    required this.examDate,
    required this.dailyMinutes,
    required this.skillScores,
    this.availableMaterials = const [],
    this.availableExercises = const [],
    this.planId = 'active_plan',
  });

  final DateTime startDate;
  final DateTime examDate;
  final int dailyMinutes;
  final SkillScores skillScores;
  final List<LearningResourceRef> availableMaterials;
  final List<LearningResourceRef> availableExercises;
  final String planId;
}

/// Thuật toán sinh và tái cân bằng lộ trình ôn thi B1 (thuần Dart).
class LearningPathGenerator {
  const LearningPathGenerator();

  static const List<int> supportedDailyMinutes = [30, 45, 60];

  /// Chuẩn hóa quỹ thời gian ngày về 30, 45 hoặc 60 phút.
  static int normalizeDailyMinutes(int minutes) {
    if (minutes <= 37) return 30;
    if (minutes <= 52) return 45;
    return 60;
  }

  /// Định dạng yyyy-MM-dd ổn định, không phụ thuộc múi giờ.
  static String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Sinh lộ trình tuần/ngày mới từ đầu vào khảo sát.
  LearningPath generate(LearningPathInput input, {DateTime? now}) {
    final start = _dateOnly(input.startDate);
    final exam = _dateOnly(input.examDate);
    final dailyMinutes = normalizeDailyMinutes(input.dailyMinutes);

    final rawDays = exam.difference(start).inDays;
    final totalDays = math.max(7, rawDays);
    final totalWeeks = (totalDays / 7).ceil();
    final isSprintMode = rawDays < 7;

    final phases = _assignWeekPhases(
      totalWeeks: totalWeeks,
      isSprintMode: isSprintMode,
    );

    final materials = input.availableMaterials.isNotEmpty
        ? input.availableMaterials
        : _defaultMaterials;
    final exercises = input.availableExercises.isNotEmpty
        ? input.availableExercises
        : _defaultExercises;

    final weeks = <WeekPlan>[];
    var dayCursor = 0;

    for (var w = 0; w < totalWeeks; w++) {
      final weekNumber = w + 1;
      final phase = phases[w];
      final daysInWeek = math.min(7, totalDays - dayCursor);

      final focusSkills = _allocateWeekSkills(
        scores: input.skillScores,
        daysCount: daysInWeek,
      );

      final days = <DayPlan>[];
      for (var d = 0; d < daysInWeek; d++) {
        final dayIndex = dayCursor + 1;
        final date = start.add(Duration(days: dayCursor));
        final isWeeklyReviewDay = daysInWeek >= 4 && d == daysInWeek - 1;
        final focusSkill = focusSkills[d];

        final tasks = _buildDayTasks(
          weekNumber: weekNumber,
          dayNumberInWeek: d + 1,
          focusSkill: focusSkill,
          dailyMinutes: dailyMinutes,
          phase: phase,
          isWeeklyReviewDay: isWeeklyReviewDay,
          materials: materials,
          exercises: exercises,
        );

        days.add(
          DayPlan(
            dayIndex: dayIndex,
            date: formatDate(date),
            focusSkill: focusSkill,
            totalMinutes: tasks.fold(0, (sum, t) => sum + t.estimatedMinutes),
            tasks: tasks,
          ),
        );
        dayCursor++;
      }

      weeks.add(
        WeekPlan(
          weekNumber: weekNumber,
          title: _buildWeekTitle(
            weekNumber: weekNumber,
            phase: phase,
            isSprintMode: isSprintMode,
            weakestSkill: input.skillScores.weakestSkill,
          ),
          phase: phase,
          days: days,
        ),
      );
    }

    return LearningPath(
      planId: input.planId,
      startDate: formatDate(start),
      examDate: formatDate(exam),
      dailyMinutes: dailyMinutes,
      initialScores: input.skillScores,
      currentScores: input.skillScores,
      currentWeek: 1,
      totalWeeks: totalWeeks,
      completionRate: 0.0,
      updatedAt: (now ?? DateTime.now()).toUtc(),
      weeks: weeks,
    );
  }

  /// Cập nhật điểm kỹ năng khi có kết quả mới từ M3 và tái phân bổ ngày pending nếu cần.
  LearningPath applyAttemptAndRebalance({
    required LearningPath currentPlan,
    required SkillType skill,
    required int attemptPercent,
    DateTime? currentDate,
    List<LearningResourceRef> availableMaterials = const [],
    List<LearningResourceRef> availableExercises = const [],
    bool forceRebalance = false,
  }) {
    final oldScore = currentPlan.currentScores.scoreOf(skill);
    final updatedSkillScore =
        (0.4 * oldScore + 0.6 * attemptPercent.clamp(0, 100)).round();
    final updatedScores = currentPlan.currentScores.updateSkill(
      skill,
      updatedSkillScore,
    );

    final updatedPlan = currentPlan.copyWith(currentScores: updatedScores);

    final shouldRebalance = forceRebalance || updatedSkillScore < 60;
    if (!shouldRebalance) {
      return updatedPlan.recalculateCompletion(now: currentDate);
    }

    return _rebalancePendingDays(
      plan: updatedPlan,
      newScores: updatedScores,
      newDailyMinutes: currentPlan.dailyMinutes,
      newExamDate:
          DateTime.tryParse(currentPlan.examDate) ?? DateTime.now(),
      currentDate: currentDate ?? DateTime.now(),
      availableMaterials: availableMaterials,
      availableExercises: availableExercises,
    );
  }

  /// Tái lập lịch phần tương lai khi user đổi `dailyMinutes` hoặc `examDate` ở M1.
  LearningPath rescheduleOnSettingsChanged({
    required LearningPath currentPlan,
    required int newDailyMinutes,
    required DateTime newExamDate,
    DateTime? currentDate,
    List<LearningResourceRef> availableMaterials = const [],
    List<LearningResourceRef> availableExercises = const [],
  }) {
    return _rebalancePendingDays(
      plan: currentPlan,
      newScores: currentPlan.currentScores,
      newDailyMinutes: normalizeDailyMinutes(newDailyMinutes),
      newExamDate: newExamDate,
      currentDate: currentDate ?? DateTime.now(),
      availableMaterials: availableMaterials,
      availableExercises: availableExercises,
    );
  }

  LearningPath _rebalancePendingDays({
    required LearningPath plan,
    required SkillScores newScores,
    required int newDailyMinutes,
    required DateTime newExamDate,
    required DateTime currentDate,
    required List<LearningResourceRef> availableMaterials,
    required List<LearningResourceRef> availableExercises,
  }) {
    final allExistingDays = plan.weeks.expand((w) => w.days).toList();
    final preservedDays = <DayPlan>[];
    var splitIndex = 0;

    // Bảo toàn toàn bộ tiền tố các ngày đã hoàn thành hoặc có task đã làm.
    for (var i = 0; i < allExistingDays.length; i++) {
      final day = allExistingDays[i];
      final hasCompletedTask = day.tasks.any((t) => t.isCompleted);
      if (day.isCompleted || hasCompletedTask) {
        preservedDays.add(day);
        splitIndex = i + 1;
      } else {
        break;
      }
    }

    final futureStart = preservedDays.isNotEmpty
        ? _dateOnly(
            DateTime.tryParse(preservedDays.last.date) ?? currentDate,
          ).add(const Duration(days: 1))
        : _dateOnly(
            DateTime.tryParse(plan.startDate) ?? currentDate,
          );

    final regenerated = generate(
      LearningPathInput(
        startDate: futureStart,
        examDate: newExamDate,
        dailyMinutes: newDailyMinutes,
        skillScores: newScores,
        availableMaterials: availableMaterials,
        availableExercises: availableExercises,
        planId: plan.planId,
      ),
      now: currentDate,
    );

    final regeneratedDays = regenerated.weeks.expand((w) => w.days).toList();
    final combinedDays = <DayPlan>[
      ...preservedDays,
      for (var i = 0; i < regeneratedDays.length; i++)
        regeneratedDays[i].copyWith(dayIndex: splitIndex + i + 1),
    ];

    final totalWeeks = (combinedDays.length / 7).ceil().clamp(1, 520);
    final isSprintMode =
        _dateOnly(newExamDate).difference(futureStart).inDays < 7 &&
        preservedDays.isEmpty;
    final phases = _assignWeekPhases(
      totalWeeks: totalWeeks,
      isSprintMode: isSprintMode,
    );

    final rebuiltWeeks = <WeekPlan>[];
    for (var w = 0; w < totalWeeks; w++) {
      final startIdx = w * 7;
      final endIdx = math.min(startIdx + 7, combinedDays.length);
      final weekDays = combinedDays.sublist(startIdx, endIdx);
      final phase = phases[w];
      rebuiltWeeks.add(
        WeekPlan(
          weekNumber: w + 1,
          title: _buildWeekTitle(
            weekNumber: w + 1,
            phase: phase,
            isSprintMode: isSprintMode,
            weakestSkill: newScores.weakestSkill,
          ),
          phase: phase,
          days: weekDays,
        ),
      );
    }

    return plan
        .copyWith(
          examDate: formatDate(_dateOnly(newExamDate)),
          dailyMinutes: newDailyMinutes,
          currentScores: newScores,
          totalWeeks: rebuiltWeeks.length,
          weeks: rebuiltWeeks,
          updatedAt: currentDate.toUtc(),
        )
        .recalculateCompletion(now: currentDate);
  }

  List<LearningPhase> _assignWeekPhases({
    required int totalWeeks,
    required bool isSprintMode,
  }) {
    if (isSprintMode || totalWeeks <= 1) {
      return List.filled(totalWeeks, LearningPhase.review);
    }
    if (totalWeeks == 2) {
      return [LearningPhase.foundation, LearningPhase.review];
    }

    final reviewWeeks = math.max(1, (totalWeeks * 0.2).round());
    final remaining = totalWeeks - reviewWeeks;
    final foundationWeeks = (remaining / 2).ceil();
    final focusWeeks = remaining - foundationWeeks;

    return [
      ...List.filled(foundationWeeks, LearningPhase.foundation),
      ...List.filled(focusWeeks, LearningPhase.focus),
      ...List.filled(reviewWeeks, LearningPhase.review),
    ];
  }

  /// Phân bổ kỹ năng trọng tâm cho các ngày trong tuần dựa trên độ thiếu hụt (gap).
  List<SkillType> _allocateWeekSkills({
    required SkillScores scores,
    required int daysCount,
  }) {
    if (daysCount <= 0) return const [];

    final gaps = <SkillType, int>{
      for (final skill in SkillType.coreSkills)
        skill: math.max(10, 100 - scores.scoreOf(skill)),
    };
    final totalGap = gaps.values.fold(0, (sum, g) => sum + g);

    // Nếu tuần có >= 4 ngày, đảm bảo mỗi kỹ năng cốt lõi có tối thiểu 1 ngày.
    final counts = <SkillType, int>{
      for (final skill in SkillType.coreSkills) skill: daysCount >= 4 ? 1 : 0,
    };

    var remaining = daysCount - counts.values.fold(0, (sum, c) => sum + c);

    // Sắp xếp kỹ năng theo gap giảm dần (kỹ năng yếu nhất ưu tiên trước).
    final sortedSkills = List<SkillType>.from(SkillType.coreSkills)
      ..sort((a, b) => gaps[b]!.compareTo(gaps[a]!));

    if (remaining > 0) {
      final remainders = <SkillType, double>{};
      var allocated = 0;
      for (final skill in sortedSkills) {
        final exact = (gaps[skill]! / totalGap) * remaining;
        final floorVal = exact.floor();
        counts[skill] = counts[skill]! + floorVal;
        remainders[skill] = exact - floorVal;
        allocated += floorVal;
      }

      var leftover = remaining - allocated;
      final byRemainder = List<SkillType>.from(sortedSkills)
        ..sort((a, b) {
          final cmp = remainders[b]!.compareTo(remainders[a]!);
          return cmp != 0 ? cmp : gaps[b]!.compareTo(gaps[a]!);
        });

      var idx = 0;
      while (leftover > 0) {
        final skill = byRemainder[idx % byRemainder.length];
        counts[skill] = counts[skill]! + 1;
        leftover--;
        idx++;
      }
    }

    // Dàn đều theo vòng lặp từ kỹ năng yếu nhất để không bị dồn cục liên tiếp.
    final result = <SkillType>[];
    final workingCounts = Map<SkillType, int>.from(counts);
    while (result.length < daysCount) {
      var addedInRound = false;
      for (final skill in sortedSkills) {
        if ((workingCounts[skill] ?? 0) > 0) {
          result.add(skill);
          workingCounts[skill] = workingCounts[skill]! - 1;
          addedInRound = true;
          if (result.length == daysCount) break;
        }
      }
      if (!addedInRound) break;
    }

    return result;
  }

  List<DailyTask> _buildDayTasks({
    required int weekNumber,
    required int dayNumberInWeek,
    required SkillType focusSkill,
    required int dailyMinutes,
    required LearningPhase phase,
    required bool isWeeklyReviewDay,
    required List<LearningResourceRef> materials,
    required List<LearningResourceRef> exercises,
  }) {
    final prefix = 'w${weekNumber}_d$dayNumberInWeek';
    final mat = _pickResource(
      materials,
      focusSkill,
      seed: weekNumber * 7 + dayNumberInWeek,
      fallbackSkill: SkillType.vocabulary,
    );
    final ex = _pickResource(
      exercises,
      focusSkill,
      seed: weekNumber * 7 + dayNumberInWeek,
    );

    if (dailyMinutes == 30) {
      return [
        DailyTask(
          taskId: '${prefix}_t1',
          title: isWeeklyReviewDay
              ? 'Ôn tập tổng hợp kiến thức tuần $weekNumber'
              : mat.title,
          skill: isWeeklyReviewDay ? SkillType.vocabulary : mat.skill,
          targetModule: TargetModule.m2,
          targetResourceId: mat.id,
          estimatedMinutes: 15,
        ),
        DailyTask(
          taskId: '${prefix}_t2',
          title: isWeeklyReviewDay
              ? 'Mini-test tổng hợp cuối tuần $weekNumber'
              : ex.title,
          skill: focusSkill,
          targetModule: TargetModule.m3,
          targetResourceId: ex.id,
          estimatedMinutes: 15,
        ),
      ];
    }

    if (dailyMinutes == 45) {
      final extraSkill =
          focusSkill == SkillType.writing || focusSkill == SkillType.speaking
          ? focusSkill
          : SkillType.vocabulary;
      final extraMat = _pickResource(
        materials,
        extraSkill,
        seed: weekNumber + dayNumberInWeek + 3,
        fallbackSkill: SkillType.vocabulary,
      );
      return [
        DailyTask(
          taskId: '${prefix}_t1',
          title: mat.title,
          skill: mat.skill,
          targetModule: TargetModule.m2,
          targetResourceId: mat.id,
          estimatedMinutes: 15,
        ),
        DailyTask(
          taskId: '${prefix}_t2',
          title: isWeeklyReviewDay
              ? 'Thi thử rút gọn cuối tuần $weekNumber (${focusSkill.labelVi})'
              : ex.title,
          skill: focusSkill,
          targetModule: TargetModule.m3,
          targetResourceId: ex.id,
          estimatedMinutes: 20,
        ),
        DailyTask(
          taskId: '${prefix}_t3',
          title: phase == LearningPhase.review
              ? 'Rà soát lỗi sai & mẹo thi B1'
              : extraMat.title,
          skill: extraSkill,
          targetModule:
              phase == LearningPhase.review ? TargetModule.m3 : TargetModule.m2,
          targetResourceId:
              phase == LearningPhase.review ? ex.id : extraMat.id,
          estimatedMinutes: 10,
        ),
      ];
    }

    // 60 phút/ngày
    final followUpSkill =
        focusSkill == SkillType.listening || focusSkill == SkillType.reading
        ? SkillType.writing
        : focusSkill;
    final followUpEx = _pickResource(
      exercises,
      followUpSkill,
      seed: weekNumber * 3 + dayNumberInWeek,
    );

    return [
      DailyTask(
        taskId: '${prefix}_t1',
        title: mat.title,
        skill: mat.skill,
        targetModule: TargetModule.m2,
        targetResourceId: mat.id,
        estimatedMinutes: 20,
      ),
      DailyTask(
        taskId: '${prefix}_t2',
        title: isWeeklyReviewDay
            ? 'Đề tổng hợp B1 cuối tuần $weekNumber'
            : ex.title,
        skill: focusSkill,
        targetModule: TargetModule.m3,
        targetResourceId: ex.id,
        estimatedMinutes: 25,
      ),
      DailyTask(
        taskId: '${prefix}_t3',
        title: 'Thực hành ${followUpSkill.labelVi} & ôn lại câu sai',
        skill: followUpSkill,
        targetModule: TargetModule.m3,
        targetResourceId: followUpEx.id,
        estimatedMinutes: 15,
      ),
    ];
  }

  LearningResourceRef _pickResource(
    List<LearningResourceRef> pool,
    SkillType skill, {
    required int seed,
    SkillType? fallbackSkill,
  }) {
    final matched = pool.where((item) => item.skill == skill).toList();
    if (matched.isNotEmpty) {
      return matched[seed % matched.length];
    }
    if (fallbackSkill != null) {
      final fallbackMatched =
          pool.where((item) => item.skill == fallbackSkill).toList();
      if (fallbackMatched.isNotEmpty) {
        return fallbackMatched[seed % fallbackMatched.length];
      }
    }
    return pool[seed % pool.length];
  }

  String _buildWeekTitle({
    required int weekNumber,
    required LearningPhase phase,
    required bool isSprintMode,
    required SkillType weakestSkill,
  }) {
    if (isSprintMode) {
      return 'Tuần $weekNumber: Ôn tập nước rút 7 ngày (Ưu tiên ${weakestSkill.labelVi})';
    }
    return 'Tuần $weekNumber: ${phase.labelVi} (Ưu tiên ${weakestSkill.labelVi})';
  }

  static const List<LearningResourceRef> _defaultMaterials = [
    LearningResourceRef(
      id: 'mat_vocab_01',
      title: 'Từ vựng chủ đề Sinh hoạt & Học tập B1',
      skill: SkillType.vocabulary,
      targetModule: TargetModule.m2,
    ),
    LearningResourceRef(
      id: 'mat_grammar_01',
      title: 'Ngữ pháp cốt lõi: Thì & Mệnh đề quan hệ B1',
      skill: SkillType.reading,
      targetModule: TargetModule.m2,
    ),
    LearningResourceRef(
      id: 'mat_listen_01',
      title: 'Chiến lược nghe hiểu hội thoại & thông báo ngắn B1',
      skill: SkillType.listening,
      targetModule: TargetModule.m2,
    ),
    LearningResourceRef(
      id: 'mat_write_01',
      title: 'Mẫu câu & bố cục viết Email/Thư B1 Thủy Lợi',
      skill: SkillType.writing,
      targetModule: TargetModule.m2,
    ),
    LearningResourceRef(
      id: 'mat_speak_01',
      title: 'Dàn ý trả lời Nói Part 1–3 chủ đề quen thuộc',
      skill: SkillType.speaking,
      targetModule: TargetModule.m2,
    ),
  ];

  static const List<LearningResourceRef> _defaultExercises = [
    LearningResourceRef(
      id: 'ex_listen_01',
      title: 'Luyện Nghe Part 1 – Hội thoại ngắn B1',
      skill: SkillType.listening,
      targetModule: TargetModule.m3,
    ),
    LearningResourceRef(
      id: 'ex_read_01',
      title: 'Luyện Đọc hiểu – Tìm ý chính & từ đồng nghĩa',
      skill: SkillType.reading,
      targetModule: TargetModule.m3,
    ),
    LearningResourceRef(
      id: 'ex_write_01',
      title: 'Luyện Viết đoạn văn ngắn & Email B1',
      skill: SkillType.writing,
      targetModule: TargetModule.m3,
    ),
    LearningResourceRef(
      id: 'ex_speak_01',
      title: 'Thực hành Nói theo chủ đề & checklist phát âm',
      skill: SkillType.speaking,
      targetModule: TargetModule.m3,
    ),
  ];
}
