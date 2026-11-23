import 'package:flutter/material.dart';

import '../../data/models/assessment_result_model.dart';
import '../../data/models/skill_scores.dart';

/// Thẻ hiển thị phân tích 4 kỹ năng B1 (điểm hiện tại, mức phân loại và kỹ năng ưu tiên).
class SkillSummaryCard extends StatelessWidget {
  const SkillSummaryCard({
    super.key,
    required this.currentScores,
    this.initialScores,
    this.title = 'Phân tích 4 kỹ năng B1',
  });

  final SkillScores currentScores;
  final SkillScores? initialScores;
  final String title;

  Color _colorForTier(BuildContext context, SkillLevelTier tier) {
    final scheme = Theme.of(context).colorScheme;
    switch (tier) {
      case SkillLevelTier.needsFoundation:
        return scheme.error;
      case SkillLevelTier.intermediate:
        return Colors.orange.shade700;
      case SkillLevelTier.good:
        return Colors.green.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weakest = currentScores.weakestSkill;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'TB: ${currentScores.averageScore.round()}/100',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < SkillType.coreSkills.length; i++) ...[
              _SkillProgressRow(
                skill: SkillType.coreSkills[i],
                score: currentScores.scoreOf(SkillType.coreSkills[i]),
                initialScore: initialScores?.scoreOf(SkillType.coreSkills[i]),
                isWeakest: SkillType.coreSkills[i] == weakest,
                barColor: _colorForTier(
                  context,
                  SkillLevelTier.fromScore(
                    currentScores.scoreOf(SkillType.coreSkills[i]),
                  ),
                ),
              ),
              if (i < SkillType.coreSkills.length - 1)
                const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkillProgressRow extends StatelessWidget {
  const _SkillProgressRow({
    required this.skill,
    required this.score,
    required this.initialScore,
    required this.isWeakest,
    required this.barColor,
  });

  final SkillType skill;
  final int score;
  final int? initialScore;
  final bool isWeakest;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tier = SkillLevelTier.fromScore(score);
    final delta = initialScore == null ? 0 : score - initialScore!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    skill.labelVi,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isWeakest)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Ưu tiên',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (delta != 0) ...[
              Text(
                delta > 0 ? '+$delta' : '$delta',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: delta > 0
                      ? Colors.green.shade700
                      : theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              '$score/100',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: score / 100.0,
            minHeight: 8,
            color: barColor,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tier.labelVi,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
