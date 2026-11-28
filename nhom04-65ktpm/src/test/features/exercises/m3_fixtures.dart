import 'dart:convert';

import 'package:tlu_b1_daily/features/exercises/data/models/exam_models.dart';
import 'package:tlu_b1_daily/features/exercises/data/repositories/question_bank_repository.dart';

Question _q(String id, int answer) => Question(
  id: id,
  prompt: 'Prompt $id',
  options: const ['opt A', 'opt B', 'opt C', 'opt D'],
  answerIndex: answer,
  explanationVi: 'Giải thích $id',
);

/// Bộ đề nhỏ để test: Nghe 2 câu, Đọc 2 câu, Viết 1 đề, Nói 1 đề.
ExamSet fixtureSet(int n) {
  final id = n.toString().padLeft(2, '0');
  return ExamSet(
    id: 'set_$id',
    title: 'Đề mẫu số $n',
    topic: 'Chủ đề $n',
    description: 'Mô tả $n',
    sections: [
      ExamSection(
        id: 'ex_listen_$id',
        skill: ExamSkill.listening,
        title: 'Listening',
        instructionsVi: 'Nghe và chọn đáp án.',
        durationMinutes: 1,
        groups: [
          QuestionGroup(
            id: 'set_${id}_l1',
            title: 'Part 1',
            audio: 'assets/audio/m3/set_${id}_l1.m4a',
            transcript: const [TranscriptLine(speaker: 'W', text: 'Hello.')],
            questions: [_q('set_${id}_l01', 1), _q('set_${id}_l02', 2)],
          ),
        ],
      ),
      ExamSection(
        id: 'ex_read_$id',
        skill: ExamSkill.reading,
        title: 'Reading',
        instructionsVi: 'Đọc và chọn đáp án.',
        durationMinutes: 1,
        groups: [
          QuestionGroup(
            id: 'set_${id}_r1',
            title: 'Part 1',
            passage: 'A short notice.',
            questions: [_q('set_${id}_r01', 0), _q('set_${id}_r02', 3)],
          ),
        ],
      ),
      ExamSection(
        id: 'ex_write_$id',
        skill: ExamSkill.writing,
        title: 'Writing',
        instructionsVi: 'Viết email.',
        durationMinutes: 1,
        tasks: [
          ProductiveTask(
            id: 'set_${id}_w1',
            title: 'Task 1 – Email',
            prompt: 'Write an email.',
            sampleAnswer: 'Dear Tom, ...',
            minWords: 5,
            maxWords: 10,
          ),
        ],
      ),
      ExamSection(
        id: 'ex_speak_$id',
        skill: ExamSkill.speaking,
        title: 'Speaking',
        instructionsVi: 'Trả lời câu hỏi.',
        durationMinutes: 1,
        tasks: [
          ProductiveTask(
            id: 'set_${id}_s1',
            title: 'Part 1',
            prompt: 'Talk about your hobby.',
            sampleAnswer: 'I like reading.',
            prepSeconds: 0,
            speakSeconds: 30,
          ),
        ],
      ),
    ],
  );
}

QuestionBankRepository fixtureRepository() => QuestionBankRepository(
  loader: (path) async {
    final n = QuestionBankRepository.setAssets.indexOf(path) + 1;
    return jsonEncode(fixtureSet(n).toJson());
  },
);
