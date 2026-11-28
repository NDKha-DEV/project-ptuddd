import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_b1_daily/features/exercises/data/models/exam_models.dart';
import 'package:tlu_b1_daily/features/exercises/domain/exercise_catalog.dart';

import 'm3_fixtures.dart';

void main() {
  final catalog = ExerciseCatalog([fixtureSet(1), fixtureSet(2)]);

  test('mỗi phần thi là một bài luyện, id = id phần thi', () {
    final listening = catalog.byId('ex_listen_01')!;
    expect(listening.isMock, isFalse);
    expect(listening.skill, ExamSkill.listening);
    expect(listening.title, 'Nghe – Đề mẫu số 1');
    expect(listening.questionCount, 2);
    expect(listening.durationMinutes, 1);
  });

  test('mỗi bộ đề có một bài thi thử mock_<số đề> đủ 4 kỹ năng', () {
    final mock = catalog.byId('mock_02')!;
    expect(mock.isMock, isTrue);
    expect(mock.skill, isNull);
    expect(mock.skills, ExamSkill.values);
    expect(mock.durationMinutes, 4);
    expect(mock.questionCount, 4);
    expect(mock.taskCount, 2);
    expect(catalog.mockTests.map((e) => e.id), ['mock_01', 'mock_02']);
  });

  test('lọc bài luyện theo kỹ năng và đếm câu toàn ngân hàng', () {
    expect(catalog.practiceFor(ExamSkill.writing).map((e) => e.id), [
      'ex_write_01',
      'ex_write_02',
    ]);
    expect(catalog.questionCount, 8);
    expect(catalog.byId('khong_co'), isNull);
  });
}
