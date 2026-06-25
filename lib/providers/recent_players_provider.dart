import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import 'database_provider.dart';

/// Provides the list of recent player names (up to 20) for autocomplete.
final recentPlayersProvider = FutureProvider<List<RecentPlayer>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getRecentPlayers();
});

/// Convenience provider that returns just the name strings.
final recentPlayerNamesProvider = Provider<Future<List<String>>>((ref) async {
  final players = await ref.watch(recentPlayersProvider.future);
  return players.map((p) => p.name).toList();
});
