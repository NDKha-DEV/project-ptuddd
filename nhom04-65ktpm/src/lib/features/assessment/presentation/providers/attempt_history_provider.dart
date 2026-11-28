import 'package:flutter/foundation.dart';

import '../../data/models/exercise_attempt.dart';
import '../../data/repositories/attempt_repository.dart';
import '../../domain/skill_stats.dart';

/// Lịch sử làm bài và thống kê theo kỹ năng của người dùng hiện tại.
class AttemptHistoryProvider extends ChangeNotifier {
  AttemptHistoryProvider({AttemptRepository? repository})
    : _repository = repository ?? AttemptRepository();

  /// Dùng khi chưa có uid (ví dụ khi chạy test không có Supabase).
  static const localUid = 'local';

  final AttemptRepository _repository;

  String _uid = localUid;
  List<ExerciseAttempt> _attempts = [];
  SkillStatsSummary _summary = SkillStatsSummary.fromAttempts(const []);
  bool _loaded = false;

  List<ExerciseAttempt> get attempts => List.unmodifiable(_attempts);
  SkillStatsSummary get summary => _summary;
  bool get isLoaded => _loaded;

  /// Đổi người dùng thì tải lại lịch sử của người đó.
  Future<void> loadFor(String? uid) async {
    final next = (uid == null || uid.isEmpty) ? localUid : uid;
    if (_loaded && next == _uid) return;
    _uid = next;
    _setAttempts(await _repository.loadAll(_uid));
  }

  Future<void> add(ExerciseAttempt attempt) async {
    await _repository.save(_uid, attempt);
    _setAttempts([attempt, ..._attempts.where((a) => a.id != attempt.id)]);
  }

  Future<void> clear() async {
    await _repository.clear(_uid);
    _setAttempts([]);
  }

  List<ExerciseAttempt> attemptsFor(String exerciseId) =>
      _attempts.where((a) => a.exerciseId == exerciseId).toList();

  int? bestScoreFor(String exerciseId) {
    final scores = attemptsFor(exerciseId).map((a) => a.scorePercent);
    return scores.isEmpty ? null : scores.reduce((a, b) => a > b ? a : b);
  }

  void _setAttempts(List<ExerciseAttempt> attempts) {
    _attempts = attempts;
    _summary = SkillStatsSummary.fromAttempts(attempts);
    _loaded = true;
    notifyListeners();
  }
}
