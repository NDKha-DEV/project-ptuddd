import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../data/models/daily_task_model.dart';
import '../../data/models/learning_path_model.dart';
import '../../domain/services/learning_path_generator.dart';
import '../providers/learning_path_provider.dart';
import '../widgets/day_task_card.dart';
import '../widgets/skill_summary_card.dart';
import '../widgets/week_selector.dart';
import 'english_tours_screen.dart';
import 'onboarding_survey_screen.dart';

/// M4 - Màn hình chính Tab Lộ trình học tập B1.
class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({
    super.key,
    this.onOpenTask,
    this.onOpenSurvey,
    this.onOpenTours,
  });

  final ValueChanged<DailyTask>? onOpenTask;
  final VoidCallback? onOpenSurvey;
  final VoidCallback? onOpenTours;

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<LearningPathProvider>();
      if (!provider.hasActivePlan &&
          provider.tours.isEmpty &&
          !provider.isLoading) {
        provider.loadInitialData();
      }
    });
  }

  void _handleOpenTask(BuildContext context, DailyTask task) {
    if (widget.onOpenTask != null) {
      widget.onOpenTask!(task);
      return;
    }
    final route = task.targetModule == TargetModule.m2
        ? AppRoutes.materialDetail(task.targetResourceId)
        : AppRoutes.exerciseDetail(task.targetResourceId);
    context.push(route);
  }

  void _handleOpenSurvey(BuildContext context) {
    if (widget.onOpenSurvey != null) {
      widget.onOpenSurvey!();
      return;
    }
    if (GoRouter.maybeOf(context) != null) {
      context.push(AppRoutes.learningPathSurvey);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => const OnboardingSurveyScreen(),
      ),
    );
  }

  void _handleOpenTours(BuildContext context) {
    if (widget.onOpenTours != null) {
      widget.onOpenTours!();
      return;
    }
    if (GoRouter.maybeOf(context) != null) {
      context.push(AppRoutes.learningPathTours);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const EnglishToursScreen(),
      ),
    );
  }

  void _showSkillSummarySheet(BuildContext context, LearningPath plan) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: SkillSummaryCard(
          currentScores: plan.currentScores,
          initialScores: plan.initialScores,
        ),
      ),
    );
  }

  Future<void> _showRescheduleSheet(
    BuildContext context,
    LearningPathProvider provider,
    LearningPath plan,
  ) async {
    var selectedMinutes = plan.dailyMinutes;
    var selectedExamDate =
        DateTime.tryParse(plan.examDate) ??
        DateTime.now().add(const Duration(days: 56));
    final today = DateTime.now();
    final minDate = DateTime(today.year, today.month, today.day);
    if (selectedExamDate.isBefore(minDate)) {
      selectedExamDate = minDate.add(const Duration(days: 7));
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Điều chỉnh lịch ôn tập',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chỉ cập nhật các ngày chưa hoàn thành, giữ nguyên lịch sử đã học.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Quỹ thời gian mỗi ngày',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final m in AppConstants.dailyMinuteOptions)
                        ChoiceChip(
                          label: Text('$m phút'),
                          selected: selectedMinutes == m,
                          onSelected: (_) =>
                              setModalState(() => selectedMinutes = m),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ngày thi: ${LearningPathGenerator.formatDate(selectedExamDate)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedExamDate,
                            firstDate: minDate,
                            lastDate: minDate.add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setModalState(() => selectedExamDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: const Text('Đổi ngày'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      child: const Text('Cập nhật lộ trình'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      await provider.rescheduleSettings(
        dailyMinutes: selectedMinutes,
        examDate: selectedExamDate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LearningPathProvider>();
    final plan = provider.activePlan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lộ trình học tập'),
        actions: [
          if (plan != null) ...[
            IconButton(
              tooltip: 'Điều chỉnh lịch học',
              onPressed: provider.isSaving
                  ? null
                  : () => _showRescheduleSheet(context, provider, plan),
              icon: const Icon(Icons.tune),
            ),
            IconButton(
              tooltip: 'Khảo sát lại',
              onPressed: provider.isSaving
                  ? null
                  : () => _handleOpenSurvey(context),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ],
      ),
      body: _buildBody(context, provider, plan),
    );
  }

  Widget _buildBody(
    BuildContext context,
    LearningPathProvider provider,
    LearningPath? plan,
  ) {
    if (provider.isLoading && plan == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Đang tải lộ trình học tập...'),
          ],
        ),
      );
    }

    if (plan == null) {
      return _EmptyLearningPathView(
        toursCount: provider.tours.length,
        onStartSurvey: () => _handleOpenSurvey(context),
        onOpenTours: () => _handleOpenTours(context),
      );
    }

    final selectedWeek = provider.selectedWeek;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (provider.errorMessage != null) ...[
          MaterialBanner(
            backgroundColor: scheme.errorContainer,
            content: Text(
              provider.errorMessage!,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
            actions: [
              TextButton(
                onPressed: provider.clearError,
                child: const Text('Đóng'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        _OverviewHeaderCard(
          plan: plan,
          daysUntilExam: provider.daysUntilExam,
          onShowSkills: () => _showSkillSummarySheet(context, plan),
          onRetakeSurvey: () => _handleOpenSurvey(context),
        ),
        const SizedBox(height: 12),
        _ToursBannerCard(
          totalTours: provider.tours.length,
          savedCount: provider.savedTourIds.length,
          onTap: () => _handleOpenTours(context),
        ),
        const SizedBox(height: 16),
        WeekSelector(
          weeks: plan.weeks,
          selectedWeekNumber: provider.selectedWeekNumber,
          currentWeekNumber: plan.currentWeek,
          onWeekSelected: provider.selectWeek,
        ),
        if (selectedWeek != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedWeek.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(selectedWeek.phase.labelVi),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < selectedWeek.days.length; i++) ...[
            DayTaskCard(
              key: ValueKey('week_${selectedWeek.weekNumber}_day_${selectedWeek.days[i].dayIndex}'),
              day: selectedWeek.days[i],
              isToday: selectedWeek.days[i].date == provider.todayDateKey,
              initiallyExpanded:
                  selectedWeek.days[i].date == provider.todayDateKey ||
                  (i == 0 &&
                      selectedWeek.days.every(
                        (d) => d.date != provider.todayDateKey,
                      )),
              onToggleTask: (task) =>
                  provider.toggleTaskCompletion(task.taskId),
              onOpenTask: (task) => _handleOpenTask(context, task),
            ),
            if (i < selectedWeek.days.length - 1) const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _EmptyLearningPathView extends StatelessWidget {
  const _EmptyLearningPathView({
    required this.toursCount,
    required this.onStartSurvey,
    required this.onOpenTours,
  });

  final int toursCount;
  final VoidCallback onStartSurvey;
  final VoidCallback onOpenTours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.route_rounded, size: 56, color: scheme.primary),
                const SizedBox(height: 12),
                Text(
                  'Chưa có lộ trình B1 cá nhân',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Thực hiện khảo sát nhanh để hệ thống phân bổ lộ trình theo tuần và từng ngày vừa khít quỹ thời gian 30–60 phút/ngày.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onStartSurvey,
                    icon: const Icon(Icons.assignment_outlined),
                    label: const Text('Bắt đầu khảo sát tạo lộ trình'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ToursBannerCard(
          totalTours: toursCount,
          savedCount: 0,
          onTap: onOpenTours,
        ),
      ],
    );
  }
}

class _OverviewHeaderCard extends StatelessWidget {
  const _OverviewHeaderCard({
    required this.plan,
    required this.daysUntilExam,
    required this.onShowSkills,
    required this.onRetakeSurvey,
  });

  final LearningPath plan;
  final int? daysUntilExam;
  final VoidCallback onShowSkills;
  final VoidCallback onRetakeSurvey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final percent = (plan.completionRate * 100).round();

    return Card(
      color: scheme.primaryContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    daysUntilExam != null
                        ? 'Còn $daysUntilExam ngày tới kỳ thi B1'
                        : 'Mục tiêu thi: ${plan.examDate}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${plan.dailyMinutes} phút/ngày · Thi ${plan.examDate}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tiến độ tổng thể: $percent%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'Tuần ${plan.currentWeek}/${plan.totalWeeks}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: plan.completionRate.clamp(0.0, 1.0),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onShowSkills,
                  icon: const Icon(Icons.bar_chart_rounded, size: 18),
                  label: const Text('Phân tích 4 kỹ năng'),
                ),
                OutlinedButton.icon(
                  onPressed: onRetakeSurvey,
                  icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                  label: const Text('Khảo sát lại'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToursBannerCard extends StatelessWidget {
  const _ToursBannerCard({
    required this.totalTours,
    required this.savedCount,
    required this.onTap,
  });

  final int totalTours;
  final int savedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: scheme.secondaryContainer,
                foregroundColor: scheme.onSecondaryContainer,
                child: const Icon(Icons.directions_walk_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thực hành giao tiếp thực tế – Tour dẫn tiếng Anh & CLB',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalTours gợi ý tại Hà Nội · Đã lưu $savedCount',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
