import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../exercises/data/models/exercise.dart';
import '../../data/models/exercise_attempt.dart';
import '../widgets/attempt_result_view.dart';

/// Xem lại một lần làm bài trong lịch sử.
class AttemptReviewScreen extends StatelessWidget {
  const AttemptReviewScreen({
    super.key,
    required this.exercise,
    required this.attempt,
  });

  final Exercise exercise;
  final ExerciseAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final when = DateFormat('HH:mm dd/MM/yyyy')
        .format(attempt.completedAt.toLocal());
    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Làm lúc $when'),
          ),
        ),
      ),
      body: AttemptResultView(exercise: exercise, attempt: attempt),
    );
  }
}
