import 'dart:async';

import 'package:flutter/material.dart';

import '../../../assessment/domain/scoring.dart';
import '../../data/models/exam_models.dart';
import 'audio_player_bar.dart' show formatClock;

/// Trang làm đề Viết (ô soạn bài + đếm từ) hoặc Nói (đồng hồ chuẩn bị/nói + ghi chú).
class ProductiveTaskView extends StatelessWidget {
  const ProductiveTaskView({
    super.key,
    required this.skill,
    required this.task,
    required this.initialText,
    required this.onChanged,
  });

  final ExamSkill skill;
  final ProductiveTask task;
  final String initialText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWriting = skill == ExamSkill.writing;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(task.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              task.prompt,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
        if (task.tipsVi.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            leading: const Icon(Icons.lightbulb_outline),
            title: const Text('Gợi ý làm bài'),
            children: [
              for (final tip in task.tipsVi)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.chevron_right, size: 18),
                  title: Text(tip),
                ),
            ],
          ),
        const SizedBox(height: 8),
        if (isWriting)
          _WritingEditor(
            key: ValueKey(task.id),
            task: task,
            initialText: initialText,
            onChanged: onChanged,
          )
        else ...[
          SpeakingTimer(
            key: ValueKey('timer_${task.id}'),
            prepSeconds: task.prepSeconds ?? 0,
            speakSeconds: task.speakSeconds ?? 120,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('notes_${task.id}'),
            initialValue: initialText,
            onChanged: onChanged,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Ghi chú ý chính (không bắt buộc)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ],
    );
  }
}

class _WritingEditor extends StatefulWidget {
  const _WritingEditor({
    super.key,
    required this.task,
    required this.initialText,
    required this.onChanged,
  });

  final ProductiveTask task;
  final String initialText;
  final ValueChanged<String> onChanged;

  @override
  State<_WritingEditor> createState() => _WritingEditorState();
}

class _WritingEditorState extends State<_WritingEditor> {
  late final _controller = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = Scoring.countWords(_controller.text);
    final min = widget.task.minWords;
    final max = widget.task.maxWords;
    final inRange =
        (min == null || words >= min) && (max == null || words <= max);
    final range = min != null && max != null ? ' (yêu cầu $min–$max từ)' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          onChanged: (text) {
            widget.onChanged(text);
            setState(() {});
          },
          minLines: 8,
          maxLines: 16,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            hintText: 'Viết bài của bạn bằng tiếng Anh...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$words từ$range',
          textAlign: TextAlign.end,
          style: TextStyle(
            color: words == 0 || inRange
                ? null
                : Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }
}

/// Đồng hồ luyện nói: đếm thời gian chuẩn bị rồi thời gian nói.
class SpeakingTimer extends StatefulWidget {
  const SpeakingTimer({
    super.key,
    required this.prepSeconds,
    required this.speakSeconds,
  });

  final int prepSeconds;
  final int speakSeconds;

  @override
  State<SpeakingTimer> createState() => _SpeakingTimerState();
}

enum _SpeakPhase { idle, prep, speak, done }

class _SpeakingTimerState extends State<SpeakingTimer> {
  _SpeakPhase _phase = _SpeakPhase.idle;
  int _left = 0;
  Timer? _timer;

  void _start() {
    _timer?.cancel();
    if (widget.prepSeconds > 0) {
      _enter(_SpeakPhase.prep, widget.prepSeconds);
    } else {
      _enter(_SpeakPhase.speak, widget.speakSeconds);
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _enter(_SpeakPhase phase, int seconds) {
    setState(() {
      _phase = phase;
      _left = seconds;
    });
  }

  void _tick() {
    if (_left > 1) {
      setState(() => _left--);
    } else if (_phase == _SpeakPhase.prep) {
      _enter(_SpeakPhase.speak, widget.speakSeconds);
    } else {
      _timer?.cancel();
      _enter(_SpeakPhase.done, 0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = switch (_phase) {
      _SpeakPhase.idle =>
        widget.prepSeconds > 0
            ? 'Chuẩn bị ${widget.prepSeconds}s, nói ${widget.speakSeconds}s'
            : 'Nói trong ${widget.speakSeconds}s',
      _SpeakPhase.prep => 'Chuẩn bị: ${formatClock(Duration(seconds: _left))}',
      _SpeakPhase.speak => 'Đang nói: ${formatClock(Duration(seconds: _left))}',
      _SpeakPhase.done => 'Hết giờ nói. Hãy tự đánh giá sau khi nộp bài.',
    };
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          _phase == _SpeakPhase.speak ? Icons.mic : Icons.timer_outlined,
        ),
        title: Text(label),
        trailing: FilledButton.tonal(
          onPressed: _start,
          child: Text(_phase == _SpeakPhase.idle ? 'Bắt đầu' : 'Làm lại'),
        ),
      ),
    );
  }
}
