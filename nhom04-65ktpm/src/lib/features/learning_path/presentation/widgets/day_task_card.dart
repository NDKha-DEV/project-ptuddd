import 'package:flutter/material.dart';

import '../../data/models/daily_task_model.dart';
import '../../data/models/learning_path_model.dart';
import '../../data/models/skill_scores.dart';

/// Thẻ hiển thị kế hoạch 1 ngày và danh sách nhiệm vụ `DailyTask`.
class DayTaskCard extends StatefulWidget {
  const DayTaskCard({
    super.key,
    required this.day,
    required this.onToggleTask,
    required this.onOpenTask,
    this.isToday = false,
    this.initiallyExpanded = false,
  });

  final DayPlan day;
  final ValueChanged<DailyTask> onToggleTask;
  final ValueChanged<DailyTask> onOpenTask;
  final bool isToday;
  final bool initiallyExpanded;

  @override
  State<DayTaskCard> createState() => _DayTaskCardState();
}

class _DayTaskCardState extends State<DayTaskCard> {
  late bool _expanded = widget.initiallyExpanded || widget.isToday;

  @override
  void didUpdateWidget(covariant DayTaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isToday && !oldWidget.isToday) {
      _expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final day = widget.day;
    final doneCount = day.tasks.where((task) => task.isCompleted).length;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: widget.isToday
            ? BorderSide(color: scheme.primary, width: 1.5)
            : BorderSide(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    day.isCompleted
                        ? Icons.check_circle
                        : widget.isToday
                        ? Icons.today
                        : Icons.calendar_today_outlined,
                    color: day.isCompleted
                        ? Colors.green.shade700
                        : widget.isToday
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Ngày ${day.dayIndex} · ${day.date}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (widget.isToday)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Hôm nay',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Trọng tâm: ${day.focusSkill.labelVi} · ${day.totalMinutes} phút · $doneCount/${day.tasks.length} xong',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  for (var i = 0; i < day.tasks.length; i++) ...[
                    _DailyTaskTile(
                      task: day.tasks[i],
                      onToggle: () => widget.onToggleTask(day.tasks[i]),
                      onOpen: () => widget.onOpenTask(day.tasks[i]),
                    ),
                    if (i < day.tasks.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DailyTaskTile extends StatelessWidget {
  const _DailyTaskTile({
    required this.task,
    required this.onToggle,
    required this.onOpen,
  });

  final DailyTask task;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  Color _skillColor(BuildContext context, SkillType skill) {
    final scheme = Theme.of(context).colorScheme;
    switch (skill) {
      case SkillType.listening:
        return scheme.primary;
      case SkillType.reading:
        return Colors.teal.shade700;
      case SkillType.writing:
        return Colors.deepPurple.shade600;
      case SkillType.speaking:
        return Colors.orange.shade800;
      case SkillType.vocabulary:
        return Colors.indigo.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final badgeColor = _skillColor(context, task.skill);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: task.isCompleted
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.45)
            : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: task.isCompleted,
            onChanged: (_) => onToggle(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.isCompleted
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _MetaChip(
                      label: task.skill.labelVi,
                      color: badgeColor,
                    ),
                    _MetaChip(
                      label: '${task.estimatedMinutes}p',
                      color: scheme.secondary,
                    ),
                    _MetaChip(
                      label: task.targetModule == TargetModule.m2
                          ? 'M2 Tài liệu'
                          : 'M3 Bài tập',
                      color: scheme.tertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: onOpen,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
            child: const Text('Học ngay'),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
