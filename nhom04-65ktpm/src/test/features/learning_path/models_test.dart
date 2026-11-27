import 'package:flutter_test/flutter_test.dart';

import 'package:tlu_b1_daily/features/learning_path/data/models/assessment_result_model.dart';
import 'package:tlu_b1_daily/features/learning_path/data/models/daily_task_model.dart';
import 'package:tlu_b1_daily/features/learning_path/data/models/english_tour_model.dart';
import 'package:tlu_b1_daily/features/learning_path/data/models/learning_path_model.dart';
import 'package:tlu_b1_daily/features/learning_path/data/models/skill_scores.dart';

void main() {
  group('SkillScores', () {
    test('giới hạn điểm trong khoảng 0..100 và tìm kỹ năng yếu nhất', () {
      final scores = SkillScores(
        listening: -10,
        reading: 120,
        writing: 45,
        speaking: 38,
      );

      expect(scores.listening, 0);
      expect(scores.reading, 100);
      expect(scores.weakestSkill, SkillType.listening);

      final updated = scores.updateSkill(SkillType.listening, 60);
      expect(updated.listening, 60);
      expect(updated.weakestSkill, SkillType.speaking);
    });

    test('fromJson và toJson giữ nguyên dữ liệu', () {
      final original = SkillScores(
        listening: 50,
        reading: 60,
        writing: 45,
        speaking: 40,
      );

      final decoded = SkillScores.fromJson(original.toJson());
      expect(decoded, original);
    });
  });

  group('DailyTask', () {
    test('fromJson/toJson và chuyển trạng thái completed', () {
      final json = {
        'taskId': 'w1_d1_t1',
        'title': 'Từ vựng chủ đề Sinh hoạt & Học tập B1',
        'skill': 'vocabulary',
        'targetModule': 'M2',
        'targetResourceId': 'mat_vocab_01',
        'estimatedMinutes': 15,
        'status': 'pending',
      };

      final task = DailyTask.fromJson(json);
      expect(task.skill, SkillType.vocabulary);
      expect(task.targetModule, TargetModule.m2);
      expect(task.isCompleted, isFalse);

      final completedAt = DateTime.utc(2026, 11, 22, 9, 30);
      final done = task.copyWith(
        status: TaskStatus.completed,
        completedAt: completedAt,
      );
      expect(done.isCompleted, isTrue);

      final roundTrip = DailyTask.fromJson(done.toJson());
      expect(roundTrip, done);
    });
  });

  group('LearningPath', () {
    test('fromJson/toJson khớp Data Contract và recalculateCompletion chính xác', () {
      final now = DateTime.utc(2026, 11, 20, 9, 0);
      final path = LearningPath(
        startDate: '2026-11-20',
        examDate: '2027-01-15',
        dailyMinutes: 45,
        initialScores: SkillScores(
          listening: 50,
          reading: 60,
          writing: 45,
          speaking: 40,
        ),
        currentScores: SkillScores(
          listening: 55,
          reading: 62,
          writing: 45,
          speaking: 40,
        ),
        currentWeek: 1,
        totalWeeks: 1,
        completionRate: 0,
        updatedAt: now,
        savedTourIds: const ['tour_hanoi_free_walking_01'],
        weeks: [
          WeekPlan(
            weekNumber: 1,
            title: 'Tuần 1: Củng cố nền tảng Nghe – Đọc & Từ vựng cơ bản',
            phase: LearningPhase.foundation,
            days: [
              DayPlan(
                dayIndex: 1,
                date: '2026-11-20',
                focusSkill: SkillType.speaking,
                totalMinutes: 45,
                tasks: const [
                  DailyTask(
                    taskId: 'w1_d1_t1',
                    title: 'Từ vựng chủ đề Sinh hoạt & Học tập B1',
                    skill: SkillType.vocabulary,
                    targetModule: TargetModule.m2,
                    targetResourceId: 'mat_vocab_01',
                    estimatedMinutes: 15,
                    status: TaskStatus.completed,
                  ),
                  DailyTask(
                    taskId: 'w1_d1_t2',
                    title: 'Luyện Nghe Part 1 – Hội thoại ngắn',
                    skill: SkillType.listening,
                    targetModule: TargetModule.m3,
                    targetResourceId: 'ex_listen_01',
                    estimatedMinutes: 30,
                    status: TaskStatus.pending,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final recalculated = path.recalculateCompletion(now: now);
      expect(recalculated.completionRate, 0.5);
      expect(recalculated.weeks.first.completionRate, 0.5);
      expect(recalculated.weeks.first.days.first.completedMinutes, 15);

      final roundTrip = LearningPath.fromJson(recalculated.toJson());
      expect(roundTrip, recalculated);
    });
  });

  group('InitialAssessmentResult & EnglishTour', () {
    test('phân loại mức năng lực theo ngưỡng đặc tả M4', () {
      expect(SkillLevelTier.fromScore(44), SkillLevelTier.needsFoundation);
      expect(SkillLevelTier.fromScore(45), SkillLevelTier.intermediate);
      expect(SkillLevelTier.fromScore(69), SkillLevelTier.intermediate);
      expect(SkillLevelTier.fromScore(70), SkillLevelTier.good);
    });

    test('EnglishTour round-trip và nhận diện lịch cuối tuần', () {
      final tour = EnglishTour.fromJson({
        'tourId': 'tour_hanoi_free_walking_01',
        'title': 'Hanoi Free Walking Tour – Khu phố cổ & Hồ Hoàn Kiếm',
        'organizer': 'Hanoi Kids',
        'scheduleText': 'Thứ Bảy & Chủ Nhật hằng tuần, 08:30 – 11:30',
        'location': 'Tượng đài Lý Thái Tổ, Hoàn Kiếm, Hà Nội',
        'levelRecommended': 'A2–B1',
        'samplePhrases': [
          'Welcome to Hanoi! Let me introduce a bit about this historic area...',
        ],
        'sourceUrl': 'https://example.org',
        'lastVerifiedAt': '2026-11-18',
      });

      expect(tour.isWeekend, isTrue);
      expect(EnglishTour.fromJson(tour.toJson()), tour);
    });
  });
}
