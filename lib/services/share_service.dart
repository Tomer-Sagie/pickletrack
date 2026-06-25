import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database.dart';

/// Pure helper: builds the share-sheet text body for a completed match.
@visibleForTesting
String buildMatchSummaryText({
  required String winnerLabel,
  required String teamAPlayers,
  required String teamBPlayers,
  required String finalScores,
  required String date,
  required String duration,
}) {
  final buf = StringBuffer();
  buf.writeln('🏓 PickleTrack Match');
  buf.writeln('$date · $duration');
  buf.writeln('$teamAPlayers  vs  $teamBPlayers');
  buf.writeln('Final: $finalScores');
  buf.writeln('Winner: $winnerLabel');
  buf.writeln();
  buf.writeln('Tracked with PickleTrack — free & offline');
  return buf.toString();
}

/// Pure helper: assembles a [Map<String, dynamic>] entry for a single
/// completed match, including its event log (if supplied).
@visibleForTesting
Map<String, dynamic> buildMatchExportEntry(
  CompletedMatche m, {
  List<MatchEventLogData> eventLog = const [],
}) {
  return {
    'id': m.id,
    'type': m.type,
    'scoringRule': m.scoringRule,
    'gameCount': m.gameCount,
    'gamesPlayed': m.gamesPlayed,
    'playTo': m.playTo,
    'winBy': m.winBy,
    'teamAPlayers': jsonDecode(m.teamAPlayers),
    'teamBPlayers': jsonDecode(m.teamBPlayers),
    'finalScores': jsonDecode(m.finalScores),
    'winner': m.winner,
    'durationSeconds': m.durationSeconds,
    'startedAt': m.startedAt.toIso8601String(),
    'completedAt': m.completedAt.toIso8601String(),
    'eventLog': eventLog.map((e) => {
      'gameNumber': e.gameNumber,
      'eventType': e.eventType,
      'scorerTeam': e.scorerTeam,
      'serverName': e.serverName,
      'teamAScore': e.teamAScore,
      'teamBScore': e.teamBScore,
      'serverNumber': e.serverNumber,
      'timestamp': e.timestamp.toIso8601String(),
    }).toList(),
  };
}

/// Pure helper: encodes a list of export entries as pretty-printed JSON.
@visibleForTesting
String encodeMatchExportJson(List<Map<String, dynamic>> entries) =>
    const JsonEncoder.withIndent('  ').convert(entries);

/// Sharing service for text summaries, screenshots, and data exports.
class ShareService {
  ShareService._();

  /// Shares a text summary of a completed match.
  static Future<void> shareMatchSummary({
    required String winnerLabel,
    required String teamAPlayers,
    required String teamBPlayers,
    required String finalScores,
    required String date,
    required String duration,
  }) async {
    try {
      final text = buildMatchSummaryText(
        winnerLabel: winnerLabel,
        teamAPlayers: teamAPlayers,
        teamBPlayers: teamBPlayers,
        finalScores: finalScores,
        date: date,
        duration: duration,
      );
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (e, st) {
      // Sharing is non-critical; log so failures are visible without
      // crashing the share sheet.
      debugPrint('ShareService.shareMatchSummary failed: $e\n$st');
    }
  }

  /// Captures a screenshot of [repaintKey]'s boundary and shares it.
  static Future<void> shareScreenshot(
    GlobalKey repaintKey, {
    required String matchLabel,
  }) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/pickletrack_$matchLabel.png');
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
      ));
    } catch (e, st) {
      // Silently fail — sharing is non-critical, but DO log so the next
      // person hitting this can debug from logcat without re-deriving
      // why their share button "did nothing".
      debugPrint('ShareService.shareScreenshot failed: $e\n$st');
    }
  }

  /// Exports all completed matches as a JSON file and shares it.
  static Future<void> exportAllData(AppDatabase db) async {
    try {
      final matches = await db.getCompletedMatches();
      final entries = <Map<String, dynamic>>[];
      for (final m in matches) {
        final eventLog = await db.getMatchEventLog(m.id);
        entries.add(buildMatchExportEntry(m, eventLog: eventLog));
      }

      final json = encodeMatchExportJson(entries);
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/pickletrack_export_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(json);

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
      ));
    } catch (e, st) {
      // Same rationale as the other two methods — log rather than swallow.
      debugPrint('ShareService.exportAllData failed: $e\n$st');
    }
  }
}
