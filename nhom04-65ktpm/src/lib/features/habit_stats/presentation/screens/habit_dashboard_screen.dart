import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_view.dart';

/// M5 - Daily You: mục tiêu 30-60 phút/ngày, Study Timer, streak, thống kê.
class HabitDashboardScreen extends StatelessWidget {
  const HabitDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderView(
      title: 'Hôm nay',
      module: 'M5 - Thói quen và thống kê tiến độ',
      owner: 'Nguyễn Đình Kha',
    );
  }
}
