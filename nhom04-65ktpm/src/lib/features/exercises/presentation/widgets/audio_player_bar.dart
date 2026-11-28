import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/audio_controller.dart';

String formatClock(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$minutes:$seconds' : '$minutes:$seconds';
}

/// Trình phát audio bài nghe: phát/tạm dừng, tua ±5 giây, kéo thanh tiến trình, đổi tốc độ.
class AudioPlayerBar extends StatefulWidget {
  const AudioPlayerBar({super.key, required this.assetPath});

  final String assetPath;

  @override
  State<AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends State<AudioPlayerBar> {
  static const _speeds = [0.75, 1.0, 1.25];
  static const _skip = Duration(seconds: 5);

  late final AudioController _controller;
  double? _dragValue;

  @override
  void initState() {
    super.initState();
    _controller = _factory().create()..load(widget.assetPath);
  }

  /// Test đăng ký bản giả qua Provider; app thật dùng just_audio.
  AudioControllerFactory _factory() {
    try {
      return context.read<AudioControllerFactory>();
    } on ProviderNotFoundException {
      return const AudioControllerFactory();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: ValueListenableBuilder<AudioState>(
          valueListenable: _controller,
          builder: (context, state, _) {
            if (state.error != null) {
              return ListTile(
                leading: const Icon(Icons.volume_off),
                title: Text(state.error!),
                subtitle: const Text(
                  'Bạn vẫn có thể đọc transcript sau khi nộp.',
                ),
              );
            }
            final total = state.duration ?? Duration.zero;
            final maxMs = total.inMilliseconds.toDouble();
            final posMs = state.position.inMilliseconds
                .clamp(0, total.inMilliseconds)
                .toDouble();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: _dragValue ?? posMs,
                  max: maxMs > 0 ? maxMs : 1,
                  onChanged: maxMs > 0
                      ? (v) => setState(() => _dragValue = v)
                      : null,
                  onChangeEnd: (v) {
                    _controller.seek(Duration(milliseconds: v.round()));
                    setState(() => _dragValue = null);
                  },
                ),
                Row(
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      '${formatClock(state.position)} / ${formatClock(total)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Lùi 5 giây',
                      icon: const Icon(Icons.replay_5),
                      onPressed: () => _controller.seekBy(-_skip),
                    ),
                    IconButton.filled(
                      tooltip: state.playing ? 'Tạm dừng' : 'Phát',
                      icon: Icon(
                        state.playing ? Icons.pause : Icons.play_arrow,
                      ),
                      onPressed: state.playing
                          ? _controller.pause
                          : _controller.play,
                    ),
                    IconButton(
                      tooltip: 'Tới 5 giây',
                      icon: const Icon(Icons.forward_5),
                      onPressed: () => _controller.seekBy(_skip),
                    ),
                    PopupMenuButton<double>(
                      tooltip: 'Tốc độ phát',
                      initialValue: state.speed,
                      onSelected: _controller.setSpeed,
                      itemBuilder: (context) => [
                        for (final speed in _speeds)
                          PopupMenuItem(value: speed, child: Text('${speed}x')),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('${state.speed}x'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
