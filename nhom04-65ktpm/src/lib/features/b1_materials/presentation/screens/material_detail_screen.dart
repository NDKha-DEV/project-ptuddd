import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_view.dart';

/// M2 - Chi tiết tài liệu. M4 mở màn này qua `AppRoutes.materialDetail(id)`.
class MaterialDetailScreen extends StatelessWidget {
  const MaterialDetailScreen({super.key, required this.materialId});

  final String materialId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderView(
      title: 'Tài liệu $materialId',
      module: 'M2 - Chi tiết tài liệu',
      owner: 'Trịnh Quốc Bảo',
    );
  }
}
