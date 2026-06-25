import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_test/flutter_test.dart';
import 'package:pickletrack/utils/error_suppression.dart';

void main() {
  group('isKnownMissingPluginException', () {
    test('returns true for MissingPluginException with allowlisted channel', () {
      final err = MissingPluginException(
        'No implementation found for method init on channel '
        'xyz.luan/audioplayers.global',
      );
      expect(isKnownMissingPluginException(err), isTrue);
    });

    test('returns false for MissingPluginException with unknown channel', () {
      final err = MissingPluginException(
        'No implementation found for method init on channel '
        'com.example/unknown_plugin',
      );
      expect(isKnownMissingPluginException(err), isFalse);
    });

    test('returns false for non-MissingPluginException errors', () {
      expect(isKnownMissingPluginException(Exception('boom')), isFalse);
      expect(isKnownMissingPluginException(StateError('bad state')), isFalse);
      expect(isKnownMissingPluginException('a string'), isFalse);
      expect(isKnownMissingPluginException(42), isFalse);
    });

    test('falls back to toString when the message field is null', () {
      // MissingPluginException tolerates a null message; ensure the
      // predicate still safely defaults to false instead of crashing.
      final err = MissingPluginException();
      expect(isKnownMissingPluginException(err), isFalse);
    });
  });
}
