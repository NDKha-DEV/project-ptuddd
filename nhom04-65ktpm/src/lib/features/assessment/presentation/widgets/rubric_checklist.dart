import 'package:flutter/material.dart';

import '../../domain/rubrics.dart';

/// Bảng tự chấm theo rubric: mỗi tiêu chí chọn 1 trong 4 mức 0–3.
class RubricChecklist extends StatelessWidget {
  const RubricChecklist({
    super.key,
    required this.criteria,
    required this.valueOf,
    this.onChanged,
  });

  final List<RubricCriterion> criteria;
  final int? Function(String criterionId) valueOf;

  /// null = chỉ xem (ví dụ khi xem lại lịch sử).
  final void Function(String criterionId, int points)? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final criterion in criteria) ...[
          Text(criterion.titleVi, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              for (final level in criterion.levels)
                ChoiceChip(
                  label: Text('${level.points}'),
                  selected: valueOf(criterion.id) == level.points,
                  onSelected: onChanged == null
                      ? null
                      : (_) => onChanged!(criterion.id, level.points),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              _description(criterion),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ],
    );
  }

  String _description(RubricCriterion criterion) {
    final value = valueOf(criterion.id);
    if (value == null) return 'Chọn mức phù hợp với bài của bạn.';
    return criterion.levels.firstWhere((l) => l.points == value).descriptionVi;
  }
}
