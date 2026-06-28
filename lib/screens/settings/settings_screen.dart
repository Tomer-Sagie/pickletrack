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
                  // Replace the previous two-sentence run-on ("A free,
                  // offline-first pickleball score tracker. / No ads, no
                  // accounts, no internet required.") with an icon-led
                  // bullet list, matching the visual rhythm used by the
                  // How-to-Play sections below. Each row states one concrete
                  // promise of the app so the value-prop reads at a glance
                  // instead of blending into a paragraph.
                  //
                  // The first row is intentionally a positive "what the
                  // app IS" line (scores matches) so the brand name above
                  // isn't the only thing anchoring a first-time user to
                  // the app's purpose. The remaining three rows surface
                  // the "what it ISN'T" promises from the original copy.
                  const _AboutFeature(
                    // `add_task_rounded` (clipboard + plus) is the verb
                    // "log a new entry" — the action — vs `scoreboard`
                    // which is the noun (the display).
                    icon: Icons.add_task_rounded,
                    label: 'Scores every match you play',
                  ),
                  const SizedBox(height: 2),
                  const _AboutFeature(
                    icon: Icons.local_offer_rounded,
                    label: 'Free — no subscriptions or hidden costs',
                  ),
                  const SizedBox(height: 2),
                  const _AboutFeature(
                    icon: Icons.cloud_off_rounded,
                    label: 'Works fully offline',
                  ),
                  const SizedBox(height: 2),
                  const _AboutFeature(
                    icon: Icons.privacy_tip_rounded,
                    label: 'No ads, accounts, or tracking',
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
    final current = ref.read(defaultScoringRuleProvider).value ?? 'sideout';
    final result = await _showPickerBottomSheet<String>(
      context: context,
      title: 'Default scoring rule',
      current: current,
      options: const [
        _PickerOption(value: 'sideout', label: 'Side-Out', subtitle: 'Only the serving team can score'),
        _PickerOption(value: 'rally', label: 'Rally', subtitle: 'Every rally scores a point'),
      ],
    );
    if (result != null) {
      ref.read(settingsNotifierProvider.notifier).setDefaultScoringRule(result);
    }
  }

  void _showGameCountPicker() async {
    final current = ref.read(defaultGameCountProvider).value ?? 1;
    final result = await _showPickerBottomSheet<int>(
      context: context,
      title: 'Default games',
      current: current,
      options: const [
        _PickerOption(value: 1, label: '1 Game'),
        _PickerOption(value: 3, label: 'Best of 3'),
      ],
    );
    if (result != null) {
      ref.read(settingsNotifierProvider.notifier).setDefaultGameCount(result);
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
    final builtInOptions = ScoringPreset.defaults
        .map((p) => _PickerOption(
              value: p,
              label: p.label,
            ))
        .toList();
    // When the user's current default is a Custom preset (set via
    // Setup), prepend a disabled informational option so the picker
    // never appears with no selected radio. The option's subtitle shows
    // the exact play-to / win-by values; tapping it is a no-op because
    // Custom defaults can only be edited through Setup.
    final options = current.isCustom
        ? <_PickerOption<ScoringPreset>>[
            _PickerOption<ScoringPreset>(
              value: current,
              label: 'Custom (set via Setup)',
              subtitle: '${current.playTo}, win by ${current.winBy}',
              disabled: true,
            ),
            ...builtInOptions,
          ]
        : builtInOptions;
    final result = await _showPickerBottomSheet<ScoringPreset>(
      context: context,
      title: 'Default win condition',
      current: current,
      options: options,
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
        // Destructive actions get a warning chip instead of a chevron,
        // which would (incorrectly) read as "navigate to a sub-screen".
        trailing: Icon(
          Icons.warning_amber_rounded,
          color: theme.colorScheme.error,
          size: 22,
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

  // The How-to-Play body is supplied by [_kHowToPlaySections] (a
  // top-level const List<Map<String, Object>>) and rendered by
  // [_buildHowToPlaySections]. Future locale swaps are data-only.
  Widget _buildHowToPlay(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(Icons.help_outline_rounded, size: 22, color: theme.colorScheme.primary),
        title: Text('How to Play', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: _buildHowToPlaySections(),
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

// ── How-to-Play data source ──

/// Localisation-ready data source for the How-to-Play expansion. Each
/// map entry carries:
///
///  • `'title'`   — [String], section heading
///  • `'icon'`    — [IconData], topic-matching lead-in glyph
///  • `'bullets'` — [List]<[String]>, discrete rules under the title
///
/// Replaces the previous hand-rolled `_HowToPlaySection(...)` literals
/// inside `_buildHowToPlay`. Lifting the data out of widget code means
/// future locale swaps become pure data edits — wrap this list in a
/// `Map<Locale, List<Map<String, Object>>>` (or load it from an asset)
/// without touching any widget code.
///
/// The map shape ([Map]<[String], [Object]>) matches the codebase's
/// convention for structured locale-agnostic data, so any future
/// data-driven expansion (sound effects, undo copy, etc.) can lift
/// literals the same way. Dart 3 records would be a more type-safe
/// alternative if direct map↔locale-object symmetry isn't needed.
const List<Map<String, Object>> _kHowToPlaySections = <Map<String, Object>>[
  <String, Object>{
    'title': 'Basic Rules',
    'icon': Icons.rule_rounded,
    'bullets': <String>[
      'Games are played to 11 points (or 7/15 for Quick/Tournament).',
      'You must win by 2 points.',
      'In side-out scoring, only the serving team can score points.',
    ],
  },
  <String, Object>{
    'title': 'Doubles Serving',
    'icon': Icons.groups_2_rounded,
    'bullets': <String>[
      'The first server of the game starts as Server 2 (0-0-2).',
      'Server 1 serves until losing a rally, then Server 2 serves.',
      'After Server 2 loses, it’s a side-out to the other team.',
      'When the serving team scores, partners switch sides.',
    ],
  },
  <String, Object>{
    'title': 'Singles Serving',
    'icon': Icons.person_rounded,
    'bullets': <String>[
      'Serve from the right side when your score is even.',
      'Serve from the left side when your score is odd.',
      'A lost rally is a side-out (you lose the serve).',
    ],
  },
  <String, Object>{
    'title': 'Rally Scoring',
    'icon': Icons.flash_on_rounded,
    'bullets': <String>[
      'Every rally awards a point — the rally winner scores.',
      'Either team can score, regardless of who served.',
      'The serving team changes after each lost rally.',
    ],
  },
  <String, Object>{
    'title': 'The Kitchen',
    // `do_disturb_alt_rounded` reads as the do-not / no-entry
    // indicator, which carries the "you can't volley here" zone
    // restriction more directly than a generic `block_rounded`.
    'icon': Icons.do_disturb_alt_rounded,
    'bullets': <String>[
      'No volleying while standing in the non-volley zone (the kitchen).',
      'The ball must bounce before you hit it if your feet are in the kitchen.',
    ],
  },
];

/// Materialises [_kHowToPlaySections] as a `List<Widget>` of
/// `_HowToPlaySection` widgets. Lives at file-scope (not as a
/// `_SettingsScreenState` method) so that any future locale-keyed
/// variant of the data source can share the same renderer.
///
/// Casting `'bullets'` via `(List).cast<String>()` accounts for
/// Dart's runtime generic erasure — at runtime `_kHowToPlaySections`
/// is just `List`, so we recover static `List<String>` typing here
/// instead of at every read site.
List<Widget> _buildHowToPlaySections() {
  return <Widget>[
    for (final section in _kHowToPlaySections)
      _HowToPlaySection(
        title: section['title']! as String,
        icon: section['icon']! as IconData,
        bullets: section['bullets']! as List<String>,
      ),
  ];
}

// ── How to Play Section ──

/// One bullet-list entry inside the How-to-Play expansion. Each
/// section gets:
///
///  • a small [icon] leading the title (signals the topic at a glance)
///  • a list of [bullets], each rendered with a leading bullet glyph
///    so the body reads as discrete rules instead of a paragraph.
///
/// The `bullets` list replaces the previous single-string `body`, which
/// collapsed several rules into a run-on sentence that hid the "list
/// of things you must remember" feel.
class _HowToPlaySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> bullets;

  const _HowToPlaySection({
    required this.title,
    required this.icon,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Indent the bullet list so the bullet glyphs line up under
          // the title text (not under the icon) — the title row is
          // Icon(16) + SizedBox(6) + Text, so the title text starts
          // at 22px from the content edge. Keeping the bullets at the
          // same 22px avoids a floating-text look.
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final bullet in bullets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      // `center` auto-positions the dot against the row
                      // height that the [Expanded] text dictates — no
                      // magic-number offset to track if the theme's
                      // bodySmall metrics change.
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Use a Material Icon rather than the Text bullet
                        // glyph (•) so the marker renders at a stable
                        // width across Roboto / SF / web font fallbacks.
                        Icon(
                          Icons.fiber_manual_record,
                          size: 5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bullet,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── About Feature ──

/// Single icon-led row inside the About card. Mirrors the visual
/// rhythm used by the How-to-Play `_HowToPlaySection` widget (small
/// icon on the left, short label on the right) but without the bullet
/// glyph — each feature is distinct enough to warrant its own
/// recognisable icon, whereas How-to-Play bullets express the "list
/// of rules under a topic" structure.
///
/// Keeping the row [const]-constructable allows the parent `Column`
/// to declare a `const [...]` children list, matching how the
/// How-to-Play sections above are laid out.
class _AboutFeature extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AboutFeature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      // `center` auto-positions the icon against the row height set
      // by the label text — same approach we settled on for the
      // bullet dot in `_HowToPlaySection`, so the About card visually
      // matches How-to-Play without any magic-number offset.
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ExcludeSemantics on the icon so TalkBack doesn't announce
        // the icon glyph name (e.g. "local_offer rounded icon") as
        // a prefix to the label. The Text below is the single
        // meaningful semantic node for the row.
        ExcludeSemantics(
          child: Icon(icon, size: 16, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Picker Bottom Sheet (shared) ──

class _PickerOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final bool disabled;
  const _PickerOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.disabled = false,
  });
}

/// Reusable bottom-sheet picker used by Scoring rule, Games, and
/// Win Condition defaults. Saves screen real estate vs. a modal
/// dialog and matches Material 3 mobile conventions where
/// single-choice options appear in a draggable sheet.
Future<T?> _showPickerBottomSheet<T>({
  required BuildContext context,
  required String title,
  required T current,
  required List<_PickerOption<T>> options,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) {
      final theme = Theme.of(sheetCtx);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Cancel',
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            for (final option in options)
              RadioListTile<T>(
                title: Text(option.label),
                subtitle: option.subtitle != null ? Text(option.subtitle!) : null,
                value: option.value,
                groupValue: current,
                onChanged: option.disabled
                    ? null
                    : (v) => Navigator.pop(sheetCtx, v),
              ),
          ],
        ),
      );
    },
  );
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
