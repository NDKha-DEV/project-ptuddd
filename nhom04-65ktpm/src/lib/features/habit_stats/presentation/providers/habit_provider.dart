import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../data/models/study_session_model.dart';
import '../../data/repositories/habit_repository.dart';

class HabitProvider extends ChangeNotifier {
  final HabitRepository _repository;

  HabitProvider(this._repository);

  Timer? _timer;

  int _remainingSeconds = 1800;
  int _selectedMinutes = 30;
  bool _isRunning = false;

  int get remainingSeconds => _remainingSeconds;
  int get selectedMinutes => _selectedMinutes;
  bool get isRunning => _isRunning;

  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  void selectDuration(int minutes) {
    if (_isRunning || minutes < 30 || minutes > 60) return;

    _selectedMinutes = minutes;
    _remainingSeconds = minutes * 60;
    notifyListeners();
  }

  void startTimer() {
    if (_isRunning) return;

    _isRunning = true;
    notifyListeners();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          notifyListeners();
        } else {
          timer.cancel();
          _isRunning = false;
          _saveCompletedSession();
        }
      },
    );
  }

  void pauseTimer() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    _isRunning = false;
    _remainingSeconds = _selectedMinutes * 60;
    notifyListeners();
  }

  Future<void> _saveCompletedSession() async {
    await _repository.saveSession(
      StudySessionModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        startedAt: DateTime.now().subtract(
          Duration(minutes: _selectedMinutes),
        ),
        durationMinutes: _selectedMinutes,
        isCompleted: true,
      ),
    );

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}