import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tlu_b1_daily/features/assessment/presentation/providers/attempt_history_provider.dart';
import 'package:tlu_b1_daily/features/exercises/data/services/audio_controller.dart';
import 'package:tlu_b1_daily/features/exercises/presentation/providers/exercises_provider.dart';
import 'package:tlu_b1_daily/features/exercises/presentation/screens/exercise_detail_screen.dart';
import 'package:tlu_b1_daily/features/exercises/presentation/screens/exercises_screen.dart';

import 'm3_fixtures.dart';

late AttemptHistoryProvider history;
late FakeAudioFactory audio;

/// Màn hình cao để mọi câu hỏi của bộ đề test cùng hiển thị.
void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _wrap(Widget child) => MultiProvider(
  providers: [
    ChangeNotifierProvider(
      create: (_) => ExercisesProvider(repository: fixtureRepository()),
    ),
    ChangeNotifierProvider.value(value: history),
    Provider<AudioControllerFactory>.value(value: audio),
  ],
  child: MaterialApp(home: child),
);

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    history = AttemptHistoryProvider();
    audio = FakeAudioFactory();
  });

  testWidgets('làm bài Nghe: phát audio, chọn đáp án, nộp và xem giải thích', (
    tester,
  ) async {
    _tallView(tester);
    await tester.pumpWidget(
      _wrap(const ExerciseDetailScreen(exerciseId: 'ex_listen_01')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nghe – Đề mẫu số 1'), findsOneWidget);
    await _tapText(tester, 'Bắt đầu');

    // Đồng hồ đếm ngược và trình phát audio.
    expect(find.text('01:00'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:59'), findsOneWidget);
    final player = audio.controllers.single;
    expect(player.calls.first, 'load assets/audio/m3/set_01_l1.m4a');
    await tester.tap(find.byTooltip('Phát'));
    await tester.pump();
    expect(player.calls, contains('play'));
    await tester.tap(find.byTooltip('Tới 5 giây'));
    await tester.pump();
    expect(player.calls, contains('seek 5'));

    await tester.tap(find.text('opt B').first); // đúng câu 1
    await tester.tap(find.text('opt A').last); // sai câu 2
    await tester.pump();

    await _tapText(tester, 'Nộp bài');
    expect(find.text('Bạn đã trả lời tất cả câu hỏi.'), findsOneWidget);
    await _tapText(tester, 'Nộp bài');

    expect(find.text('Kết quả'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.textContaining('Giải thích set_01_l02'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(history.attempts.single.exerciseId, 'ex_listen_01');
    expect(history.attempts.single.scorePercent, 50);
  });

  testWidgets('hết giờ thì tự nộp bài', (tester) async {
    _tallView(tester);
    await tester.pumpWidget(
      _wrap(const ExerciseDetailScreen(exerciseId: 'ex_read_01')),
    );
    await tester.pumpAndSettle();
    await _tapText(tester, 'Bắt đầu');
    await tester.pump(const Duration(seconds: 61));
    await tester.pumpAndSettle();

    expect(find.text('0%'), findsOneWidget);
    expect(find.textContaining('hết giờ, tự động nộp'), findsOneWidget);
  });

  testWidgets('Viết: soạn bài, tự chấm đủ rubric mới xem được kết quả', (
    tester,
  ) async {
    _tallView(tester);
    await tester.pumpWidget(
      _wrap(const ExerciseDetailScreen(exerciseId: 'ex_write_01')),
    );
    await tester.pumpAndSettle();
    await _tapText(tester, 'Bắt đầu');

    await tester.enterText(find.byType(TextField), 'Dear Tom, I am fine now.');
    await tester.pump();
    expect(find.text('6 từ (yêu cầu 5–10 từ)'), findsOneWidget);

    await _tapText(tester, 'Nộp bài');
    await _tapText(tester, 'Nộp bài');
    expect(find.text('Tự đánh giá Viết/Nói'), findsOneWidget);
    expect(find.text('Dear Tom, I am fine now.'), findsOneWidget);

    final submit = find.widgetWithText(FilledButton, 'Chấm đủ các tiêu chí');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    final threes = find.widgetWithText(ChoiceChip, '3');
    expect(threes, findsNWidgets(4));
    for (var i = 0; i < 4; i++) {
      await tester.ensureVisible(threes.at(i));
      await tester.tap(threes.at(i));
      await tester.pump();
    }
    await _tapText(tester, 'Xem kết quả');

    expect(find.text('100%'), findsOneWidget);
    expect(history.attempts.single.skillKey, 'writing');
  });

  testWidgets('mã bài không tồn tại thì báo lỗi', (tester) async {
    await tester.pumpWidget(
      _wrap(const ExerciseDetailScreen(exerciseId: 'ex_listen_99')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy bài tập ex_listen_99.'), findsOneWidget);
  });

  testWidgets('màn Luyện tập: lọc theo kỹ năng, thi thử, kết quả trống', (
    tester,
  ) async {
    _tallView(tester);
    await tester.pumpWidget(_wrap(const ExercisesScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Đề mẫu số 1'), findsOneWidget);
    expect(find.text('Đề mẫu số 5'), findsOneWidget);
    await tester.tap(find.text('Viết'));
    await tester.pumpAndSettle();
    expect(find.textContaining('tự chấm theo rubric'), findsOneWidget);

    await tester.tap(find.text('Thi thử').first);
    await tester.pumpAndSettle();
    expect(find.text('Thi thử – Đề mẫu số 1'), findsOneWidget);

    await tester.tap(find.text('Kết quả'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa có bài nào'), findsOneWidget);
  });
}
