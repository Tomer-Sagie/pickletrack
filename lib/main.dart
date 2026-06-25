import 'package:flutter/foundation.dart' show
    debugPrint, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'app.dart';
import 'utils/error_suppression.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    }
  }
  // Quiet down the cosmetic `MissingPluginException` log on platforms
  // where the bundled plugins don't have a host implementation (e.g.
  // `audioplayers.global` on Flutter web before the web shim initializes).
  suppressKnownMissingPluginExceptions();
  runApp(const ProviderScope(child: PickleTrackApp()));
}
