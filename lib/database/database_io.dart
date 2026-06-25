import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Opens a native SQLite database connection (Android, iOS, desktop).
///
/// Wraps [LazyDatabase] in [DatabaseConnection] (rather than using
/// [DatabaseConnection.delayed]) because [NativeDatabase]'s static
/// type flows as [QueryExecutor] in drift 2.x and can't satisfy
/// `Future<DatabaseConnection>` directly. Both branches return
/// [DatabaseConnection] so the conditional import in `database.dart`
/// stays type-safe.
DatabaseConnection openDatabaseConnection() {
  return DatabaseConnection(LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pickletrack.sqlite'));
    return NativeDatabase.createInBackground(file);
  }));
}
