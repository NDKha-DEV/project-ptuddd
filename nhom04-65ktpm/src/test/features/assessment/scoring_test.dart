import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_b1_daily/features/assessment/data/models/exercise_attempt.dart';
import 'package:tlu_b1_daily/features/assessment/domain/rubrics.dart';
import 'package:tlu_b1_daily/features/assessment/domain/scoring.dart';
import 'package:tlu_b1_daily/features/exercises/data/models/exam_models.dart';

import '../exercises/m3_fixtures.dart';

ExerciseAttempt _attempt(
  String id,
  DateTime at,
  Map<ExamSkill, (int, int)> results, {
  bool mock = false,
}) {
  return ExerciseAttempt(
    id: id,
    exerciseId: id,
    setId: 'set_01',
    isMock: mock,
    startedAt: at.subtract(const Duration(minutes: 10)),
    completedAt: at,
    skillResults: [
      for (final e in results.entries)
        SkillResult(skill: e.key, earned: e.value.$1, possible: e.value.$2),
    ],
  );
}

void main() {
  final set = fixtureSet(1);

  group('Scoring', () {
    test('chấm Nghe: đúng 1/2 câu, câu bỏ trống tính sai', () {
      final listening = set.sectionOf(ExamSkill.listening)!;
      final result = Scoring.gradeObjective(listening, {'set_01_l01': 1});
      expect(result.earned, 1);
      expect(result.possible, 2);
      expect(result.scorePercent, 50);
    });

    test('chấm Đọc: đáp án sai không được điểm', () {
      final reading = set.sectionOf(ExamSkill.reading)!;
      final result = Scoring.gradeObjective(reading, {
        'set_01_r01': 0,
        'set_01_r02': 1,
      });
      expect(result.earned, 1);
    });

    test('rubric Viết: tổng điểm theo tiêu chí, thiếu tiêu chí tính 0', () {
      final writing = set.sectionOf(ExamSkill.writing)!;
      final result = Scoring.gradeProductive(writing, {
        'set_01_w1': {'task': 3, 'organisation': 2, 'vocabulary': 1},
      });
      expect(result.possible, B1Rubrics.writing.length * 3);
      expect(result.earned, 6);
      expect(result.scorePercent, 50);
    });

    test('rubric chặn điểm vượt mức tối đa', () {
      final speaking = set.sectionOf(ExamSkill.speaking)!;
      final result = Scoring.gradeProductive(speaking, {
        'set_01_s1': {'fluency': 9},
      });
      expect(result.earned, 3);
    });

    test('đếm từ tiếng Anh', () {
      expect(Scoring.countWords("I'm fine, thanks.  See you at 7!"), 7);
      expect(Scoring.countWords('   '), 0);
    });

    test('nhận xét theo ngưỡng điểm', () {
      expect(Scoring.verdictVi(85), contains('Rất tốt'));
      expect(Scoring.verdictVi(50), contains('Đạt'));
      expect(Scoring.verdictVi(20), contains('Chưa đạt'));
    });
  });

  group('ExerciseAttempt', () {
    test('toJson/fromJson giữ nguyên dữ liệu và theo hợp đồng M4', () {
      final attempt = ExerciseAttempt(
        id: 'mock_01_1',
        exerciseId: 'mock_01',
        setId: 'set_01',
        isMock: true,
        startedAt: DateTime.utc(2026, 11, 28, 8),
        completedAt: DateTime.utc(2026, 11, 28, 8, 20, 5),
        skillResults: const [
          SkillResult(skill: ExamSkill.listening, earned: 6, possible: 8),
          SkillResult(skill: ExamSkill.writing, earned: 12, possible: 24),
        ],
        answers: const {'set_01_l01': 2},
        responses: const {'set_01_w1': 'Dear Tom'},
        rubric: const {
          'set_01_w1': {'task': 3},
        },
        timedOut: true,
      );
      final json = attempt.toJson();
      expect(json['skill'], 'mock');
      expect(json['scorePercent'], 63); // (75 + 50) / 2
      expect(json['durationMinutes'], 21);

      final copy = ExerciseAttempt.fromJson(json);
      expect(copy.isMock, isTrue);
      expect(copy.scorePercent, 63);
      expect(copy.resultOf(ExamSkill.listening)!.earned, 6);
      expect(copy.answers['set_01_l01'], 2);
      expect(copy.responses['set_01_w1'], 'Dear Tom');
      expect(copy.rubric['set_01_w1']!['task'], 3);
      expect(copy.timedOut, isTrue);
    });

    test('bài luyện kỹ năng có skill là khóa kỹ năng', () {
      final attempt = _attempt('ex_read_01', DateTime.utc(2026), {
        ExamSkill.reading: (3, 12),
      });
      expect(attempt.toJson()['skill'], 'reading');
    });
  });
}
