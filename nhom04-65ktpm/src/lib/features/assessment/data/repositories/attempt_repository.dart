import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise_attempt.dart';

/// Lưu lịch sử làm bài trên thiết bị theo từng người dùng.
///
/// Khi M1 chốt bảng Supabase `attempts`, thêm bước đồng bộ tại [save] mà
/// không đổi giao diện lớp này.
class AttemptRepository {
  AttemptRepository({SharedPreferences? prefs}) {
    _prefs = prefs;
  }

  /// Giữ tối đa chừng này lần làm gần nhất để không phình bộ nhớ.
  static const maxAttempts = 200;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _store async =>
      _prefs ??= await SharedPreferences.getInstance();

  String _key(String uid) => 'm3_attempts_$uid';

  /// Lịch sử mới nhất trước.
  Future<List<ExerciseAttempt>> loadAll(String uid) async {
    final raw = (await _store).getString(_key(uid));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      final attempts = [
        for (final item in list)
          ExerciseAttempt.fromJson(Map<String, dynamic>.from(item as Map)),
      ]..sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return attempts;
    } on FormatException {
      return [];
    }
  }

  Future<void> save(String uid, ExerciseAttempt attempt) async {
    final attempts = await loadAll(uid)
      ..removeWhere((a) => a.id == attempt.id)
      ..insert(0, attempt);
    final kept = attempts.take(maxAttempts).map((a) => a.toJson()).toList();
    await (await _store).setString(_key(uid), jsonEncode(kept));
  }

  Future<void> clear(String uid) async {
    await (await _store).remove(_key(uid));
  }
}
