import 'package:flutter/foundation.dart';

import '../../data/models/assessment_result_model.dart';
import '../../data/models/daily_task_model.dart';
import '../../data/models/english_tour_model.dart';
import '../../data/models/learning_path_model.dart';
import '../../data/models/skill_scores.dart';
import '../../data/repositories/learning_path_repository.dart';
import '../../domain/services/learning_path_generator.dart';

/// Quản lý trạng thái cho module M4 (khảo sát đầu vào, lộ trình học tập và tour tiếng Anh).
class LearningPathProvider extends ChangeNotifier {
  LearningPathProvider({
    required this._repository,
    this._generator = const LearningPathGenerator(),
    DateTime Function()? nowProvider,
    String initialUid = LearningPathRepository.defaultLocalUid,
  }) : _nowProvider = nowProvider ?? DateTime.now,
       _uid = initialUid.trim().isEmpty
           ? LearningPathRepository.defaultLocalUid
           : initialUid.trim();

  final LearningPathRepository _repository;
  final LearningPathGenerator _generator;
  final DateTime Function() _nowProvider;

  String _uid;
  bool _hasLoadedForCurrentUid = false;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  LearningPath? _activePlan;
  InitialAssessmentResult? _latestAssessment;
  List<EnglishTour> _tours = const [];
  Set<String> _savedTourIds = const {};
  List<LearningResourceRef> _materials = const [];
  List<LearningResourceRef> _exercises = const [];
  int _selectedWeekNumber = 1;
  bool _weekendToursOnly = false;

  String get uid => _uid;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  LearningPath? get activePlan => _activePlan;
  bool get hasActivePlan => _activePlan != null;
  InitialAssessmentResult? get latestAssessment => _latestAssessment;
  List<EnglishTour> get tours => _tours;
  Set<String> get savedTourIds => _savedTourIds;
  bool get weekendToursOnly => _weekendToursOnly;
  int get selectedWeekNumber => _selectedWeekNumber;

  List<EnglishTour> get filteredTours {
    if (!_weekendToursOnly) return _tours;
    return _tours.where((tour) => tour.isWeekend).toList();
  }

  bool isTourSaved(String tourId) => _savedTourIds.contains(tourId);

  List<MiniDiagnosticQuestion> get miniDiagnosticQuestions =>
      _repository.getMiniDiagnosticQuestions();

  String get todayDateKey => LearningPathGenerator.formatDate(_nowProvider());

  /// Số ngày còn lại tới kỳ thi B1 (null nếu chưa có lộ trình).
  int? get daysUntilExam {
    final plan = _activePlan;
    if (plan == null) return null;
    final exam = DateTime.tryParse(plan.examDate);
    if (exam == null) return null;
    final now = _nowProvider();
    final today = DateTime(now.year, now.month, now.day);
    final examOnly = DateTime(exam.year, exam.month, exam.day);
    final diff = examOnly.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Tuần đang được chọn để hiển thị trên màn hình Lộ trình.
  WeekPlan? get selectedWeek {
    final plan = _activePlan;
    if (plan == null || plan.weeks.isEmpty) return null;
    for (final week in plan.weeks) {
      if (week.weekNumber == _selectedWeekNumber) return week;
    }
    return plan.weeks.first;
  }

  /// Quy đổi mức tự tin (1..5) và đáp án mini-quiz (nếu có) thành điểm 4 kỹ năng 0..100.
  static SkillScores computeAssessmentScores({
    required Map<SkillType, int> confidenceLevels,
    required Map<String, int> quizAnswers,
    required List<MiniDiagnosticQuestion> questions,
    required bool skipMiniQuiz,
  }) {
    int scoreForSkill(SkillType skill) {
      final level = (confidenceLevels[skill] ?? 3).clamp(1, 5);
      final confidenceScore = level * 15 + 10; // 1->25, 2->40, 3->55, 4->70, 5->85
      if (skipMiniQuiz) return confidenceScore;

      final skillQuestions = questions.where((q) => q.skill == skill).toList();
      if (skillQuestions.isEmpty) return confidenceScore;

      final correctCount = skillQuestions
          .where((q) => q.isCorrect(quizAnswers[q.id]))
          .length;
      final quizPercent = (correctCount / skillQuestions.length) * 100.0;
      return (0.4 * confidenceScore + 0.6 * quizPercent).round().clamp(0, 100);
    }

    return SkillScores(
      listening: scoreForSkill(SkillType.listening),
      reading: scoreForSkill(SkillType.reading),
      writing: scoreForSkill(SkillType.writing),
      speaking: scoreForSkill(SkillType.speaking),
    );
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Đồng bộ `uid` từ `AuthProvider` (Supabase Auth) và tải dữ liệu tương ứng khi đổi phiên.
  Future<void> syncUid(String? nextUid) async {
    final trimmed = nextUid?.trim() ?? '';
    if (trimmed.isEmpty) {
      if (_uid == LearningPathRepository.defaultLocalUid &&
          _activePlan == null &&
          _latestAssessment == null &&
          _savedTourIds.isEmpty &&
          !_hasLoadedForCurrentUid) {
        return;
      }
      _uid = LearningPathRepository.defaultLocalUid;
      _hasLoadedForCurrentUid = false;
      _activePlan = null;
      _latestAssessment = null;
      _savedTourIds = const {};
      _selectedWeekNumber = 1;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    if (trimmed == _uid && (_hasLoadedForCurrentUid || _isLoading)) return;
    _uid = trimmed;
    _hasLoadedForCurrentUid = false;
    await loadInitialData();
  }

  /// Tải lộ trình, kết quả khảo sát, tài liệu/bài tập tham chiếu và danh sách tour.
  Future<void> loadInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        _repository.loadActivePlan(_uid),
        _repository.loadLatestAssessment(_uid),
        _repository.fetchEnglishTours(),
        _repository.loadSavedTourIds(_uid),
        _repository.fetchAvailableMaterials(),
        _repository.fetchAvailableExercises(),
      ]);

      final loadedPlan = results[0] as LearningPath?;
      final loadedAssessment = results[1] as InitialAssessmentResult?;
      final loadedTours = results[2] as List<EnglishTour>;
      final loadedSavedIds = results[3] as List<String>;
      final loadedMaterials = results[4] as List<LearningResourceRef>;
      final loadedExercises = results[5] as List<LearningResourceRef>;

      _activePlan = loadedPlan;
      _latestAssessment = loadedAssessment;
      _tours = loadedTours;
      _savedTourIds = {
        ...loadedSavedIds,
        if (loadedPlan != null) ...loadedPlan.savedTourIds,
      };
      _materials = loadedMaterials;
      _exercises = loadedExercises;
      _selectedWeekNumber = _resolveInitialWeek(loadedPlan);
      _hasLoadedForCurrentUid = true;
    } catch (e) {
      _errorMessage = 'Không thể tải dữ liệu lộ trình: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int _resolveInitialWeek(LearningPath? plan) {
    if (plan == null || plan.weeks.isEmpty) return 1;
    final today = todayDateKey;
    for (final week in plan.weeks) {
      if (week.days.any((day) => day.date == today)) {
        return week.weekNumber;
      }
    }
    return plan.currentWeek.clamp(1, plan.weeks.length);
  }

  /// Tạo mới lộ trình học tập từ kết quả khảo sát đầu vào (hoặc bỏ qua mini-quiz).
  Future<LearningPath?> createPlanFromAssessment({
    required DateTime examDate,
    required int dailyMinutes,
    required Map<SkillType, int> confidenceLevels,
    Map<String, int> quizAnswers = const {},
    bool skipMiniQuiz = false,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = _nowProvider();
      final scores = computeAssessmentScores(
        confidenceLevels: confidenceLevels,
        quizAnswers: quizAnswers,
        questions: miniDiagnosticQuestions,
        skipMiniQuiz: skipMiniQuiz,
      );

      final normalizedMinutes = LearningPathGenerator.normalizeDailyMinutes(
        dailyMinutes,
      );

      final assessment = InitialAssessmentResult(
        examDate: LearningPathGenerator.formatDate(examDate),
        dailyMinutes: normalizedMinutes,
        scores: scores,
        skippedMiniQuiz: skipMiniQuiz,
        assessedAt: now.toUtc(),
      );
      await _repository.saveAssessment(_uid, assessment);

      if (_materials.isEmpty) {
        _materials = await _repository.fetchAvailableMaterials();
      }
      if (_exercises.isEmpty) {
        _exercises = await _repository.fetchAvailableExercises();
      }

      final generated = _generator
          .generate(
            LearningPathInput(
              startDate: now,
              examDate: examDate,
              dailyMinutes: normalizedMinutes,
              skillScores: scores,
              availableMaterials: _materials,
              availableExercises: _exercises,
            ),
            now: now,
          )
          .copyWith(savedTourIds: _savedTourIds.toList());

      await _repository.saveActivePlan(_uid, generated);
      _latestAssessment = assessment;
      _activePlan = generated;
      _selectedWeekNumber = _resolveInitialWeek(generated);
      _hasLoadedForCurrentUid = true;
      return generated;
    } catch (e) {
      _errorMessage = 'Không thể tạo lộ trình: $e';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void selectWeek(int weekNumber) {
    final plan = _activePlan;
    if (plan == null || plan.weeks.isEmpty) return;
    final clamped = weekNumber.clamp(1, plan.weeks.length);
    if (_selectedWeekNumber == clamped) return;
    _selectedWeekNumber = clamped;
    notifyListeners();
  }

  /// Đánh dấu hoàn thành hoặc mở lại một nhiệm vụ trong ngày.
  Future<void> toggleTaskCompletion(
    String taskId, {
    void Function(DailyTask updatedTask, bool isCompleted)? onTaskToggled,
  }) async {
    final plan = _activePlan;
    if (plan == null) return;

    final now = _nowProvider();
    DailyTask? toggledTask;

    final updatedWeeks = plan.weeks.map((week) {
      var weekChanged = false;
      final updatedDays = week.days.map((day) {
        var dayChanged = false;
        final updatedTasks = day.tasks.map((task) {
          if (task.taskId != taskId) return task;
          dayChanged = true;
          weekChanged = true;
          final nextCompleted = !task.isCompleted;
          toggledTask = task.copyWith(
            status: nextCompleted ? TaskStatus.completed : TaskStatus.pending,
            completedAt: nextCompleted ? now.toUtc() : null,
            clearCompletedAt: !nextCompleted,
          );
          return toggledTask!;
        }).toList();

        return dayChanged ? day.copyWith(tasks: updatedTasks) : day;
      }).toList();

      return weekChanged ? week.copyWith(days: updatedDays) : week;
    }).toList();

    if (toggledTask == null) return;

    final nextActiveWeek = _findCurrentWeekNumber(updatedWeeks);
    final updatedPlan = plan
        .copyWith(currentWeek: nextActiveWeek, weeks: updatedWeeks)
        .recalculateCompletion(now: now);

    _activePlan = updatedPlan;
    notifyListeners();

    try {
      await _repository.saveActivePlan(_uid, updatedPlan);
      onTaskToggled?.call(toggledTask!, toggledTask!.isCompleted);
    } catch (e) {
      _errorMessage = 'Không thể lưu tiến độ nhiệm vụ: $e';
      notifyListeners();
    }
  }

  int _findCurrentWeekNumber(List<WeekPlan> weeks) {
    if (weeks.isEmpty) return 1;
    for (final week in weeks) {
      if (!week.isCompleted) return week.weekNumber;
    }
    return weeks.last.weekNumber;
  }

  /// Cập nhật điểm kỹ năng khi nhận kết quả bài tập từ M3 và tái cân bằng ngày chưa làm nếu cần.
  Future<void> applyExerciseAttempt({
    required SkillType skill,
    required int scorePercent,
    bool forceRebalance = false,
  }) async {
    final plan = _activePlan;
    if (plan == null) return;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedPlan = _generator.applyAttemptAndRebalance(
        currentPlan: plan,
        skill: skill,
        attemptPercent: scorePercent,
        currentDate: _nowProvider(),
        availableMaterials: _materials,
        availableExercises: _exercises,
        forceRebalance: forceRebalance,
      );
      await _repository.saveActivePlan(_uid, updatedPlan);
      _activePlan = updatedPlan;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật lộ trình từ kết quả bài tập: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Tái lập lịch phần tương lai khi người dùng đổi quỹ thời gian hoặc ngày thi.
  Future<void> rescheduleSettings({
    required int dailyMinutes,
    required DateTime examDate,
  }) async {
    final plan = _activePlan;
    if (plan == null) return;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedPlan = _generator.rescheduleOnSettingsChanged(
        currentPlan: plan,
        newDailyMinutes: dailyMinutes,
        newExamDate: examDate,
        currentDate: _nowProvider(),
        availableMaterials: _materials,
        availableExercises: _exercises,
      );
      await _repository.saveActivePlan(_uid, updatedPlan);
      _activePlan = updatedPlan;
      _selectedWeekNumber = _resolveInitialWeek(updatedPlan);
    } catch (e) {
      _errorMessage = 'Không thể điều chỉnh lộ trình: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Xóa lộ trình hiện tại để người dùng thực hiện khảo sát lại.
  Future<void> resetPlan() async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.clearActivePlan(_uid);
      _activePlan = null;
      _selectedWeekNumber = 1;
    } catch (e) {
      _errorMessage = 'Không thể đặt lại lộ trình: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Bật/tắt lưu quan tâm một tour tiếng Anh.
  Future<void> toggleSavedTour(String tourId) async {
    try {
      final updatedIds = await _repository.toggleSavedTour(_uid, tourId);
      _savedTourIds = updatedIds.toSet();
      if (_activePlan != null) {
        _activePlan = _activePlan!.copyWith(savedTourIds: updatedIds);
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể cập nhật tour đã lưu: $e';
      notifyListeners();
    }
  }

  void setWeekendToursOnly(bool value) {
    if (_weekendToursOnly == value) return;
    _weekendToursOnly = value;
    notifyListeners();
  }
}
