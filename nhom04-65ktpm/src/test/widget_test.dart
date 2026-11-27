import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlu_b1_daily/app.dart';
import 'package:tlu_b1_daily/features/auth/presentation/providers/auth_provider.dart';
import 'package:tlu_b1_daily/features/learning_path/data/repositories/learning_path_repository.dart';
import 'package:tlu_b1_daily/features/learning_path/presentation/providers/learning_path_provider.dart';

Widget _buildApp() => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider(firebaseReady: false)),
    ChangeNotifierProvider(
      create: (_) => LearningPathProvider(
        repository: LearningPathRepository(firebaseReady: false),
      ),
    ),
  ],
  child: const TluB1DailyApp(),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Chưa đăng nhập thì vào màn Login', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.text('TLU B1 Daily'), findsOneWidget);
  });

  testWidgets('Vào app rồi chuyển qua 5 tab', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('M5 - Thói quen và thống kê tiến độ'), findsOneWidget);

    await tester.tap(find.text('Tài liệu'));
    await tester.pumpAndSettle();
    expect(find.text('M2 - Tài liệu tiếng Anh B1'), findsOneWidget);

    await tester.tap(find.text('Luyện tập'));
    await tester.pumpAndSettle();
    expect(find.text('M3 - Bài tập và đánh giá'), findsOneWidget);

    await tester.tap(find.text('Lộ trình'));
    await tester.pumpAndSettle();
    expect(find.text('Lộ trình học tập'), findsOneWidget);

    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();
    expect(find.text('M1 - Nền tảng và tài khoản'), findsOneWidget);
  });

  testWidgets('Luồng M4 đầy đủ qua GoRouter: Khảo sát -> Lộ trình -> Tour tiếng Anh', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lộ trình'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có lộ trình B1 cá nhân'), findsOneWidget);

    await tester.tap(find.text('Bắt đầu khảo sát tạo lộ trình'));
    await tester.pumpAndSettle();
    expect(find.text('Khảo sát đầu vào B1'), findsOneWidget);

    final skipBtn = find.text('Bỏ qua & tạo lộ trình nền tảng');
    await tester.scrollUntilVisible(
      skipBtn,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(skipBtn);
    await tester.pumpAndSettle();

    expect(find.text('Tiến độ tổng thể: 0%'), findsOneWidget);

    await tester.tap(find.textContaining('Tour dẫn tiếng Anh'));
    await tester.pumpAndSettle();
    expect(find.text('Tour dẫn tiếng Anh & CLB'), findsOneWidget);
  });
}
