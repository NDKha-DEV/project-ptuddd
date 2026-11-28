import 'package:flutter/material.dart';

import '../../data/models/exam_models.dart';

/// Câu hỏi trắc nghiệm. Khi [review] = true: tô đáp án đúng/sai và hiện giải thích.
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.number,
    required this.question,
    this.selected,
    this.onSelect,
    this.review = false,
  });

  final int number;
  final Question question;
  final int? selected;
  final ValueChanged<int>? onSelect;
  final bool review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final correct = question.isCorrect(selected);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Câu $number. ', style: theme.textTheme.titleSmall),
                Expanded(
                  child: Text(
                    question.prompt,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                if (review)
                  Icon(
                    correct ? Icons.check_circle : Icons.cancel,
                    color: correct ? Colors.green : scheme.error,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < question.options.length; i++)
              _OptionTile(
                label: Question.optionLabel(i),
                text: question.options[i],
                selected: selected == i,
                state: !review
                    ? _OptionState.normal
                    : i == question.answerIndex
                    ? _OptionState.correct
                    : selected == i
                    ? _OptionState.wrong
                    : _OptionState.normal,
                onTap: review || onSelect == null ? null : () => onSelect!(i),
              ),
            if (review) ...[
              if (selected == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Bạn chưa chọn đáp án.',
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            'Đáp án ${Question.optionLabel(question.answerIndex)}. ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: question.explanationVi),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _OptionState { normal, correct, wrong }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.text,
    required this.selected,
    required this.state,
    this.onTap,
  });

  final String label;
  final String text;
  final bool selected;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color border, Color? fill) = switch (state) {
      _OptionState.correct => (
        Colors.green,
        Colors.green.withValues(alpha: 0.12),
      ),
      _OptionState.wrong => (scheme.error, scheme.errorContainer),
      _OptionState.normal when selected => (
        scheme.primary,
        scheme.primaryContainer,
      ),
      _OptionState.normal => (scheme.outlineVariant, null),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: fill ?? Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: border, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Text(
                  '$label.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(text)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
