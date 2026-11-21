import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_view.dart';

/// M4 - Lộ trình học theo tuần/ngày. Đặc tả: docs/M4_Dac_Ta_Thiet_Ke_Lo_Trinh_Hoc_Tap.md
class LearningPathScreen extends StatelessWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderView(
      title: 'Lộ trình',
      module: 'M4 - Lộ trình học tập',
      owner: 'Nguyễn Tùng Dương',
    );
  }
}
