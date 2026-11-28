import 'package:flutter/material.dart';

import '../../data/models/learning_path_model.dart';

/// Thanh cuộn ngang chọn tuần trong lộ trình học tập.
class WeekSelector extends StatelessWidget {
  const WeekSelector({
    super.key,
    required this.weeks,
    required this.selectedWeekNumber,
    required this.currentWeekNumber,
    required this.onWeekSelected,
  });

  final List<WeekPlan> weeks;
  final int selectedWeekNumber;
  final int currentWeekNumber;
  final ValueChanged<int> onWeekSelected;

  @override
  Widget build(BuildContext context) {
    if (weeks.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: weeks.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final week = weeks[index];
          final isSelected = week.weekNumber == selectedWeekNumber;
          final isCurrent = week.weekNumber == currentWeekNumber;
          final percent = (week.completionRate * 100).round();

          final backgroundColor = isSelected
              ? scheme.primaryContainer
              : scheme.surfaceContainerLow;
          final borderColor = isSelected
              ? scheme.primary
              : isCurrent
              ? scheme.outline
              : scheme.outlineVariant;
          final foregroundColor = isSelected
              ? scheme.onPrimaryContainer
              : scheme.onSurface;

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onWeekSelected(week.weekNumber),
            child: Container(
              constraints: const BoxConstraints(minWidth: 104),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tuần ${week.weekNumber}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (week.isCompleted) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check_circle,
                          size: 15,
                          color: Colors.green.shade700,
                        ),
                      ] else if (isCurrent) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.radio_button_checked,
                          size: 13,
                          color: scheme.primary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    week.isCompleted ? 'Hoàn thành' : '$percent% xong',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
