import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Trạng thái trình phát mà giao diện cần.
class AudioState {
  const AudioState({
    this.position = Duration.zero,
    this.duration,
    this.playing = false,
    this.completed = false,
    this.speed = 1.0,
    this.error,
  });

  final Duration position;
  final Duration? duration;
  final bool playing;
  final bool completed;
  final double speed;
  final String? error;

  AudioState copyWith({
    Duration? position,
    Duration? duration,
    bool? playing,
    bool? completed,
    double? speed,
    String? error,
  }) {
    return AudioState(
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playing: playing ?? this.playing,
      completed: completed ?? this.completed,
      speed: speed ?? this.speed,
      error: error ?? this.error,
    );
  }
}

/// Trình phát audio phần Nghe. Tách interface để widget test dùng bản giả.
abstract class AudioController extends ValueNotifier<AudioState> {
  AudioController() : super(const AudioState());

  Future<void> load(String assetPath);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);

  Future<void> seekBy(Duration offset) {
    final duration = value.duration ?? Duration.zero;
    var target = value.position + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (duration > Duration.zero && target > duration) target = duration;
    return seek(target);
  }
}

/// Tạo trình phát cho mỗi đoạn nghe; đăng ký qua Provider để test thay bản giả.
class AudioControllerFactory {
  const AudioControllerFactory();

  AudioController create() => JustAudioController();
}

class JustAudioController extends AudioController {
  JustAudioController() {
    _subscriptions.addAll([
      _player.positionStream.listen((p) => value = value.copyWith(position: p)),
      _player.durationStream.listen((d) => value = value.copyWith(duration: d)),
      _player.playerStateStream.listen((state) {
        final completed = state.processingState == ProcessingState.completed;
        value = value.copyWith(
          playing: state.playing && !completed,
          completed: completed,
        );
      }),
    ]);
  }

  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  Future<void> load(String assetPath) async {
    try {
      final duration = await _player.setAsset(assetPath);
      value = value.copyWith(duration: duration);
    } catch (e) {
      debugPrint('M3 audio load failed ($assetPath): $e');
      value = value.copyWith(error: 'Không phát được audio bài nghe.');
    }
  }

  @override
  Future<void> play() async {
    if (value.completed) await _player.seek(Duration.zero);
    await _player.play();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    value = value.copyWith(speed: speed);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}
