import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pickletrack/services/sound_service.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

/// Test-clean instance that uses a mocked [AudioPlayer]. The shared global
/// singleton is left untouched so other test files keep working.
SoundService _testInstance(AudioPlayer mock) =>
    SoundService.forTest(player: mock);

void main() {
  // Initialise the Flutter test binding so that SystemSound.play (which
  // goes through a platform channel) has a binding to talk to.
  TestWidgetsFlutterBinding.ensureInitialized();

  // Stub AssetSource equality so mocktail's `verify(...withAnyArgument)`
  // works on calls that include it.
  setUpAll(() {
    registerFallbackValue(AssetSource('any'));
  });

  group('SoundService', () {
    late _MockAudioPlayer mockPlayer;

    setUp(() {
      mockPlayer = _MockAudioPlayer();
      // Default: enable sound at start of each test
      _testInstance(mockPlayer).setEnabled(true);
    });

    test('isEnabled default is true', () {
      final svc = _testInstance(_MockAudioPlayer());
      expect(svc.isEnabled, true);
    });

    test('setEnabled updates the flag', () {
      final svc = _testInstance(_MockAudioPlayer());
      svc.setEnabled(false);
      expect(svc.isEnabled, false);
      svc.setEnabled(true);
      expect(svc.isEnabled, true);
    });

    test('playPointScored does nothing when disabled', () async {
      final svc = _testInstance(mockPlayer);
      svc.setEnabled(false);
      await svc.playPointScored();
      verifyNever(() => mockPlayer.play(any()));
    });

    test('playPointScored attempts to play the bundled asset when enabled', () async {
      final svc = _testInstance(mockPlayer);
      when(() => mockPlayer.play(any())).thenAnswer((_) async {});

      await svc.playPointScored();

      final captured = verify(() => mockPlayer.play(captureAny())).captured;
      expect(captured, hasLength(1));
      final src = captured.single as AssetSource;
      expect(src.path, 'sounds/point_scored.wav');
    });

    test('playPointScored swallows errors silently (fallback path)', () async {
      final svc = _testInstance(mockPlayer);
      when(() => mockPlayer.play(any())).thenThrow(Exception('Asset missing'));

      // Should not throw — a missing asset triggers the system sound fallback
      // which is also a side effect we don't want to test here.
      await svc.playPointScored();
    });

    test('dispose releases the audio player', () async {
      final svc = _testInstance(mockPlayer);
      when(() => mockPlayer.dispose()).thenAnswer((_) async {});
      svc.dispose();
      verify(() => mockPlayer.dispose()).called(1);
    });
  });

  // ── SystemSound.play channel interaction ──
  //
  // When the asset is missing, SoundService falls back to
  // SystemSound.play(SystemSoundType.click). That call goes through Flutter's
  // platform-channel layer. In a unit test environment that channel is a
  // TestDefaultBinaryMessengerBinding, so we just verify the test doesn't
  // throw when the fallback is reached.
  group('SystemSound fallback', () {
    late _MockAudioPlayer mockPlayer;

    setUp(() {
      mockPlayer = _MockAudioPlayer();
    });

    test('does not throw when audio player + fallback are both unavailable', () async {
      final svc = _testInstance(mockPlayer);
      when(() => mockPlayer.play(any())).thenThrow(Exception('boom'));

      // Test platform channels swallow the SystemSound.play call silently.
      await svc.playPointScored();
    });
  });
}


