import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tlu_b1_daily/features/assessment/data/models/exercise_attempt.dart';
import 'package:tlu_b1_daily/features/assessment/data/repositories/attempt_repository.dart';
import 'package:tlu_b1_daily/features/assessment/presentation/providers/attempt_history_provider.dart';
import 'package:tlu_b1_daily/features/exercises/data/models/exam_models.dart';

ExerciseAttempt _attempt(String id, int day, int earned) => ExerciseAttempt(
  id: id,
  exerciseId: 'ex_listen_01',
  setId: 'set_01',
  isMock: false,
  startedAt: DateTime.utc(2026, 11, day, 8),
  completedAt: DateTime.utc(2026, 11, day, 8, 15),
  skillResults: [
    SkillResult(skill: ExamSkill.listening, earned: earned, possible: 8),
  ],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('lưu và đọc lịch sử theo uid, mới nhất trước', () async {
    final repo = AttemptRepository();
    await repo.save('u1', _attempt('a', 1, 4));
    await repo.save('u1', _attempt('b', 2, 6));
    await repo.save('u2', _attempt('c', 3, 8));

    final u1 = await repo.loadAll('u1');
    expect(u1.map((a) => a.id), ['b', 'a']);
    expect((await repo.loadAll('u2')).single.id, 'c');
  });

  test('lưu lại cùng id thì ghi đè, không nhân bản', () async {
    final repo = AttemptRepository();
    await repo.save('u1', _attempt('a', 1, 4));
    await repo.save('u1', _attempt('a', 1, 7));
    final all = await repo.loadAll('u1');
    expect(all.single.resultOf(ExamSkill.listening)!.earned, 7);
  });

  test('dữ liệu hỏng thì trả về rỗng thay vì crash', () async {
    SharedPreferences.setMockInitialValues({'m3_attempts_u1': 'not json'});
    expect(await AttemptRepository().loadAll('u1'), isEmpty);
  });

  test('provider đổi uid thì tải lịch sử của người đó', () async {
    final repo = AttemptRepository();
    await repo.save('u1', _attempt('a', 1, 8));
    final provider = AttemptHistoryProvider(repository: repo);

    await provider.loadFor('u1');
    expect(provider.bestScoreFor('ex_listen_01'), 100);

    await provider.loadFor('u2');
    expect(provider.attempts, isEmpty);

    await provider.add(_attempt('b', 2, 2));
    expect(provider.summary.of(ExamSkill.listening).average, 25);
    expect((await repo.loadAll('u2')).single.id, 'b');
  });
}
