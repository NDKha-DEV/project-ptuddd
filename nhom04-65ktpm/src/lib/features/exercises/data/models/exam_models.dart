/// Kỹ năng trong đề B1. `key` trùng với khóa kỹ năng của M4 (`SkillType.name`).
enum ExamSkill {
  listening,
  reading,
  writing,
  speaking;

  String get key => name;

  String get labelVi {
    switch (this) {
      case ExamSkill.listening:
        return 'Nghe';
      case ExamSkill.reading:
        return 'Đọc';
      case ExamSkill.writing:
        return 'Viết';
      case ExamSkill.speaking:
        return 'Nói';
    }
  }

  /// Nghe và Đọc được chấm tự động; Viết và Nói tự đánh giá theo rubric.
  bool get isAutoGraded =>
      this == ExamSkill.listening || this == ExamSkill.reading;

  static ExamSkill fromKey(String? key) {
    return ExamSkill.values.firstWhere(
      (skill) => skill.name == key,
      orElse: () => ExamSkill.reading,
    );
  }
}

/// Một lượt lời trong transcript bài nghe. `speaker`: M (nam), W (nữ), N (người dẫn).
class TranscriptLine {
  const TranscriptLine({required this.speaker, required this.text});

  factory TranscriptLine.fromJson(Map<String, dynamic> json) {
    return TranscriptLine(
      speaker: json['speaker'] as String? ?? 'N',
      text: json['text'] as String? ?? '',
    );
  }

  final String speaker;
  final String text;

  Map<String, dynamic> toJson() => {'speaker': speaker, 'text': text};
}

/// Câu hỏi trắc nghiệm 4 phương án A/B/C/D.
class Question {
  const Question({
    required this.id,
    required this.prompt,
    required this.options,
    required this.answerIndex,
    required this.explanationVi,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      prompt: json['prompt'] as String? ?? '',
      options: List<String>.from(json['options'] as List? ?? const []),
      answerIndex: (json['answerIndex'] as num?)?.toInt() ?? 0,
      explanationVi: json['explanationVi'] as String? ?? '',
    );
  }

  final String id;
  final String prompt;
  final List<String> options;
  final int answerIndex;
  final String explanationVi;

  bool isCorrect(int? selected) => selected != null && selected == answerIndex;

  static String optionLabel(int index) => String.fromCharCode(65 + index);

  Map<String, dynamic> toJson() => {
    'id': id,
    'prompt': prompt,
    'options': options,
    'answerIndex': answerIndex,
    'explanationVi': explanationVi,
  };
}

/// Nhóm câu hỏi dùng chung một audio (Nghe) hoặc một đoạn văn (Đọc).
class QuestionGroup {
  const QuestionGroup({
    required this.id,
    required this.title,
    required this.questions,
    this.audio,
    this.transcript = const [],
    this.passage,
  });

  factory QuestionGroup.fromJson(Map<String, dynamic> json) {
    return QuestionGroup(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      audio: json['audio'] as String?,
      passage: json['passage'] as String?,
      transcript: (json['transcript'] as List? ?? const [])
          .map((e) => TranscriptLine.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      questions: (json['questions'] as List? ?? const [])
          .map((e) => Question.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  final String id;
  final String title;
  final String? audio;
  final List<TranscriptLine> transcript;
  final String? passage;
  final List<Question> questions;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'audio': audio,
    'transcript': transcript.map((e) => e.toJson()).toList(),
    'passage': passage,
    'questions': questions.map((e) => e.toJson()).toList(),
  };
}

/// Đề Viết hoặc Nói: người học tự làm rồi đối chiếu bài mẫu và rubric.
class ProductiveTask {
  const ProductiveTask({
    required this.id,
    required this.title,
    required this.prompt,
    required this.sampleAnswer,
    this.tipsVi = const [],
    this.minWords,
    this.maxWords,
    this.prepSeconds,
    this.speakSeconds,
  });

  factory ProductiveTask.fromJson(Map<String, dynamic> json) {
    return ProductiveTask(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      sampleAnswer: json['sampleAnswer'] as String? ?? '',
      tipsVi: List<String>.from(json['tipsVi'] as List? ?? const []),
      minWords: (json['minWords'] as num?)?.toInt(),
      maxWords: (json['maxWords'] as num?)?.toInt(),
      prepSeconds: (json['prepSeconds'] as num?)?.toInt(),
      speakSeconds: (json['speakSeconds'] as num?)?.toInt(),
    );
  }

  final String id;
  final String title;
  final String prompt;
  final String sampleAnswer;
  final List<String> tipsVi;
  final int? minWords;
  final int? maxWords;
  final int? prepSeconds;
  final int? speakSeconds;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'prompt': prompt,
    'sampleAnswer': sampleAnswer,
    'tipsVi': tipsVi,
    'minWords': minWords,
    'maxWords': maxWords,
    'prepSeconds': prepSeconds,
    'speakSeconds': speakSeconds,
  };
}

/// Một phần thi theo kỹ năng. `id` cũng là `exerciseId` luyện kỹ năng (ví dụ `ex_listen_01`).
class ExamSection {
  const ExamSection({
    required this.id,
    required this.skill,
    required this.title,
    required this.instructionsVi,
    required this.durationMinutes,
    this.groups = const [],
    this.tasks = const [],
  });

  factory ExamSection.fromJson(Map<String, dynamic> json) {
    return ExamSection(
      id: json['id'] as String,
      skill: ExamSkill.fromKey(json['skill'] as String?),
      title: json['title'] as String? ?? '',
      instructionsVi: json['instructionsVi'] as String? ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 20,
      groups: (json['groups'] as List? ?? const [])
          .map((e) => QuestionGroup.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      tasks: (json['tasks'] as List? ?? const [])
          .map((e) => ProductiveTask.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  final String id;
  final ExamSkill skill;
  final String title;
  final String instructionsVi;
  final int durationMinutes;
  final List<QuestionGroup> groups;
  final List<ProductiveTask> tasks;

  List<Question> get questions => [
    for (final group in groups) ...group.questions,
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'skill': skill.key,
    'title': title,
    'instructionsVi': instructionsVi,
    'durationMinutes': durationMinutes,
    'groups': groups.map((e) => e.toJson()).toList(),
    'tasks': tasks.map((e) => e.toJson()).toList(),
  };
}

/// Một bộ đề mẫu gồm 4 phần Nghe, Đọc, Viết, Nói.
class ExamSet {
  const ExamSet({
    required this.id,
    required this.title,
    required this.topic,
    required this.description,
    required this.sections,
  });

  factory ExamSet.fromJson(Map<String, dynamic> json) {
    return ExamSet(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      description: json['description'] as String? ?? '',
      sections: (json['sections'] as List? ?? const [])
          .map((e) => ExamSection.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  final String id;
  final String title;
  final String topic;
  final String description;
  final List<ExamSection> sections;

  ExamSection? sectionOf(ExamSkill skill) {
    for (final section in sections) {
      if (section.skill == skill) return section;
    }
    return null;
  }

  int get questionCount =>
      sections.fold(0, (sum, section) => sum + section.questions.length);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'topic': topic,
    'description': description,
    'sections': sections.map((e) => e.toJson()).toList(),
  };
}
