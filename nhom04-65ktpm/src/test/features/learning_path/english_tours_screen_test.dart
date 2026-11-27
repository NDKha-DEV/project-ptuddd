import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlu_b1_daily/features/learning_path/data/repositories/learning_path_repository.dart';
import 'package:tlu_b1_daily/features/learning_path/presentation/providers/learning_path_provider.dart';
import 'package:tlu_b1_daily/features/learning_path/presentation/screens/english_tours_screen.dart';
import 'package:tlu_b1_daily/features/learning_path/presentation/screens/tour_detail_screen.dart';

void main() {
  late LearningPathRepository repository;
  late LearningPathProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = LearningPathRepository(firebaseReady: false);
    provider = LearningPathProvider(
      repository: repository,
      nowProvider: () => DateTime(2026, 11, 23, 9, 0),
    );
  });

  group('EnglishToursScreen & TourDetailScreen', () {
    testWidgets('hiển thị danh sách tour, lưu quan tâm và mở chi tiết TourDetailScreen', (
      tester,
    ) async {
      await provider.loadInitialData();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: EnglishToursScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tour dẫn tiếng Anh & CLB'), findsOneWidget);
      expect(
        find.text('Hanoi Free Walking Tour – Khu phố cổ & Hồ Hoàn Kiếm'),
        findsOneWidget,
      );
      expect(find.textContaining('Đã lưu 0'), findsOneWidget);

      // Bấm lưu quan tâm tour đầu tiên
      await tester.tap(find.byIcon(Icons.bookmark_border).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Đã lưu 1'), findsOneWidget);

      // Mở chi tiết tour đầu tiên
      await tester.tap(
        find.text('Hanoi Free Walking Tour – Khu phố cổ & Hồ Hoàn Kiếm'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TourDetailScreen), findsOneWidget);
      expect(find.text('Chi tiết Tour & CLB'), findsOneWidget);
      expect(find.text('Mẫu câu giao tiếp dẫn tour gợi ý'), findsOneWidget);

      // Cuộn xuống hàng nút hành động cuối trang và đặt nhắc lịch
      final reminderBtn = find.text('Đặt nhắc lịch');
      await tester.scrollUntilVisible(
        reminderBtn,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Đã lưu quan tâm'), findsOneWidget);
      await tester.tap(reminderBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nhắc trước giờ diễn ra 1 giờ'));
      await tester.pumpAndSettle();
      expect(find.text('Nhắc lịch: Nhắc trước 1 giờ'), findsOneWidget);
    });

    testWidgets('bộ lọc Chỉ cuối tuần cập nhật trạng thái trên provider', (
      tester,
    ) async {
      await provider.loadInitialData();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: EnglishToursScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(provider.weekendToursOnly, isFalse);
      await tester.tap(find.text('Chỉ cuối tuần'));
      await tester.pumpAndSettle();
      expect(provider.weekendToursOnly, isTrue);
    });
  });
}
