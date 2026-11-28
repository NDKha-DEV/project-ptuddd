import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/exam_models.dart';

typedef AssetLoader = Future<String> Function(String path);

/// Đọc ngân hàng đề B1 đóng gói trong `assets/data/m3/` (chạy offline).
class QuestionBankRepository {
  QuestionBankRepository({AssetLoader? loader})
    : _loader = loader ?? rootBundle.loadString;

  static const setAssets = [
    'assets/data/m3/set_01.json',
    'assets/data/m3/set_02.json',
    'assets/data/m3/set_03.json',
    'assets/data/m3/set_04.json',
    'assets/data/m3/set_05.json',
  ];

  final AssetLoader _loader;

  Future<List<ExamSet>> loadSets() async {
    final sets = <ExamSet>[];
    for (final path in setAssets) {
      final raw = await _loader(path);
      sets.add(
        ExamSet.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map)),
      );
    }
    return sets;
  }
}
