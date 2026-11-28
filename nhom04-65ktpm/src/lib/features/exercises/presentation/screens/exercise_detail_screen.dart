import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../assessment/domain/rubrics.dart';
import '../../../assessment/presentation/providers/attempt_history_provider.dart';
import '../../../assessment/presentation/widgets/attempt_result_view.dart';
import '../../../assessment/presentation/widgets/rubric_checklist.dart';
import '../../data/models/exam_models.dart';
import '../../data/models/exercise.dart';
import '../providers/exercise_session.dart';
import '../providers/exercises_provider.dart';
import '../widgets/audio_player_bar.dart';
import '../widgets/productive_task_view.dart';
import '../widgets/question_card.dart';

/// M3 - Làm bài. M4 mở màn này qua `AppRoutes.exerciseDetail(id)`.
class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ExercisesProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExercisesProvider>();
    final catalog = provider.catalog;
    if (catalog == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bài tập')),
        body: provider.error != null
            ? ErrorView(
                message: provider.error!,
                onRetry: () => provider.load(force: true),
              )
            : const LoadingView(),
      );
    }
    final exercise = catalog.byId(widget.exerciseId);
    if (exercise == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bài tập')),
        body: ErrorView(
          message: 'Không tìm thấy bài tập ${widget.exerciseId}.',
        ),
      );
    }
    return _ExerciseRunner(key: ValueKey(exercise.id), exercise: exercise);
  }
}

class _ExerciseRunner extends StatefulWidget {
  const _ExerciseRunner({super.key, required this.exercise});

  final Exercise exercise;

  @override
  State<_ExerciseRunner> createState() => _ExerciseRunnerState();
}

class _ExerciseRunnerState extends State<_ExerciseRunner> {
  late ExerciseSession _session;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _session = _newSession();
  }

  ExerciseSession _newSession() =>
      ExerciseSession(widget.exercise)..addListener(_onSessionChanged);

  void _onSessionChanged() {
    final attempt = _session.attempt;
    if (_session.phase == SessionPhase.finished && attempt != null && !_saved) {
      _saved = true;
      context.read<AttemptHistoryProvider>().add(attempt);
    }
  }

  void _restart() {
    setState(() {
      _session
        ..removeListener(_onSessionChanged)
        ..dispose();
      _saved = false;
      _session = _newSession();
    });
  }

  @override
  void dispose() {
    _session
      ..removeListener(_onSessionChanged)
      ..dispose();
    super.dispose();
  }

  Future<bool> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thoát bài làm?'),
        content: const Text('Bài làm chưa nộp sẽ không được lưu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Làm tiếp'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _session,
      child: Consumer<ExerciseSession>(
        builder: (context, session, _) {
          final busy =
              session.phase == SessionPhase.inProgress ||
              session.phase == SessionPhase.selfAssess;
          return PopScope(
            canPop: !busy,
            onPopInvokedWithResult: (didPop, _) async {
              if (didPop) return;
              final navigator = Navigator.of(context);
              if (await _confirmLeave() && mounted) navigator.pop();
            },
            child: switch (session.phase) {
              SessionPhase.intro => _IntroView(session: session),
              SessionPhase.inProgress => _WorkView(session: session),
              SessionPhase.selfAssess => _SelfAssessView(session: session),
              SessionPhase.finished => Scaffold(
                appBar: AppBar(title: const Text('Kết quả')),
                body: AttemptResultView(
                  exercise: session.exercise,
                  attempt: session.attempt!,
                  actions: [
                    FilledButton.icon(
                      onPressed: _restart,
                      icon: const Icon(Icons.replay),
                      label: const Text('Làm lại'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go(AppRoutes.exercises),
                      icon: const Icon(Icons.list),
                      label: const Text('Danh sách bài'),
                    ),
                  ],
                ),
              ),
            },
          );
        },
      ),
    );
  }
}

class _IntroView extends StatelessWidget {
  const _IntroView({required this.session});

  final ExerciseSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercise = session.exercise;
    final best = context.watch<AttemptHistoryProvider>().bestScoreFor(
      exercise.id,
    );
    return Scaffold(
      appBar: AppBar(title: Text(exercise.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(exercise.examSet.topic, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(exercise.examSet.description),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.timer_outlined, size: 18),
                label: Text('${exercise.durationMinutes} phút'),
              ),
              if (exercise.questionCount > 0)
                Chip(
                  avatar: const Icon(Icons.quiz_outlined, size: 18),
                  label: Text('${exercise.questionCount} câu trắc nghiệm'),
                ),
              if (exercise.taskCount > 0)
                Chip(
                  avatar: const Icon(Icons.edit_outlined, size: 18),
                  label: Text('${exercise.taskCount} đề Viết/Nói'),
                ),
              if (best != null)
                Chip(
                  avatar: const Icon(Icons.emoji_events_outlined, size: 18),
                  label: Text('Tốt nhất $best%'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          for (final section in exercise.sections)
            Card(
              child: ListTile(
                title: Text(
                  '${section.skill.labelVi} · ${section.durationMinutes} phút',
                ),
                subtitle: Text(section.instructionsVi),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Đồng hồ đếm ngược bắt đầu khi bấm "Bắt đầu" và tự nộp bài khi hết giờ.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: session.start,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Bắt đầu'),
          ),
        ],
      ),
    );
  }
}

class _WorkView extends StatelessWidget {
  const _WorkView({required this.session});

  final ExerciseSession session;

  Future<void> _submit(BuildContext context) async {
    final missing = session.questionCount - session.answeredCount;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nộp bài?'),
        content: Text(
          missing > 0
              ? 'Bạn còn $missing câu chưa trả lời. Câu bỏ trống tính sai.'
              : 'Bạn đã trả lời tất cả câu hỏi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Làm tiếp'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Nộp bài'),
          ),
        ],
      ),
    );
    if (ok ?? false) session.finishWork();
  }

  @override
  Widget build(BuildContext context) {
    final step = session.currentStep;
    return Scaffold(
      appBar: AppBar(
        title: Text(step.section.title),
        actions: [
          _CountdownChip(seconds: session.remainingSeconds),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: _StepStrip(session: session),
        ),
      ),
      body: step.group != null
          ? _GroupView(
              key: ValueKey(step.group!.id),
              session: session,
              section: step.section,
              group: step.group!,
            )
          : ProductiveTaskView(
              key: ValueKey(step.task!.id),
              skill: step.section.skill,
              task: step.task!,
              initialText: session.responseOf(step.task!.id),
              onChanged: (text) => session.updateResponse(step.task!.id, text),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: session.isFirstStep ? null : session.previous,
                child: const Text('Trước'),
              ),
              const Spacer(),
              Text('${session.stepIndex + 1}/${session.steps.length}'),
              const Spacer(),
              if (session.isLastStep)
                FilledButton(
                  onPressed: () => _submit(context),
                  child: const Text('Nộp bài'),
                )
              else
                FilledButton(
                  onPressed: session.next,
                  child: const Text('Tiếp'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountdownChip extends StatelessWidget {
  const _CountdownChip({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final urgent = seconds <= 60;
    return Chip(
      key: const ValueKey('countdown'),
      avatar: Icon(
        Icons.timer_outlined,
        size: 18,
        color: urgent ? scheme.onError : null,
      ),
      backgroundColor: urgent ? scheme.error : null,
      label: Text(
        formatClock(Duration(seconds: seconds)),
        style: TextStyle(
          color: urgent ? scheme.onError : null,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Dải số trang để nhảy nhanh; trang đã làm xong được tô màu.
class _StepStrip extends StatelessWidget {
  const _StepStrip({required this.session});

  final ExerciseSession session;

  bool _done(SessionStep step) {
    final group = step.group;
    if (group != null) {
      return group.questions.every((q) => session.answerOf(q.id) != null);
    }
    return session.responseOf(step.task!.id).trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: session.steps.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final current = i == session.stepIndex;
          final done = _done(session.steps[i]);
          return InkWell(
            onTap: () => session.goTo(i),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? scheme.primaryContainer : null,
                border: Border.all(
                  color: current ? scheme.primary : scheme.outlineVariant,
                  width: current ? 2 : 1,
                ),
              ),
              child: Text('${i + 1}'),
            ),
          );
        },
      ),
    );
  }
}

class _GroupView extends StatelessWidget {
  const _GroupView({
    super.key,
    required this.session,
    required this.section,
    required this.group,
  });

  final ExerciseSession session;
  final ExamSection section;
  final QuestionGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final questions = section.questions;
    final audio = group.audio;
    final passage = group.passage;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(group.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (audio != null) ...[
          AudioPlayerBar(key: ValueKey(audio), assetPath: audio),
          const SizedBox(height: 12),
        ],
        if (passage != null) ...[
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(passage, style: theme.textTheme.bodyLarge),
            ),
          ),
          const SizedBox(height: 12),
        ],
        for (final question in group.questions)
          QuestionCard(
            number: questions.indexOf(question) + 1,
            question: question,
            selected: session.answerOf(question.id),
            onSelect: (i) => session.selectAnswer(question.id, i),
          ),
      ],
    );
  }
}

class _SelfAssessView extends StatelessWidget {
  const _SelfAssessView({required this.session});

  final ExerciseSession session;

  bool get _allRated => session.productiveTasks.every((task) {
    final criteria = B1Rubrics.forSkill(session.skillOfTask(task));
    return criteria.every((c) => session.rubricOf(task.id, c.id) != null);
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tự đánh giá Viết/Nói')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Đọc bài mẫu, so với bài của bạn rồi chấm từng tiêu chí (0–3). '
            'Nghe/Đọc đã được chấm tự động.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (final task in session.productiveTasks)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text('Bài của bạn', style: theme.textTheme.labelLarge),
                    Text(
                      session.responseOf(task.id).trim().isEmpty
                          ? '(Không có)'
                          : session.responseOf(task.id).trim(),
                    ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Bài mẫu đối chiếu'),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [SelectableText(task.sampleAnswer)],
                    ),
                    RubricChecklist(
                      criteria: B1Rubrics.forSkill(session.skillOfTask(task)),
                      valueOf: (id) => session.rubricOf(task.id, id),
                      onChanged: (id, points) =>
                          session.rate(task.id, id, points),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _allRated ? session.submitSelfAssessment : null,
            child: Text(_allRated ? 'Xem kết quả' : 'Chấm đủ các tiêu chí'),
          ),
        ),
      ),
    );
  }
}
