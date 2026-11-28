import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_b1_daily/features/exercises/domain/exercise_catalog.dart';
import 'package:tlu_b1_daily/features/exercises/presentation/providers/exercise_session.dart';

import 'm3_fixtures.dart';

void main() {
  final catalog = ExerciseCatalog([fixtureSet(1), fixtureSet(2)]);

  test('luyện Đọc: chọn đáp án, nộp bài, chấm điểm ngay', () {
    var now = DateTime.utc(2026, 11, 28, 9);
    final session = ExerciseSession(
      catalog.byId('ex_read_01')!,
      clock: () => now,
    );
    expect(session.phase, SessionPhase.intro);
    session.start();
    session.selectAnswer('set_01_r01', 0);
    session.selectAnswer('set_01_r02', 2);
    session.selectAnswer('set_01_r02', 3); // đổi ý
    expect(session.answeredCount, 2);

    now = now.add(const Duration(minutes: 3));
    session.finishWork();

    expect(session.phase, SessionPhase.finished);
    final attempt = session.attempt!;
    expect(attempt.scorePercent, 100);
    expect(attempt.durationMinutes, 3);
    expect(attempt.timedOut, isFalse);
    session.dispose();
  });

  testWidgets('thi thử: hết giờ tự nộp, sang bước tự đánh giá Viết/Nói', (
    tester,
  ) async {
    final session = ExerciseSession(catalog.byId('mock_01')!);
    addTearDown(session.dispose);
    session.start();
    expect(session.remainingSeconds, 4 * 60);
    session.selectAnswer('set_01_l01', 1);
    session.updateResponse('set_01_w1', '  Dear Tom, see you soon.  ');

    await tester.pump(const Duration(seconds: 10));
    expect(session.remainingSeconds, 230);

    await tester.pump(const Duration(minutes: 4));
    expect(session.phase, SessionPhase.selfAssess);
    expect(session.timedOut, isTrue);

    // Không nhận đáp án sau khi hết giờ.
    session.selectAnswer('set_01_l02', 2);
    expect(session.answerOf('set_01_l02'), isNull);

    for (final id in ['task', 'organisation', 'vocabulary', 'grammar']) {
      session.rate('set_01_w1', id, 3);
    }
    session.submitSelfAssessment();

    final attempt = session.attempt!;
    expect(attempt.isMock, isTrue);
    expect(attempt.timedOut, isTrue);
    expect(attempt.responses['set_01_w1'], 'Dear Tom, see you soon.');
    final scores = {
      for (final r in attempt.skillResults) r.skill.key: r.scorePercent,
    };
    expect(scores, {
      'listening': 50,
      'reading': 0,
      'writing': 100,
      'speaking': 0,
    });
  });
}
