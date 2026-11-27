import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit_model.dart';
import '../models/study_session_model.dart';

class HabitRepository {
  static const String _habitsKey = 'm5_habits';
  static const String _sessionsKey = 'm5_study_sessions';

  Future<List<HabitModel>> getHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_habitsKey);

    if (data == null) return [];

    final List<dynamic> decoded = jsonDecode(data);

    return decoded
        .map((item) => HabitModel.fromMap(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<void> saveHabit(HabitModel habit) async {
    final habits = await getHabits();

    habits.removeWhere((item) => item.id == habit.id);
    habits.add(habit);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _habitsKey,
      jsonEncode(habits.map((item) => item.toMap()).toList()),
    );
  }

  Future<List<StudySessionModel>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_sessionsKey);

    if (data == null) return [];

    final List<dynamic> decoded = jsonDecode(data);

    return decoded
        .map((item) => StudySessionModel.fromMap(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<void> saveSession(StudySessionModel session) async {
    final sessions = await getSessions();

    sessions.add(session);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _sessionsKey,
      jsonEncode(sessions.map((item) => item.toMap()).toList()),
    );
  }
}