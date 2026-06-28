import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/scoring_preset.dart';
import '../../providers/active_match_provider.dart';
import '../../providers/completed_matches_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../services/share_service.dart';
import '../../services/sound_service.dart';
import '../../version.dart';
import '../../widgets/confirm_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _soundEnabled = true;
  bool _hapticEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadFeedbackPrefs();
  }

  Future<void> _loadFeedbackPrefs() async {
    final db = ref.read(databaseProvider);
    final sound = await db.getSetting('sound_enabled');
    final haptic = await db.getSetting('haptic_enabled');
    if (mounted) {
      setState(() {
        _soundEnabled = sound != 'false';
        _hapticEnabled = haptic != 'false';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // themeModeProvider is AsyncNotifier-backed, so we unwrap to a
    // sync ThemeMode here. While the DB read is in flight we fall back
    // to ThemeMode.system (the same default the bootstrap uses) so the
    // SegmentedButton pre-selection is always stable.
    final themeMode =
        ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text('Settings'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // ── Theme ──
          Semantics(header: true, child: const _SectionHeader(icon: Icons.palette_rounded, label: 'Appearance')),
          const SizedBox(height: 8),
          _buildThemeSelector(theme, themeMode),

          const SizedBox(height: 28),

          // ── Defaults ──
          Semantics(header: true, child: const _SectionHeader(icon: Icons.tune_rounded, label: 'Defaults')),
          const SizedBox(height: 8),
          _buildDefaultsSection(theme),

          const SizedBox(height: 28),

          // ── Feedback ──
          Semantics(header: true, child: const _SectionHeader(icon: Icons.volume_up_rounded, label: 'Sound & Feedback')),
          const SizedBox(height: 8),
          _buildFeedbackSection(theme),

          const SizedBox(height: 28),

          // ── Data ──
          Semantics(header: true, child: const _SectionHeader(icon: Icons.storage_rounded, label: 'Data')),
          const SizedBox(height: 8),
          _buildClearDataTile(theme),
          const SizedBox(height: 2),
          _buildClearPlayersTile(theme),
          const SizedBox(height: 2),
          _buildExportDataTile(theme),

          const SizedBox(height: 28),

          // ── About ──
          Semantics(header: true, child: const _SectionHeader(icon: Icons.info_outline_rounded, label: 'About')),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PickleTrack',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appVersionLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A free, offline-first pickleball score tracker.\nNo ads, no accounts, no internet required.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildHowToPlay(theme),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(ThemeData theme, ThemeMode current) {
    final labels = {
      ThemeMode.system: 'System',
      ThemeMode.light: 'Light',
      ThemeMode.dark: 'Dark',
    };
    final icons = {
      ThemeMode.system: Icons.settings_suggest_rounded,
      ThemeMode.light: Icons.light_mode_rounded,
      ThemeMode.dark: Icons.dark_mode_rounded,
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SegmentedButton<ThemeMode>(
          segments: ThemeMode.values.map((mode) {
            return ButtonSegment<ThemeMode>(
              value: mode,
              label: Text(labels[mode]!),
              icon: Icon(icons[mode], size: 18),
            );
          }).toList(),
          selected: {current},
          onSelectionChanged: (selected) {
            final notifier = ref.read(themeModeProvider.notifier);
            notifier.setMode(selected.first);
          },
        ),
      ),
    );
  }

  Widget _buildDefaultsSection(ThemeData theme) {
    final scoringRule = ref.watch(defaultScoringRuleProvider);
    final gameCount = ref.watch(defaultGameCountProvider);

    return Column(
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.rule_rounded,
                label: 'Scoring rule',
                trailing: scoringRule.when(
                  data: (rule) => Text(
                    rule == 'sideout' ? 'Side-Out' : 'Rally',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  loading: () => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
                ),
                onTap: () => _showScoringRulePicker(),
              ),
              const _Divider(),
              _SettingsTile(
                icon: Icons.casino_rounded,
                label: 'Games',
                trailing: gameCount.when(
                  data: (count) => Text(
                    count == 3 ? 'Best of 3' : '1 Game',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  loading: () => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
                ),
                onTap: () => _showGameCountPicker(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        _buildPresetPickerSection(theme),
      ],
    );
  }

  void _showScoringRulePicker() async {
    final ruleProvider = defaultScoringRuleProvider;
    final current = ref.read(ruleProvider).value ?? 'sideout';

    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Default scoring rule'),
        children: [
          RadioListTile<String>(
            title: const Text('Side-Out'),
            subtitle: const Text('Only the serving team can score'),
            value: 'sideout',
            groupValue: current,
            onChanged: (v) => Navigator.pop(context, v),
          ),
          RadioListTile<String>(
            title: const Text('Rally'),
            subtitle: const Text('Every rally scores a point'),
            value: 'rally',
            groupValue: current,
            onChanged: (v) => Navigator.pop(context, v),
          ),
        ],
      ),
    );

    if (result != null) {
      ref.read(settingsNotifierProvider.notifier).setDefaultScoringRule(result);
    }
  }

  void _showGameCountPicker() async {
    final countProvider = defaultGameCountProvider;
    final current = ref.read(countProvider).value ?? 1;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Default games'),
        children: [
          RadioListTile<int>(
            title: const Text('1 Game'),
            value: 1,
            groupValue: current,
            onChanged: (v) => Navigator.pop(context, v),
          ),
          RadioListTile<int>(
            title: const Text('Best of 3'),
            value: 3,
            groupValue: current,
            onChanged: (v) => Navigator.pop(context, v),
          ),
        ],
      ),
    );

    if (result != null) {
      ref
          .read(settingsNotifierProvider.notifier)
          .setDefaultGameCount(result);
    }
  }

  Widget _buildFeedbackSection(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_rounded, size: 22),
            title: const Text('Point Sound'),
            subtitle: const Text('Short sound on point scored'),
            value: _soundEnabled,
            onChanged: (v) async {
              setState(() => _soundEnabled = v);
              SoundService().setEnabled(v);
              final db = ref.read(databaseProvider);
              await db.setSetting('sound_enabled', v.toString());
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          const _Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.vibration_rounded, size: 22),
            title: const Text('Haptic Feedback'),
            subtitle: const Text('Light vibration on point scored'),
            value: _hapticEnabled,
            onChanged: (v) async {
              setState(() => _hapticEnabled = v);
              final db = ref.read(databaseProvider);
              await db.setSetting('haptic_enabled', v.toString());
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetPickerSection(ThemeData theme) {
    final preset = ref.watch(defaultScoringPresetProvider);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: _SettingsTile(
        icon: Icons.emoji_events_rounded,
        label: 'Win Condition',
        trailing: preset.when(
          data: (p) => Text(
            p.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          loading: () => const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) => Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
        ),
        onTap: () => _showPresetPicker(),
      ),
    );
  }

  void _showPresetPicker() async {
    final current = ref.read(defaultScoringPresetProvider).value ?? ScoringPreset.standard;

    final result = await showDialog<ScoringPreset>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Default win condition'),
        children: [
          // When the user's current default is a Custom preset (set via
          // Setup), render a disabled informational radio at the top so
          // the picker never shows up with no radio selected. The tile
          // labels the exact play-to / win-by values so the user can see
          // what their active custom default is, but tapping it is a no-op
          // — Custom defaults can only be edited through Setup.
          if (current.isCustom)
            RadioListTile<ScoringPreset>(
              title: const Text('Custom (set via Setup)'),
              subtitle: Text(
                '${current.playTo}, win by ${current.winBy}',
              ),
              value: current,
              groupValue: current,
              onChanged: null,
            ),
          ...ScoringPreset.defaults.map((p) => RadioListTile<ScoringPreset>(
            title: Text(p.label),
            value: p,
            groupValue: current,
            onChanged: (v) => Navigator.pop(context, v),
          )),
        ],
      ),
    );

    if (result != null) {
      ref.read(settingsNotifierProvider.notifier).setDefaultPreset(result);
    }
  }

  Widget _buildClearDataTile(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: _SettingsTile(
        icon: Icons.delete_outline_rounded,
        label: 'Clear all data',
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
        onTap: () => _confirmClearData(),
        isDestructive: true,
      ),
    );
  }

  Widget _buildClearPlayersTile(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: _SettingsTile(
        icon: Icons.person_off_rounded,
        label: 'Clear Recent Players',
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
        onTap: () => _confirmClearPlayers(),
      ),
    );
  }

  Widget _buildExportDataTile(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: _SettingsTile(
        icon: Icons.ios_share_rounded,
        label: 'Export All Data',
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
        onTap: () async {
          final db = ref.read(databaseProvider);
          await ShareService.exportAllData(db);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export prepared — share sheet opened.')),
            );
          }
        },
      ),
    );
  }

  // TODO(i18n): The How-to-Play body strings below are hardcoded
  // English. When localizing, extract them into a structured list
  // (List<{String title, String body}>) keyed by locale so the
  // ExpansionTile children can be generated from a data source
  // instead of inline literals.
  Widget _buildHowToPlay(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(Icons.help_outline_rounded, size: 22, color: theme.colorScheme.primary),
        title: Text('How to Play', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const _HowToPlaySection(
            title: 'Basic Rules',
            body: 'Games are played to 11 points (or 7/15 for Quick/Tournament). '
                'You must win by 2 points. In side-out scoring, only the serving '
                'team can score points.',
          ),
          const _HowToPlaySection(
            title: 'Doubles Serving',
            body: 'The first server of the game starts as Server 2 (0-0-2). '
                'Server 1 serves until losing a rally, then Server 2 serves. '
                'After Server 2 loses, it\'s a side-out to the other team. '
                'When the serving team scores, partners switch sides.',
          ),
          const _HowToPlaySection(
            title: 'Singles Serving',
            body: 'The server serves from the right side when their score is even, '
                'and from the left when their score is odd. A lost rally is a side-out.',
          ),
          const _HowToPlaySection(
            title: 'Rally Scoring',
            body: 'Every rally awards a point — the team that wins the rally scores, '
                'regardless of who served. The serving team changes after each lost rally.',
          ),
          const _HowToPlaySection(
            title: 'The Kitchen',
            body: 'Players cannot volley the ball while standing in the non-volley zone '
                '(the kitchen). The ball must bounce before hitting it if you\'re in the kitchen.',
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearPlayers() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Clear recent players?',
      message: 'This removes all autocomplete suggestions.',
      confirmLabel: 'Clear',
      isDestructive: true,
    );
    if (confirmed != true) return;

    final db = ref.read(databaseProvider);
    await db.delete(db.recentPlayers).go();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recent players cleared.')),
      );
    }
  }

  Future<void> _confirmClearData() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Clear all data?',
      message:
          'This will delete all completed matches, recent players, and settings. This cannot be undone.',
      confirmLabel: 'Clear Everything',
      isDestructive: true,
    );

    if (confirmed != true) return;

    final db = ref.read(databaseProvider);
    try {
      // Delete all data in a single transaction so partial failures
      // can never leave the database in an inconsistent state.
      await db.transaction(() async {
        // ── Child tables first (foreign keys) ──
        await db.delete(db.matchEventLog).go();
        await db.delete(db.scoreEvents).go();
        await db.delete(db.activeMatchPlayers).go();

        // ── Parent tables ──
        await db.delete(db.completedMatches).go();
        await db.delete(db.activeMatches).go();
        await db.delete(db.recentPlayers).go();
        await db.delete(db.appSettings).go();
        await db.delete(db.tournaments).go();
      });

      // Reset theme to system and re-derive default settings
      ref.read(themeModeProvider.notifier).setMode(ThemeMode.system);

      // Invalidate all providers so the UI reflects the cleared state
      // without requiring a manual navigation away-and-back.
      ref.invalidate(themeModeProvider);
      ref.invalidate(completedMatchesProvider);
      ref.invalidate(activeMatchProvider);
      ref.invalidate(tournamentsProvider);
      ref.invalidate(defaultScoringRuleProvider);
      ref.invalidate(defaultGameCountProvider);
      ref.invalidate(defaultScoringPresetProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear data: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
}

// ── How to Play Section ──

class _HowToPlaySection extends StatelessWidget {
  final String title;
  final String body;

  const _HowToPlaySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary)),
          const SizedBox(height: 2),
          Text(body,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, height: 1.4)),
        ],
      ),
    );
  }
}

// ── Section Header ──

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings Tile ──

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color:
            isDestructive ? theme.colorScheme.error : theme.colorScheme.primary,
        size: 22,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isDestructive
              ? theme.colorScheme.error
              : theme.colorScheme.onSurface,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

// ── Divider ──

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
