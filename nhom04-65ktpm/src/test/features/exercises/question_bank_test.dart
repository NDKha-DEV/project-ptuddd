import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_b1_daily/features/exercises/data/models/exam_models.dart';
import 'package:tlu_b1_daily/features/exercises/data/repositories/question_bank_repository.dart';
import 'package:tlu_b1_daily/features/exercises/domain/exercise_catalog.dart';

/// Kiểm tra ngân hàng đề thật trong assets/data/m3 (tiêu chí nghiệm thu Issue #3).
void main() {
  late List<ExamSet> sets;

  setUpAll(() async {
    sets = await QuestionBankRepository(
      loader: (path) => File(path).readAsString(),
    ).loadSets();
  });

  test('có ít nhất 5 bộ đề và 100 câu hỏi chấm tự động', () {
    expect(sets.length, greaterThanOrEqualTo(5));
    expect(ExerciseCatalog(sets).questionCount, greaterThanOrEqualTo(100));
  });

  test('mỗi bộ đề đủ 4 kỹ năng theo đúng mã bài tập', () {
    for (final set in sets) {
      final n = set.id.replaceFirst('set_', '');
      expect(set.sectionOf(ExamSkill.listening)?.id, 'ex_listen_$n');
      expect(set.sectionOf(ExamSkill.reading)?.id, 'ex_read_$n');
      expect(set.sectionOf(ExamSkill.writing)?.tasks, isNotEmpty);
      expect(set.sectionOf(ExamSkill.speaking)?.tasks, isNotEmpty);
    }
  });

  test('mã bài tập mẫu của M4 mở được', () {
    final catalog = ExerciseCatalog(sets);
    for (final id in [
      'ex_listen_01',
      'ex_read_01',
      'ex_write_01',
      'ex_speak_01',
    ]) {
      expect(catalog.byId(id), isNotNull, reason: id);
    }
  });

  test('câu hỏi hợp lệ: id duy nhất, 4 phương án, có đáp án và giải thích', () {
    final ids = <String>{};
    for (final set in sets) {
      for (final section in set.sections) {
        for (final question in section.questions) {
          expect(ids.add(question.id), isTrue, reason: 'trùng ${question.id}');
          expect(question.options.length, 4, reason: question.id);
          expect(question.answerIndex, inInclusiveRange(0, 3));
          expect(question.prompt.trim(), isNotEmpty, reason: question.id);
          expect(
            question.explanationVi.trim(),
            isNotEmpty,
            reason: question.id,
          );
          expect(question.options.toSet().length, 4, reason: question.id);
        }
      }
    }
  });

  test('mỗi nhóm câu Nghe có transcript và file audio tồn tại', () {
    for (final set in sets) {
      for (final group in set.sectionOf(ExamSkill.listening)!.groups) {
        expect(group.transcript, isNotEmpty, reason: group.id);
        expect(group.audio, isNotNull, reason: group.id);
        expect(File(group.audio!).existsSync(), isTrue, reason: group.audio);
      }
    }
  });

  test('đề Viết/Nói có bài mẫu đối chiếu', () {
    for (final set in sets) {
      for (final skill in [ExamSkill.writing, ExamSkill.speaking]) {
        for (final task in set.sectionOf(skill)!.tasks) {
          expect(task.sampleAnswer.trim(), isNotEmpty, reason: task.id);
        }
      }
    }
  });
}
