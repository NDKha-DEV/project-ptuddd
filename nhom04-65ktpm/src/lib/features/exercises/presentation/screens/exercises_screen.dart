import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_view.dart';

/// M3 - Luyện tập theo kỹ năng và thi thử tổng hợp.
class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderView(
      title: 'Luyện tập',
      module: 'M3 - Bài tập và đánh giá',
      owner: 'Nguyễn Huy Hoàng',
    );
  }
}
