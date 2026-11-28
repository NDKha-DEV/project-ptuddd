import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_b1_daily/features/exercises/data/repositories/question_bank_repository.dart';

import 'm3_fixtures.dart';

void main() {
  test('đọc lần lượt 5 file bộ đề theo thứ tự', () async {
    final sets = await fixtureRepository().loadSets();
    expect(sets.map((s) => s.id), [
      'set_01',
      'set_02',
      'set_03',
      'set_04',
      'set_05',
    ]);
  });

  test('file lỗi JSON thì ném lỗi để màn hình báo thử lại', () async {
    final repo = QuestionBankRepository(loader: (_) async => '{not json');
    expect(repo.loadSets(), throwsFormatException);
  });
}
