import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../assessment/presentation/providers/attempt_history_provider.dart';
import '../../../assessment/presentation/screens/attempt_review_screen.dart';
import '../../../assessment/presentation/widgets/skill_stats_panel.dart';
import '../../data/models/exam_models.dart';
import '../../data/models/exercise.dart';
import '../../domain/exercise_catalog.dart';
import '../providers/exercises_provider.dart';

/// M3 - Luyện tập theo kỹ năng và thi thử tổng hợp.
class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this);
  ExamSkill _skill = ExamSkill.listening;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ExercisesProvider>().load(),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _practice(ExamSkill skill) {
    setState(() => _skill = skill);
    _tabs.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExercisesProvider>();
    final catalog = provider.catalog;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Luyện tập'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Theo kỹ năng'),
            Tab(text: 'Thi thử'),
            Tab(text: 'Kết quả'),
          ],
        ),
      ),
      body: catalog == null
          ? provider.error != null
                ? ErrorView(
                    message: provider.error!,
                    onRetry: () => provider.load(force: true),
                  )
                : const LoadingView()
          : TabBarView(
              controller: _tabs,
              children: [
                _SkillPracticeTab(
                  catalog: catalog,
                  skill: _skill,
                  onSkillChanged: (s) => setState(() => _skill = s),
                ),
                _MockTestTab(catalog: catalog),
                _ResultsTab(catalog: catalog, onPractice: _practice),
              ],
            ),
    );
  }
}

class _SkillPracticeTab extends StatelessWidget {
  const _SkillPracticeTab({
    required this.catalog,
    required this.skill,
    required this.onSkillChanged,
  });

  final ExerciseCatalog catalog;
  final ExamSkill skill;
  final ValueChanged<ExamSkill> onSkillChanged;

  @override
  Widget build(BuildContext context) {
    final exercises = catalog.practiceFor(skill);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<ExamSkill>(
          segments: [
            for (final s in ExamSkill.values)
              ButtonSegment(value: s, label: Text(s.labelVi)),
          ],
          selected: {skill},
          showSelectedIcon: false,
          onSelectionChanged: (set) => onSkillChanged(set.first),
        ),
        const SizedBox(height: 8),
        Text(
          skill.isAutoGraded
              ? 'Chấm điểm tự động, có đáp án và giải thích tiếng Việt.'
              : 'Làm bài, đối chiếu bài mẫu và tự chấm theo rubric B1.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        for (final exercise in exercises) _ExerciseTile(exercise: exercise),
      ],
    );
  }
}

class _MockTestTab extends StatelessWidget {
  const _MockTestTab({required this.catalog});

  final ExerciseCatalog catalog;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Đề tổng hợp đủ 4 kỹ năng, một đồng hồ đếm ngược cho cả bài. '
          'Ngân hàng hiện có ${catalog.sets.length} đề, ${catalog.questionCount} câu trắc nghiệm.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        for (final exercise in catalog.mockTests)
          _ExerciseTile(exercise: exercise),
      ],
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final best = context.watch<AttemptHistoryProvider>().bestScoreFor(
      exercise.id,
    );
    final details = [
      '${exercise.durationMinutes} phút',
      if (exercise.questionCount > 0) '${exercise.questionCount} câu',
      if (exercise.taskCount > 0) '${exercise.taskCount} đề Viết/Nói',
    ].join(' · ');
    return Card(
      child: ListTile(
        title: Text(exercise.isMock ? exercise.title : exercise.examSet.title),
        subtitle: Text('${exercise.examSet.topic}\n$details'),
        isThreeLine: true,
        trailing: best == null
            ? const Icon(Icons.chevron_right)
            : Chip(label: Text('$best%')),
        onTap: () => context.push(AppRoutes.exerciseDetail(exercise.id)),
      ),
    );
  }
}

class _ResultsTab extends StatelessWidget {
  const _ResultsTab({required this.catalog, required this.onPractice});

  final ExerciseCatalog catalog;
  final ValueChanged<ExamSkill> onPractice;

  @override
  Widget build(BuildContext context) {
    final history = context.watch<AttemptHistoryProvider>();
    final attempts = history.attempts;
    final format = DateFormat('HH:mm dd/MM');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SkillStatsPanel(summary: history.summary, onPractice: onPractice),
        const SizedBox(height: 16),
        Text(
          'Lịch sử làm bài (${attempts.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (attempts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Chưa có bài nào. Làm một bài luyện tập để xem thống kê.',
              textAlign: TextAlign.center,
            ),
          ),
        for (final attempt in attempts)
          if (catalog.byId(attempt.exerciseId) case final exercise?)
            Card(
              child: ListTile(
                title: Text(exercise.title),
                subtitle: Text(
                  '${format.format(attempt.completedAt.toLocal())} · '
                  '${attempt.durationMinutes} phút',
                ),
                trailing: Text(
                  '${attempt.scorePercent}%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AttemptReviewScreen(
                      exercise: exercise,
                      attempt: attempt,
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
