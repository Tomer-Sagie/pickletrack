import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MissingPluginException;

/// Platform channels that we have explicitly verified are missing on at
/// least one supported platform (e.g. `audioplayers` before the
/// `audioplayers_web` shim is registered on Flutter web).
///
/// Keep this allowlist tight: every entry must be justified by an
/// observed `MissingPluginException` in production code. Anything else
/// should keep surfacing so we don't accidentally silence real bugs.
const Set<String> _knownUnsupportedChannels = <String>{
  'xyz.luan/audioplayers.global',
};

/// Returns `true` when [error] is a [MissingPluginException] whose
/// message mentions one of the channel names in the allowlist.
///
/// Exposed as `@visibleForTesting` so the matcher can be unit-tested
/// without touching global `FlutterError` / `PlatformDispatcher` state.
@visibleForTesting
bool isKnownMissingPluginException(Object error) {
  if (error is! MissingPluginException) return false;
  final haystack = error.message ?? error.toString();
  return _knownUnsupportedChannels.any(haystack.contains);
}

/// Silences noisy `MissingPluginException` log entries for the channels
/// in the allowlist. Hooks both:
/// * [FlutterError.onError] — synchronously raised framework errors.
/// * [PlatformDispatcher.instance.onError] — async platform-channel
///   errors that never reach the widget binding.
///
/// Non-allow-listed exceptions are forwarded to whichever default
/// handlers Flutter already had in place for [FlutterError.onError] so
/// we don't accidentally mask real bugs. The [PlatformDispatcher]
/// handler deliberately returns `false` for unknowns so Flutter's own
/// default kicks in.
///
/// In debug builds, suppressed exceptions are still surfaced via
/// [debugPrint] so developers can see what was quietly absorbed.
void suppressKnownMissingPluginExceptions() {
  final previousFlutterErrorHandler = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (isKnownMissingPluginException(details.exception)) {
      debugPrint(
        'PickleTrack: suppressed MissingPluginException '
        '(${details.exception})',
      );
      return;
    }
    previousFlutterErrorHandler?.call(details);
  };

  PlatformDispatcher.instance.onError = (
    Object error,
    StackTrace stack,
  ) {
    if (isKnownMissingPluginException(error)) {
      debugPrint(
        'PickleTrack: suppressed MissingPluginException ($error)',
      );
      return true;
    }
    // Defer to Flutter's default handler (print to console + report).
    return false;
  };
}
