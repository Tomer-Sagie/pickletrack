import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:flutter/services.dart';

/// Lightweight sound service for point-scored confirmation.
///
/// Uses [audioplayers] for custom sounds and falls back to
/// [SystemSound] when the asset cannot be loaded **or** when the host
/// platform has no [audioplayers] implementation (e.g. `flutter run -d chrome`
/// without `audioplayers_web` configured).
class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;

  /// Internal constructor — used by tests to inject a mock [AudioPlayer].
  /// Bypasses the lazy-init path.
  @visibleForTesting
  SoundService.forTest({required AudioPlayer player}) : _player = player, _playerReady = true;

  SoundService._();

  AudioPlayer? _player;
  bool _playerReady = false;
  bool _enabled = true;

  /// Lazily constructs the [AudioPlayer] on first use.
  /// Returns null if the platform channel isn't implemented (e.g. some web
  /// hosts without `audioplayers_web` configured), in which case callers
  /// should fall back to [SystemSound].
  AudioPlayer? _ensurePlayer() {
    if (_playerReady) return _player;
    try {
      _player = AudioPlayer();
      _playerReady = true;
      return _player;
    } catch (e) {
      // Platform missing (e.g. flutter web without audioplayers_web init).
      // Silence the failure — SystemSound is the fallback.
      debugPrint('SoundService: AudioPlayer init unavailable — $e');
      _playerReady = true; // mark as resolved so we don't retry every call
      _player = null;
      return null;
    }
  }

  /// Whether point sounds are enabled.
  bool get isEnabled => _enabled;

  /// Enable or disable sound feedback.
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// True if a real [AudioPlayer] is available on this platform. False on
  /// hosts that lack the audioplayers implementation (e.g. browser without
  /// the web shim).
  bool get hasCustomAudio {
    // Probe once and cache the result.
    return _ensurePlayer() != null;
  }

  /// Play a short confirmation sound for a point scored.
  Future<void> playPointScored() async {
    await _playSound(
      asset: 'sounds/point_scored.wav',
      fallback: SystemSoundType.click,
    );
  }

  /// Play a distinct sound for game end.
  Future<void> playGameEnd() async {
    await _playSound(
      asset: 'sounds/game_end.wav',
      fallback: SystemSoundType.alert,
    );
  }

  /// Play a distinct sound for match end.
  Future<void> playMatchEnd() async {
    await _playSound(
      asset: 'sounds/match_end.wav',
      fallback: SystemSoundType.alert,
    );
  }

  Future<void> _playSound({
    required String asset,
    required SystemSoundType fallback,
  }) async {
    if (!_enabled) return;
    final player = _ensurePlayer();
    if (player == null) {
      try {
        SystemSound.play(fallback);
      } catch (_) {}
      return;
    }
    try {
      await player.play(AssetSource(asset));
    } catch (e) {
      debugPrint('SoundService: failed to play $asset — $e');
      try {
        SystemSound.play(fallback);
      } catch (_) {}
    }
  }

  /// Release resources.
  void dispose() {
    _player?.dispose();
    _player = null;
  }
}
