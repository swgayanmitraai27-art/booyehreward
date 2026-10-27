import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SoundService {
  static bool isMuted = false;
  static bool _initialized = false;
  static final AudioPlayer _sfxPlayer = AudioPlayer();

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      if (!kIsWeb) {
        await _sfxPlayer.setAudioContext(AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ));
        await _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
        await _sfxPlayer.setVolume(1.0);
      }
    } catch (e) {
      debugPrint('AudioContext init error: $e');
    }
  }

  static Future<void> play(String soundFile) async {
    if (isMuted) return;

    // 1. Instant System Audio & Haptic Fallback (Guaranteed to work on all Android devices)
    try {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
    } catch (_) {}

    // 2. High-quality Arcade Sound Effect via audioplayers
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(1.0);

      if (kIsWeb) {
        try {
          await _sfxPlayer.play(AssetSource('assets/sounds/$soundFile'));
        } catch (_) {
          await _sfxPlayer.play(AssetSource('sounds/$soundFile'));
        }
      } else {
        try {
          await _sfxPlayer.play(AssetSource('sounds/$soundFile'));
        } catch (_) {
          await _sfxPlayer.play(AssetSource('assets/sounds/$soundFile'));
        }
      }
    } catch (e) {
      debugPrint('AudioPlayer play error for $soundFile: $e');
    }
  }

  // Pre-configured sound triggers for arcade games & rewards
  static void playKnifeThrow() => play('knife_throw.wav');
  static void playKnifeHit() => play('knife_hit.wav');
  static void playFruitSlice() => play('fruit_slice.wav');
  static void playMergePop() => play('merge_pop.wav');
  static void playTapClick() => play('tap_click.wav');
  static void playGameOver() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
    play('game_over.wav');
  }
  static void playWinCheer() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
    play('win_cheer.wav');
  }
  static void playSpinTick() => play('spin_tick.wav');
  static void playWin() => play('win_cheer.wav');
}
