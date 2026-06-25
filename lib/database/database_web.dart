import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Opens a WASM-backed database connection for web.
/// Uses [DatabaseConnection.delayed] so the async [WasmDatabase.open]
/// can be passed to [GeneratedDatabase]'s synchronous constructor.
DatabaseConnection openDatabaseConnection() {
  return DatabaseConnection.delayed(Future(() async {
    final result = await WasmDatabase.open(
      databaseName: 'pickletrack',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );

    if (result.missingFeatures.isNotEmpty) {
      // ignore: avoid_print — diagnostic-only, no Flutter logger available in the database layer
      print('Drift web: using ${result.chosenImplementation} '
          '(missing: ${result.missingFeatures})');
    }

    return result.resolvedExecutor;
  }));
}
