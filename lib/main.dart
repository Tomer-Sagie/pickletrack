import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show
    debugPrint, defaultTargetPlatform, kDebugMode, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart'
    if (dart.library.html) 'stubs/sqlite3_web_stub.dart';

import 'app.dart';
import 'database/database.dart';
import 'services/crash_reporting_service.dart';
import 'utils/error_suppression.dart';
import 'widgets/error_boundary.dart';

/// Queued crash entries captured before the app (and therefore the DB)
/// is initialized. [PickleTrackApp] flushes these on first frame.
final List<_QueuedCrash> _queuedCrashes = [];

String? _lastErrorString;
DateTime? _lastErrorTime;

class _QueuedCrash {
  final String context;
  final Object error;
  final StackTrace? stackTrace;

  const _QueuedCrash(this.context, this.error, this.stackTrace);
}

/// Flush any crashes caught during early startup to the local DB log.
/// Called from [PickleTrackApp] once the database is reachable.
Future<void> flushStartupCrashes(AppDatabase db) async {
  if (_queuedCrashes.isEmpty) return;
  final service = CrashReportingService.instance;
  for (final crash in _queuedCrashes) {
    await service.report(
      db: db,
      context: crash.context,
      error: crash.error,
      stackTrace: crash.stackTrace,
    );
  }
  _queuedCrashes.clear();
}

/// Simple deduplication: skip identical error strings within 2 seconds.
bool _shouldDedup(String errorString) {
  final now = DateTime.now();
  if (_lastErrorString == errorString &&
      _lastErrorTime != null &&
      now.difference(_lastErrorTime!).inMilliseconds < 2000) {
    return true;
  }
  _lastErrorString = errorString;
  _lastErrorTime = now;
  return false;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Capture framework errors (build/layout/paint exceptions).
  FlutterError.onError = (details) {
    if (_shouldDedup(details.exception.toString())) {
      FlutterError.presentError(details);
      return;
    }
    _queuedCrashes.add(_QueuedCrash(
      'framework',
      details.exception,
      details.stack,
    ));
    // Still forward to the default handler so debug builds show the
    // red error screen and release builds still get console logging.
    FlutterError.presentError(details);
  };

  // Capture uncaught async errors (zones, futures, timers).
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    if (_shouldDedup(error.toString())) return true;
    _queuedCrashes.add(_QueuedCrash('async', error, stack));
    return true; // prevent default handler from also logging
  };

  // `sqlite3_flutter_libs` bundles a prebuilt `libsqlite3.so` into
  // the APK via its Gradle plugin, so Drift's NativeDatabase finds
  // it on Android (API 24+) automatically. The legacy workaround
  // below patches a pre-Android-7 dlopen bug — no-op on modern
  // devices and skipped on iOS / desktop / web.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    } catch (e, st) {
      // Cheap insurance against a future Android variant making the
      // helper throw — never block runApp over an FFI patch.
      debugPrint('PickleTrack: sqlite3 workaround failed: $e\n$st');
      _queuedCrashes.add(_QueuedCrash('sqlite3_workaround', e, st));
    }
  }
  // Initialize Firebase (graceful fallback if config files are missing).
  // This lets the app start normally during development before the
  // google-services.json / GoogleService-Info.plist are added.
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
  } catch (e, st) {
    debugPrint('PickleTrack: Firebase initialization skipped: $e');
    _queuedCrashes.add(_QueuedCrash('firebase_init', e, st));
  }

  // Enable Crashlytics in release builds once Firebase is available.
  if (firebaseInitialized && !kDebugMode) {
    FlutterError.onError = (details) {
      if (_shouldDedup(details.exception.toString())) {
        FlutterError.presentError(details);
        return;
      }
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      // Also queue for local DB fallback.
      _queuedCrashes.add(_QueuedCrash('framework', details.exception, details.stack));
      FlutterError.presentError(details);
    };

    WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
      if (_shouldDedup(error.toString())) return true;
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      _queuedCrashes.add(_QueuedCrash('async', error, stack));
      return true;
    };
  }

  // Replace the default red error screen with a production recovery UI.
  // On render errors, users see a "Go Home" button instead of a crash.
  ErrorWidget.builder = (details) => ErrorBoundaryWidget(details: details);

  // Quiet down the cosmetic `MissingPluginException` log on platforms
  // where the bundled plugins don't have a host implementation (e.g.
  // `audioplayers.global` on Flutter web before the web shim initializes).
  suppressKnownMissingPluginExceptions();
  runApp(const ProviderScope(child: PickleTrackApp()));
}
