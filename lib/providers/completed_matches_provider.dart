import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import 'database_provider.dart';

/// List of all completed matches, most recent first.
final completedMatchesProvider =
    FutureProvider<List<CompletedMatche>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getCompletedMatches();
});
