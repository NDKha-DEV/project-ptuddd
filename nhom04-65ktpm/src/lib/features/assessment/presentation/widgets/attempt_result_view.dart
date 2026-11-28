import 'package:flutter/material.dart';

import '../../../exercises/data/models/exam_models.dart';
import '../../../exercises/data/models/exercise.dart';
import '../../../exercises/presentation/widgets/question_card.dart';
import '../../data/models/exercise_attempt.dart';
import '../../domain/rubrics.dart';
import '../../domain/scoring.dart';
import 'rubric_checklist.dart';

/// Kết quả một lần làm bài: điểm tổng, điểm từng kỹ năng, đáp án + giải thích, bài mẫu.
class AttemptResultView extends StatelessWidget {
  const AttemptResultView({
    super.key,
    required this.exercise,
    required this.attempt,
    this.actions = const [],
  });

  final Exercise exercise;
  final ExerciseAttempt attempt;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryCard(attempt: attempt),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
        for (final section in exercise.sections) ...[
          const SizedBox(height: 20),
          Text(
            'Xem lại phần ${section.skill.labelVi}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (section.skill.isAutoGraded)
            ..._objectiveReview(section)
          else
            for (final task in section.tasks)
              _TaskReview(skill: section.skill, task: task, attempt: attempt),
        ],
      ],
    );
  }

  List<Widget> _objectiveReview(ExamSection section) {
    var number = 0;
    return [
      for (final group in section.groups) ...[
        _GroupHeader(group: group),
        for (final question in group.questions)
          QuestionCard(
            number: ++number,
            question: question,
            selected: attempt.answers[question.id],
            review: true,
          ),
      ],
    ];
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.attempt});

  final ExerciseAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = attempt.scorePercent;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$score%',
                  key: const ValueKey('attempt_score'),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: score >= Scoring.passPercent
                        ? Colors.green.shade700
                        : theme.colorScheme.error,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Scoring.verdictVi(score),
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        'Thời gian: ${attempt.durationMinutes} phút'
                        '${attempt.timedOut ? ' · hết giờ, tự động nộp' : ''}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final result in attempt.skillResults)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(result.skill.labelVi),
                        const Spacer(),
                        Text(
                          result.skill.isAutoGraded
                              ? '${result.earned}/${result.possible} câu · ${result.scorePercent}%'
                              : 'Tự chấm ${result.earned}/${result.possible} · ${result.scorePercent}%',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: result.scorePercent / 100,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
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

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final QuestionGroup group;

  @override
  Widget build(BuildContext context) {
    final hasTranscript = group.transcript.isNotEmpty;
    final passage = group.passage;
    if (!hasTranscript && passage == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(group.title, style: Theme.of(context).textTheme.titleSmall),
      );
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(group.title),
        subtitle: Text(hasTranscript ? 'Xem transcript' : 'Xem lại đoạn văn'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTranscript)
            for (final line in group.transcript)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${_speakerLabel(line.speaker)}: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: line.text),
                    ],
                  ),
                ),
              )
          else
            Text(passage!),
        ],
      ),
    );
  }

  static String _speakerLabel(String speaker) => switch (speaker) {
    'M' => 'Man',
    'W' => 'Woman',
    _ => 'Speaker',
  };
}

class _TaskReview extends StatelessWidget {
  const _TaskReview({
    required this.skill,
    required this.task,
    required this.attempt,
  });

  final ExamSkill skill;
  final ProductiveTask task;
  final ExerciseAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final response = attempt.responses[task.id];
    final marks = attempt.rubric[task.id] ?? const {};
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(task.prompt, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              skill == ExamSkill.writing ? 'Bài của bạn' : 'Ghi chú của bạn',
              style: theme.textTheme.labelLarge,
            ),
            Text(
              response ?? '(Không có)',
              style: response == null
                  ? TextStyle(color: theme.colorScheme.outline)
                  : null,
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Bài mẫu đối chiếu'),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [SelectableText(task.sampleAnswer)],
            ),
            RubricChecklist(
              criteria: B1Rubrics.forSkill(skill),
              valueOf: (id) => marks[id],
            ),
          ],
        ),
      ),
    );
  }
}
