import 'package:flutter_test/flutter_test.dart';
import 'package:tlu_b1_daily/features/exercises/data/models/exam_models.dart';

void main() {
  final json = {
    'id': 'set_01',
    'title': 'Đề mẫu số 1',
    'topic': 'Học tập',
    'description': 'Mô tả',
    'sections': [
      {
        'id': 'ex_listen_01',
        'skill': 'listening',
        'title': 'Listening',
        'instructionsVi': 'Nghe và chọn đáp án.',
        'durationMinutes': 20,
        'groups': [
          {
            'id': 'set_01_l1',
            'title': 'Part 1',
            'audio': 'assets/audio/m3/set_01_l1.m4a',
            'transcript': [
              {'speaker': 'W', 'text': 'Hi.'},
            ],
            'questions': [
              {
                'id': 'set_01_l01',
                'prompt': 'What time?',
                'options': ['6', '7', '8', '9'],
                'answerIndex': 2,
                'explanationVi': 'Giải thích',
              },
            ],
          },
        ],
      },
      {
        'id': 'ex_write_01',
        'skill': 'writing',
        'title': 'Writing',
        'instructionsVi': 'Viết email.',
        'durationMinutes': 40,
        'tasks': [
          {
            'id': 'set_01_w1',
            'title': 'Task 1',
            'prompt': 'Write an email.',
            'minWords': 80,
            'maxWords': 100,
            'tipsVi': ['Mở đầu lịch sự'],
            'sampleAnswer': 'Dear Tom, ...',
          },
        ],
      },
    ],
  };

  test('đọc bộ đề từ JSON', () {
    final set = ExamSet.fromJson(json);
    expect(set.sections.length, 2);
    final listening = set.sectionOf(ExamSkill.listening)!;
    expect(listening.questions.single.answerIndex, 2);
    expect(listening.groups.single.transcript.single.speaker, 'W');
    expect(set.sectionOf(ExamSkill.writing)!.tasks.single.minWords, 80);
    expect(set.sectionOf(ExamSkill.speaking), isNull);
    expect(set.questionCount, 1);
  });

  test('toJson rồi fromJson giữ nguyên nội dung', () {
    final copy = ExamSet.fromJson(ExamSet.fromJson(json).toJson());
    expect(copy.toJson(), ExamSet.fromJson(json).toJson());
  });

  test('chấm một câu và nhãn phương án', () {
    final q = ExamSet.fromJson(json).sections.first.questions.single;
    expect(q.isCorrect(2), isTrue);
    expect(q.isCorrect(1), isFalse);
    expect(q.isCorrect(null), isFalse);
    expect(Question.optionLabel(0), 'A');
    expect(Question.optionLabel(3), 'D');
  });

  test('khóa kỹ năng trùng với M4 và kỹ năng chấm tự động', () {
    expect(ExamSkill.values.map((s) => s.key), [
      'listening',
      'reading',
      'writing',
      'speaking',
    ]);
    expect(ExamSkill.listening.isAutoGraded, isTrue);
    expect(ExamSkill.writing.isAutoGraded, isFalse);
    expect(ExamSkill.fromKey('speaking'), ExamSkill.speaking);
    expect(ExamSkill.speaking.labelVi, 'Nói');
  });
}
