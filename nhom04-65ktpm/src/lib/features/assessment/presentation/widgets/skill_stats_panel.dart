import 'package:flutter/material.dart';

import '../../../exercises/data/models/exam_models.dart';
import '../../domain/skill_stats.dart';

/// Thống kê điểm theo 4 kỹ năng: trung bình, cao nhất, xu hướng 5 lần gần nhất.
class SkillStatsPanel extends StatelessWidget {
  const SkillStatsPanel({super.key, required this.summary, this.onPractice});

  final SkillStatsSummary summary;
  final ValueChanged<ExamSkill>? onPractice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weakest = summary.weakestSkill;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (weakest != null)
          Card(
            color: theme.colorScheme.tertiaryContainer,
            child: ListTile(
              leading: const Icon(Icons.trending_down),
              title: Text('Kỹ năng cần ưu tiên: ${weakest.labelVi}'),
              subtitle: Text(
                'Điểm trung bình ${summary.of(weakest).average}% – thấp nhất trong các kỹ năng đã làm.',
              ),
              trailing: onPractice == null
                  ? null
                  : TextButton(
                      onPressed: () => onPractice!(weakest),
                      child: const Text('Luyện ngay'),
                    ),
            ),
          ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.25,
          children: [
            for (final skill in ExamSkill.values)
              _SkillTile(stat: summary.of(skill)),
          ],
        ),
      ],
    );
  }
}

class _SkillTile extends StatelessWidget {
  const _SkillTile({required this.stat});

  final SkillStat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trend = stat.trend;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(stat.skill.labelVi, style: theme.textTheme.titleSmall),
                const Spacer(),
                if (trend != null)
                  Text(
                    trend >= 0 ? '+$trend' : '$trend',
                    style: TextStyle(
                      color: trend >= 0
                          ? Colors.green.shade700
                          : theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              stat.hasData ? '${stat.average}%' : '–',
              style: theme.textTheme.headlineSmall,
            ),
            Text(
              stat.hasData
                  ? '${stat.attempts} lần · cao nhất ${stat.best}%'
                  : 'Chưa làm bài',
              style: theme.textTheme.bodySmall,
            ),
            const Spacer(),
            SizedBox(
              height: 28,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final score in stat.recent)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: FractionallySizedBox(
                          heightFactor: (score / 100).clamp(0.06, 1.0),
                          alignment: Alignment.bottomCenter,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
