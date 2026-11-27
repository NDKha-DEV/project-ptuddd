import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_view.dart';

/// M3 - Làm bài. M4 mở màn này qua `AppRoutes.exerciseDetail(id)`.
class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderView(
      title: 'Bài tập $exerciseId',
      module: 'M3 - Làm bài',
      owner: 'Nguyễn Huy Hoàng',
    );
  }
}
