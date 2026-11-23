import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/models/assessment_result_model.dart';
import '../../data/models/skill_scores.dart';
import '../../domain/services/learning_path_generator.dart';
import '../providers/learning_path_provider.dart';

/// M4 - Màn hình khảo sát đầu vào B1 gồm 2 bước (có tùy chọn bỏ qua mini-quiz).
class OnboardingSurveyScreen extends StatefulWidget {
  const OnboardingSurveyScreen({
    super.key,
    this.onCompleted,
    this.initialDate,
  });

  final VoidCallback? onCompleted;
  final DateTime? initialDate;

  @override
  State<OnboardingSurveyScreen> createState() => _OnboardingSurveyScreenState();
}

class _OnboardingSurveyScreenState extends State<OnboardingSurveyScreen> {
  int _step = 0;
  late DateTime _examDate;
  int _dailyMinutes = 45;
  final Map<SkillType, int> _confidenceLevels = {
    for (final skill in SkillType.coreSkills) skill: 3,
  };
  final Map<String, int> _quizAnswers = {};

  DateTime get _today {
    final base = widget.initialDate ?? DateTime.now();
    return DateTime(base.year, base.month, base.day);
  }

  @override
  void initState() {
    super.initState();
    _examDate = _today.add(const Duration(days: 56));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final latest = context.read<LearningPathProvider>().latestAssessment;
      if (latest == null) return;
      final parsedExam = DateTime.tryParse(latest.examDate);
      setState(() {
        _dailyMinutes = latest.dailyMinutes;
        if (parsedExam != null && !parsedExam.isBefore(_today)) {
          _examDate = parsedExam;
        }
      });
    });
  }

  Future<void> _pickExamDate() async {
    final firstDate = _today;
    final lastDate = _today.add(const Duration(days: 365));
    final initial = _examDate.isBefore(firstDate) ? firstDate : _examDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Chọn ngày dự kiến thi B1',
    );
    if (picked != null && mounted) {
      setState(() => _examDate = picked);
    }
  }

  Future<void> _submit({required bool skipMiniQuiz}) async {
    final provider = context.read<LearningPathProvider>();
    final plan = await provider.createPlanFromAssessment(
      examDate: _examDate,
      dailyMinutes: _dailyMinutes,
      confidenceLevels: Map<SkillType, int>.from(_confidenceLevels),
      quizAnswers: Map<String, int>.from(_quizAnswers),
      skipMiniQuiz: skipMiniQuiz,
    );
    if (!mounted || plan == null) return;

    widget.onCompleted?.call();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LearningPathProvider>();
    final questions = provider.miniDiagnosticQuestions;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Khảo sát đầu vào B1')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _step == 0
                            ? 'Bước 1/2 · Mục tiêu & tự đánh giá'
                            : 'Bước 2/2 · Kiểm tra nhanh (${_quizAnswers.length}/${questions.length} câu)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      _step == 0 ? '50%' : '100%',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: _step == 0 ? 0.5 : 1.0,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          if (provider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: MaterialBanner(
                backgroundColor: scheme.errorContainer,
                content: Text(
                  provider.errorMessage!,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
                actions: [
                  TextButton(
                    onPressed: provider.clearError,
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _step == 0
                ? _buildStepOne(context, provider.isSaving)
                : _buildStepTwo(context, questions, provider.isSaving),
          ),
        ],
      ),
    );
  }

  Widget _buildStepOne(BuildContext context, bool isSaving) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final formattedExam = LearningPathGenerator.formatDate(_examDate);
    final daysUntil = _examDate.difference(_today).inDays;

    return ListView(
      key: const ValueKey('survey_step_1'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1. Ngày dự kiến thi B1',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedExam,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            daysUntil < 7
                                ? 'Chế độ ôn tập nước rút 7 ngày'
                                : 'Còn $daysUntil ngày (${(daysUntil / 7).ceil()} tuần)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: isSaving ? null : _pickExamDate,
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('Chọn ngày'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final weeks in const [4, 8, 12])
                      ChoiceChip(
                        label: Text('$weeks tuần'),
                        selected: daysUntil == weeks * 7,
                        onSelected: isSaving
                            ? null
                            : (_) => setState(
                                () => _examDate = _today.add(
                                  Duration(days: weeks * 7),
                                ),
                              ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '2. Quỹ thời gian học mỗi ngày',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mỗi ngày lộ trình sẽ đóng gói nhiệm vụ vừa khít quỹ thời gian này.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final minutes in AppConstants.dailyMinuteOptions)
                      ChoiceChip(
                        label: Text('$minutes phút/ngày'),
                        selected: _dailyMinutes == minutes,
                        onSelected: isSaving
                            ? null
                            : (_) => setState(() => _dailyMinutes = minutes),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3. Tự đánh giá mức tự tin 4 kỹ năng (1–5)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '1: Rất yếu · 3: Trung bình · 5: Tự tin thi B1',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                for (final skill in SkillType.coreSkills) ...[
                  _ConfidenceSelectorRow(
                    skill: skill,
                    value: _confidenceLevels[skill] ?? 3,
                    enabled: !isSaving,
                    onChanged: (level) =>
                        setState(() => _confidenceLevels[skill] = level),
                  ),
                  if (skill != SkillType.coreSkills.last)
                    const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: isSaving ? null : () => setState(() => _step = 1),
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Tiếp tục kiểm tra nhanh (10 câu)'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: isSaving ? null : () => _submit(skipMiniQuiz: true),
          child: isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Bỏ qua & tạo lộ trình nền tảng'),
        ),
      ],
    );
  }

  Widget _buildStepTwo(
    BuildContext context,
    List<MiniDiagnosticQuestion> questions,
    bool isSaving,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      key: const ValueKey('survey_step_2'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          color: scheme.primaryContainer.withValues(alpha: 0.45),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mini Diagnostic (~5 phút)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Trả lời nhanh 10 câu đại diện để hệ thống cân đối chính xác hơn giữa Nghe, Đọc, Viết và Nói.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < questions.length; i++) ...[
          _DiagnosticQuestionCard(
            index: i + 1,
            question: questions[i],
            selectedOption: _quizAnswers[questions[i].id],
            enabled: !isSaving,
            onSelected: (optionIndex) {
              setState(() => _quizAnswers[questions[i].id] = optionIndex);
            },
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: isSaving ? null : () => _submit(skipMiniQuiz: false),
          icon: isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: const Text('Tạo lộ trình của tôi'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isSaving ? null : () => setState(() => _step = 0),
                child: const Text('Quay lại Bước 1'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextButton(
                onPressed: isSaving ? null : () => _submit(skipMiniQuiz: true),
                child: const Text('Bỏ qua kiểm tra'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConfidenceSelectorRow extends StatelessWidget {
  const _ConfidenceSelectorRow({
    required this.skill,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final SkillType skill;
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                skill.labelVi,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              'Mức $value/5',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var level = 1; level <= 5; level++) ...[
              Expanded(
                child: ChoiceChip(
                  label: Center(child: Text('$level')),
                  selected: value == level,
                  showCheckmark: false,
                  onSelected: enabled ? (_) => onChanged(level) : null,
                ),
              ),
              if (level < 5) const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }
}

class _DiagnosticQuestionCard extends StatelessWidget {
  const _DiagnosticQuestionCard({
    required this.index,
    required this.question,
    required this.selectedOption,
    required this.enabled,
    required this.onSelected,
  });

  final int index;
  final MiniDiagnosticQuestion question;
  final int? selectedOption;
  final bool enabled;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Câu $index',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    question.skill.labelVi,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              question.prompt,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < question.options.length; i++) ...[
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: enabled ? () => onSelected(i) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selectedOption == i
                        ? scheme.primaryContainer.withValues(alpha: 0.55)
                        : scheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selectedOption == i
                          ? scheme.primary
                          : scheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedOption == i
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: selectedOption == i
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          question.options[i],
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (i < question.options.length - 1) const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}
