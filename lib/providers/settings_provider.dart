import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scoring_preset.dart';
import 'database_provider.dart';

/// Default setting keys.
abstract class SettingKeys {
  static const defaultScoringRule = 'default_scoring_rule';
  static const defaultGameCount = 'default_game_count';
  static const defaultPlayTo = 'default_play_to';
  static const defaultWinBy = 'default_win_by';
  static const defaultPresetName = 'default_preset_name';
}

/// Provides a setting value by key.
final settingProvider =
    FutureProvider.family<String?, String>((ref, key) {
  final db = ref.watch(databaseProvider);
  return db.getSetting(key);
});

/// Returns the default scoring preset from settings (or Standard if unset).
final defaultScoringPresetProvider =
    FutureProvider<ScoringPreset>((ref) async {
  final db = ref.watch(databaseProvider);
  final presetName = await db.getSetting(SettingKeys.defaultPresetName);
  final playToStr = await db.getSetting(SettingKeys.defaultPlayTo);
  final winByStr = await db.getSetting(SettingKeys.defaultWinBy);

  if (presetName == 'Custom' && playToStr != null && winByStr != null) {
    return ScoringPreset.custom(
      playTo: int.tryParse(playToStr) ?? 11,
      winBy: int.tryParse(winByStr) ?? 2,
    );
  }

  switch (presetName) {
    case 'Quick':
      return ScoringPreset.quick;
    case 'Tournament':
      return ScoringPreset.tournament;
    default:
      return ScoringPreset.standard;
  }
});

/// Returns the default scoring rule from settings (or 'sideout' if unset).
final defaultScoringRuleProvider = FutureProvider<String>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.getSetting(SettingKeys.defaultScoringRule) ?? 'sideout';
});

/// Returns the default game count from settings (or 1 if unset).
final defaultGameCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final val = await db.getSetting(SettingKeys.defaultGameCount);
  return int.tryParse(val ?? '') ?? 1;
});

/// Notifier for updating settings.
class SettingsNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> setDefaultScoringRule(String rule) async {
    final db = ref.read(databaseProvider);
    await db.setSetting(SettingKeys.defaultScoringRule, rule);
    ref.invalidate(defaultScoringRuleProvider);
  }

  Future<void> setDefaultPreset(ScoringPreset preset) async {
    final db = ref.read(databaseProvider);
    await db.setSetting(SettingKeys.defaultPresetName, preset.name);
    await db.setSetting(
        SettingKeys.defaultPlayTo, preset.playTo.toString());
    await db.setSetting(SettingKeys.defaultWinBy, preset.winBy.toString());
    ref.invalidate(defaultScoringPresetProvider);
  }

  Future<void> setDefaultGameCount(int count) async {
    final db = ref.read(databaseProvider);
    await db.setSetting(SettingKeys.defaultGameCount, count.toString());
    ref.invalidate(defaultGameCountProvider);
  }
}

final settingsNotifierProvider = NotifierProvider<SettingsNotifier, void>(
  SettingsNotifier.new,
);
