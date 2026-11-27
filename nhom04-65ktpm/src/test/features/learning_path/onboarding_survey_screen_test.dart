import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tlu_b1_daily/features/learning_path/data/repositories/learning_path_repository.dart';
import 'package:tlu_b1_daily/features/learning_path/presentation/providers/learning_path_provider.dart';
import 'package:tlu_b1_daily/features/learning_path/presentation/screens/onboarding_survey_screen.dart';

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

  Widget buildSubject({VoidCallback? onCompleted}) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        home: OnboardingSurveyScreen(
          initialDate: DateTime(2026, 11, 23),
          onCompleted: onCompleted,
        ),
      ),
    );
  }

  group('OnboardingSurveyScreen', () {
    testWidgets('hiển thị Bước 1 đầy đủ lựa chọn ngày thi, quỹ thời gian và 4 kỹ năng', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Khảo sát đầu vào B1'), findsOneWidget);
      expect(find.textContaining('Bước 1/2'), findsOneWidget);
      expect(find.text('30 phút/ngày'), findsOneWidget);
      expect(find.text('45 phút/ngày'), findsOneWidget);
      expect(find.text('60 phút/ngày'), findsOneWidget);
      expect(find.text('Nghe'), findsOneWidget);
      expect(find.text('Đọc'), findsOneWidget);
      expect(find.text('Viết'), findsOneWidget);
      expect(find.text('Nói'), findsOneWidget);
    });

    testWidgets('bấm Bỏ qua & tạo lộ trình nền tảng tạo lộ trình ngay với cấu hình đã chọn', (
      tester,
    ) async {
      var completedCalled = false;
      await tester.pumpWidget(
        buildSubject(onCompleted: () => completedCalled = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('4 tuần'));
      await tester.tap(find.text('60 phút/ngày'));
      await tester.pump();

      final skipButton = find.text('Bỏ qua & tạo lộ trình nền tảng');
      await tester.scrollUntilVisible(
        skipButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(skipButton);
      await tester.pumpAndSettle();

      expect(completedCalled, isTrue);
      expect(provider.hasActivePlan, isTrue);
      expect(provider.activePlan!.dailyMinutes, 60);
      expect(provider.activePlan!.totalWeeks, 4);
      expect(provider.latestAssessment!.skippedMiniQuiz, isTrue);
    });

    testWidgets('chuyển sang Bước 2, trả lời câu hỏi và tạo lộ trình hoàn chỉnh', (
      tester,
    ) async {
      var completedCalled = false;
      await tester.pumpWidget(
        buildSubject(onCompleted: () => completedCalled = true),
      );
      await tester.pumpAndSettle();

      final nextButton = find.text('Tiếp tục kiểm tra nhanh (10 câu)');
      await tester.scrollUntilVisible(
        nextButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Bước 2/2'), findsOneWidget);
      expect(find.text('Câu 1'), findsOneWidget);

      // Chọn đáp án đúng cho Câu 1 ("goes")
      await tester.ensureVisible(find.text('goes'));
      await tester.tap(find.text('goes'));
      await tester.pump();
      expect(find.textContaining('1/10 câu'), findsOneWidget);

      // Cuộn xuống cuối danh sách để bấm Tạo lộ trình của tôi
      final submitButton = find.text('Tạo lộ trình của tôi');
      await tester.scrollUntilVisible(
        submitButton,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(completedCalled, isTrue);
      expect(provider.hasActivePlan, isTrue);
      expect(provider.latestAssessment!.skippedMiniQuiz, isFalse);
    });

    testWidgets('từ Bước 2 có thể quay lại Bước 1 giữ nguyên lựa chọn', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('30 phút/ngày'));
      await tester.pump();

      final nextButton = find.text('Tiếp tục kiểm tra nhanh (10 câu)');
      await tester.scrollUntilVisible(
        nextButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      final backButton = find.text('Quay lại Bước 1');
      await tester.scrollUntilVisible(
        backButton,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Bước 1/2'), findsOneWidget);
      final chip30 = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '30 phút/ngày'),
      );
      expect(chip30.selected, isTrue);
    });
  });
}
