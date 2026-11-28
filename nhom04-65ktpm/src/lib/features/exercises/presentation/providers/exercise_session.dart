import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../assessment/data/models/exercise_attempt.dart';
import '../../../assessment/domain/scoring.dart';
import '../../data/models/exam_models.dart';
import '../../data/models/exercise.dart';

enum SessionPhase { intro, inProgress, selfAssess, finished }

/// Một trang trong bài làm: một nhóm câu hỏi (Nghe/Đọc) hoặc một đề Viết/Nói.
class SessionStep {
  const SessionStep.group(this.section, QuestionGroup this.group) : task = null;
  const SessionStep.task(this.section, ProductiveTask this.task) : group = null;

  final ExamSection section;
  final QuestionGroup? group;
  final ProductiveTask? task;
}

typedef Clock = DateTime Function();

/// Trạng thái một lần làm bài: đáp án, đồng hồ đếm ngược, tự đánh giá và nộp bài.
class ExerciseSession extends ChangeNotifier {
  ExerciseSession(this.exercise, {Clock? clock})
    : _clock = clock ?? DateTime.now,
      steps = [
        for (final section in exercise.sections) ...[
          for (final group in section.groups) SessionStep.group(section, group),
          for (final task in section.tasks) SessionStep.task(section, task),
        ],
      ];

  final Exercise exercise;
  final List<SessionStep> steps;
  final Clock _clock;

  SessionPhase _phase = SessionPhase.intro;
  int _stepIndex = 0;
  int _remainingSeconds = 0;
  bool _timedOut = false;
  DateTime? _startedAt;
  DateTime? _workEndedAt;
  Timer? _timer;
  ExerciseAttempt? _attempt;

  final Map<String, int> _answers = {};
  final Map<String, String> _responses = {};
  final Map<String, Map<String, int>> _rubric = {};

  SessionPhase get phase => _phase;
  int get stepIndex => _stepIndex;
  SessionStep get currentStep => steps[_stepIndex];
  bool get isFirstStep => _stepIndex == 0;
  bool get isLastStep => _stepIndex == steps.length - 1;
  int get remainingSeconds => _remainingSeconds;
  bool get timedOut => _timedOut;
  ExerciseAttempt? get attempt => _attempt;
  Map<String, int> get answers => Map.unmodifiable(_answers);

  int get totalSeconds => exercise.durationMinutes * 60;
  int get questionCount => exercise.questionCount;
  int get answeredCount => exercise.sections
      .expand((s) => s.questions)
      .where((q) => _answers.containsKey(q.id))
      .length;

  List<ProductiveTask> get productiveTasks => [
    for (final section in exercise.sections) ...section.tasks,
  ];

  ExamSkill skillOfTask(ProductiveTask task) => exercise.sections
      .firstWhere((s) => s.tasks.any((t) => t.id == task.id))
      .skill;

  int? answerOf(String questionId) => _answers[questionId];
  String responseOf(String taskId) => _responses[taskId] ?? '';
  int? rubricOf(String taskId, String criterionId) =>
      _rubric[taskId]?[criterionId];

  void start() {
    if (_phase != SessionPhase.intro) return;
    _phase = SessionPhase.inProgress;
    _startedAt = _clock();
    _remainingSeconds = totalSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void _tick() {
    if (_phase != SessionPhase.inProgress) return;
    _remainingSeconds--;
    if (_remainingSeconds <= 0) {
      _remainingSeconds = 0;
      _timedOut = true;
      finishWork();
      return;
    }
    notifyListeners();
  }

  void selectAnswer(String questionId, int optionIndex) {
    if (_phase != SessionPhase.inProgress) return;
    _answers[questionId] = optionIndex;
    notifyListeners();
  }

  void updateResponse(String taskId, String text) {
    if (_phase != SessionPhase.inProgress) return;
    _responses[taskId] = text;
  }

  void goTo(int index) {
    if (index < 0 || index >= steps.length) return;
    _stepIndex = index;
    notifyListeners();
  }

  void next() => goTo(_stepIndex + 1);
  void previous() => goTo(_stepIndex - 1);

  /// Kết thúc phần làm bài (bấm nộp hoặc hết giờ). Có Viết/Nói thì sang bước tự đánh giá.
  void finishWork() {
    if (_phase != SessionPhase.inProgress) return;
    _timer?.cancel();
    _workEndedAt = _clock();
    if (productiveTasks.isEmpty) {
      _complete();
    } else {
      _phase = SessionPhase.selfAssess;
      notifyListeners();
    }
  }

  void rate(String taskId, String criterionId, int points) {
    if (_phase != SessionPhase.selfAssess) return;
    (_rubric[taskId] ??= {})[criterionId] = points;
    notifyListeners();
  }

  /// Hoàn tất tự đánh giá và chốt kết quả.
  void submitSelfAssessment() {
    if (_phase != SessionPhase.selfAssess) return;
    _complete();
  }

  void _complete() {
    final started = _startedAt ?? _clock();
    _attempt = ExerciseAttempt(
      id: '${exercise.id}_${started.millisecondsSinceEpoch}',
      exerciseId: exercise.id,
      setId: exercise.examSet.id,
      isMock: exercise.isMock,
      startedAt: started,
      completedAt: _workEndedAt ?? _clock(),
      skillResults: Scoring.gradeSections(
        exercise.sections,
        answers: _answers,
        rubric: _rubric,
      ),
      answers: Map.of(_answers),
      responses: {
        for (final entry in _responses.entries)
          if (entry.value.trim().isNotEmpty) entry.key: entry.value.trim(),
      },
      rubric: {
        for (final entry in _rubric.entries) entry.key: Map.of(entry.value),
      },
      timedOut: _timedOut,
    );
    _phase = SessionPhase.finished;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
