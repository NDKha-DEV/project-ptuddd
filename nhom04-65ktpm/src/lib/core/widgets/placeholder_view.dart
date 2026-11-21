import 'package:flutter/material.dart';

/// Màn hình tạm cho module chưa làm. Xóa khi module có giao diện thật.
class PlaceholderView extends StatelessWidget {
  const PlaceholderView({
    super.key,
    required this.title,
    required this.module,
    this.owner,
  });

  final String title;
  final String module;
  final String? owner;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, size: 48),
            const SizedBox(height: 12),
            Text(module, style: textTheme.titleMedium),
            if (owner != null) Text(owner!, style: textTheme.bodySmall),
            const SizedBox(height: 4),
            Text('Đang phát triển', style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
