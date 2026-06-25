import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';

/// Singleton provider for the AppDatabase instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
