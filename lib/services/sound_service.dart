import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Chhoti sound effects (assets/audio/). Sab calls fail-safe hain:
/// agar audio fail ho to game nahi rukta.
///
/// Har effect ek AudioPool se chalta hai (limited players), taake tez taps
/// par naye players jama na hon aur app slow na ho.
class SoundService {
  SoundService._();

  static const _clear = 'horn_clear.mp3';
  static const _bump = 'horn_bump.mp3';
  static const _win = 'win_jingle.mp3';
  static const _lose = 'lose.mp3';

  static Future<void>? _loading;
  static AudioPool? _clearPool;
  static AudioPool? _bumpPool;
  static AudioPool? _winPool;
  static AudioPool? _losePool;

  /// App start par ek bar call karein, taake pehli awaz mein delay na ho.
  static Future<void> preload() => _loading ??= _load();

  static Future<void> _load() async {
    try {
      // Effects MEDIA volume se chalen (phone ke media volume buttons se
      // control hon), music app ko na rokein, aur iOS silent switch maane.
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            usageType: AndroidUsageType.game,
            contentType: AndroidContentType.sonification,
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
        ),
      );
      // Tez taps wale effects ko 4 players tak, baaki ko 1.
      _clearPool = await FlameAudio.createPool(
        _clear,
        minPlayers: 2,
        maxPlayers: 4,
      );
      _bumpPool = await FlameAudio.createPool(
        _bump,
        minPlayers: 1,
        maxPlayers: 2,
      );
      _winPool = await FlameAudio.createPool(
        _win,
        minPlayers: 1,
        maxPlayers: 1,
      );
      _losePool = await FlameAudio.createPool(
        _lose,
        minPlayers: 1,
        maxPlayers: 1,
      );
    } catch (error) {
      debugPrint('Sound preload failed: $error');
      _loading = null; // agli bar dobara try ho sake
    }
  }

  static Future<void> _start(AudioPool pool, double volume) async {
    try {
      await pool.start(volume: volume);
    } catch (error) {
      debugPrint('Sound play failed: $error');
    }
  }

  static void _play(
    AudioPool? pool, {
    required bool enabled,
    required double volume,
  }) {
    if (!enabled || pool == null) return;
    unawaited(_start(pool, volume));
  }

  static void clear({required bool enabled}) =>
      _play(_clearPool, enabled: enabled, volume: 0.5);
  static void bump({required bool enabled}) =>
      _play(_bumpPool, enabled: enabled, volume: 0.6);
  static void win({required bool enabled}) =>
      _play(_winPool, enabled: enabled, volume: 0.7);
  static void lose({required bool enabled}) =>
      _play(_losePool, enabled: enabled, volume: 0.7);
}
