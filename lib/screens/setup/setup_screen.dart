import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/scoring_preset.dart';
import '../../providers/active_match_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/confirm_dialog.dart';

class SetupScreen extends ConsumerStatefulWidget {
  // Note: the user-facing label on the home card is "Standard Start"
  // but this flag (and its corresponding route param ?quick=true in
  // router.dart) keep the original internal name. The flag is purely
  // boolean plumbing; renaming it would force a router + bookmark
  // migration for no functional gain. Treat it as the legacy alias
  // for "pre-fill Standard Start defaults".
  final bool quickStart;

  const SetupScreen({super.key, this.quickStart = false});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _formKey = GlobalKey<FormState>();

  String _matchType = 'doubles';
  String _scoringRule = 'sideout';
  int _gameCount = 1;
  ScoringPreset _selectedPreset = ScoringPreset.standard;
  int _playTo = 11;
  int _winBy = 2;
  bool _isCustomPreset = false;

  List<TextEditingController> _teamAControllers = [];
  List<TextEditingController> _teamBControllers = [];
  int? _startingServerIndex;

  final _customPlayToController = TextEditingController();
  final _customWinByController = TextEditingController();
  List<FocusNode> _focusNodes = [];
  // Snapshot of initial state for back-press discard detection.
  // When every field matches its snapshot the form is pristine.
  late final String _initialMatchType;
  late final String _initialScoringRule;
  late final int _initialGameCount;
  late final ScoringPreset _initialPreset;
  late final bool _initialIsCustom;
  late final List<String> _initialControllerTexts;

  bool get _hasUnsavedChanges {
    // Compare current controller text against post-init snapshots —
    // works for both quickStart (pre-filled placeholders) and
    // non-quickStart (all empty).  Bound by the shorter list so
    // switching Doubles↔Singles doesn't index past the snapshot.
    final allControllers = [..._teamAControllers, ..._teamBControllers];
    final maxLen = allControllers.length < _initialControllerTexts.length
        ? allControllers.length
        : _initialControllerTexts.length;
    for (var i = 0; i < maxLen; i++) {
      if (allControllers[i].text != _initialControllerTexts[i]) return true;
    }
    if (_matchType != _initialMatchType) return true;
    if (_scoringRule != _initialScoringRule) return true;
    if (_gameCount != _initialGameCount) return true;
    if (_isCustomPreset != _initialIsCustom) return true;
    if (!_isCustomPreset && _selectedPreset != _initialPreset) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _applyDefaults();
  }

  void _applyDefaults() {
    if (widget.quickStart) {
      // Read the user's configured defaults from Riverpod so the
      // Quick Start flow actually respects Settings — the previous
      // hardcoded 'sideout'/1/11/2 ignored the user's choices.
      final rule = ref.read(defaultScoringRuleProvider).valueOrNull ?? 'sideout';
      final gameCount = ref.read(defaultGameCountProvider).valueOrNull ?? 1;
      final preset = ref.read(defaultScoringPresetProvider).valueOrNull ?? ScoringPreset.standard;
      _matchType = 'doubles';
      _scoringRule = rule;
      _gameCount = gameCount;
      _selectedPreset = preset;
      _playTo = preset.playTo;
      _winBy = preset.winBy;
      _isCustomPreset = false;
      _startingServerIndex = 0;
    }
    _rebuildControllers();
    // Snapshot initial state for pristine-check in back-press handler.
    _initialMatchType = _matchType;
    _initialScoringRule = _scoringRule;
    _initialGameCount = _gameCount;
    _initialPreset = _selectedPreset;
    _initialIsCustom = _isCustomPreset;
    _initialControllerTexts = [
      ..._teamAControllers.map((c) => c.text),
      ..._teamBControllers.map((c) => c.text),
    ];
  }

  void _rebuildControllers() {
    // Preserve any text the user typed before switching match type so
    // switching Doubles↔Singles doesn't silently wipe their input.
    final oldTexts = <String>[
      ..._teamAControllers.map((c) => c.text),
      ..._teamBControllers.map((c) => c.text),
    ];
    // Capture old Team-A count BEFORE disposing — needed to correctly
    // offset into oldTexts when rebuilding Team B controllers below.
    final oldACount = _teamAControllers.length;
    for (final c in _teamAControllers) { c.dispose(); }
    for (final c in _teamBControllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }

    final aCount = _matchType == 'singles' ? 1 : 2;
    final bCount = _matchType == 'singles' ? 1 : 2;

    _teamAControllers = List.generate(
      aCount,
      (i) => TextEditingController(text: oldTexts.isNotEmpty && i < oldTexts.length ? oldTexts[i] : (widget.quickStart ? 'Player A${i + 1}' : '')),
    );
    _teamBControllers = List.generate(
      bCount,
      (i) {
        final oldIdx = oldACount + i;
        return TextEditingController(text: oldIdx < oldTexts.length ? oldTexts[oldIdx] : (widget.quickStart ? 'Player B${i + 1}' : ''));
      },
    );
    _focusNodes = List.generate(aCount + bCount, (_) => FocusNode());

    if (_startingServerIndex != null && _startingServerIndex! >= _totalPlayerCount) {
      _startingServerIndex = null;
    }
  }

  int get _totalPlayerCount => _teamAControllers.length + _teamBControllers.length;

  List<String> get _allPlayerNames => [
    ..._teamAControllers.map((c) => c.text),
    ..._teamBControllers.map((c) => c.text),
  ];

  String _playerDisplayName(int index) {
    final names = _allPlayerNames;
    final name = names[index].trim();
    if (name.isNotEmpty) return name;
    if (_matchType == 'singles') return index == 0 ? 'Player A' : 'Player B';
    const labels = ['Player A1', 'Player A2', 'Player B1', 'Player B2'];
    return labels[index];
  }

  String _teamForIndex(int index) => index < _teamAControllers.length ? 'A' : 'B';

  /// Synthesizes a live [ScoringPreset] from the Custom Play-to / Win-by
  /// text fields. Used by the Win Condition dropdown so the "Custom"
  /// menu item always shows the currently typed values instead of an
  /// empty / static string. Falls back to 11 / 2 if either field is
  /// empty / non-numeric; clamps to the valid range so [ScoringPreset.custom]
  /// never throws on the way to render.
  ScoringPreset _currentCustomPreset() {
    final p = int.tryParse(_customPlayToController.text.trim()) ?? 11;
    final w = int.tryParse(_customWinByController.text.trim()) ?? 2;
    return ScoringPreset.custom(
      playTo: p.clamp(1, 99),
      winBy: w.clamp(1, 10),
    );
  }

  @override
  void dispose() {
    for (final c in _teamAControllers) { c.dispose(); }
    for (final c in _teamBControllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    _customPlayToController.dispose();
    _customWinByController.dispose();
    super.dispose();
  }

  bool _hasAtLeastOneNamePerTeam() {
    final hasTeamA = _teamAControllers.any((c) => c.text.trim().isNotEmpty);
    final hasTeamB = _teamBControllers.any((c) => c.text.trim().isNotEmpty);
    return hasTeamA && hasTeamB;
  }

  Future<void> _startMatch() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasAtLeastOneNamePerTeam()) {
      _showError('Each team needs at least one player name.');
      return;
    }
    if (_startingServerIndex == null) {
      _showError('Please select a starting server.');
      return;
    }
    if (_isCustomPreset) {
      // Numeric range / format is enforced by the form-level validators
      // attached to the playTo/winBy TextFormFields above — if we reached
      // this branch the values are guaranteed to be valid integers in
      // range, so we can just parse them straight into our state.
      _playTo = int.parse(_customPlayToController.text);
      _winBy = int.parse(_customWinByController.text);
    }

    final serverIndex = _startingServerIndex!;
    final serverTeam = _teamForIndex(serverIndex);
    final players = <({String name, String team, bool isStartingServer, String? position})>[];

    for (var i = 0; i < _teamAControllers.length; i++) {
      final name = _teamAControllers[i].text.trim();
      final isServer = i + 0 == serverIndex;
      String? position;
      if (_matchType == 'doubles') {
        position = serverTeam == 'A'
            ? (isServer ? 'right' : 'left')
            : (i == 0 ? 'right' : 'left');
      }
      players.add((name: name.isEmpty ? 'Player A${i + 1}' : name, team: 'A', isStartingServer: isServer, position: position));
    }
    for (var i = 0; i < _teamBControllers.length; i++) {
      final name = _teamBControllers[i].text.trim();
      final isServer = (i + _teamAControllers.length) == serverIndex;
      String? position;
      if (_matchType == 'doubles') {
        position = serverTeam == 'B'
            ? (isServer ? 'right' : 'left')
            : (i == 0 ? 'right' : 'left');
      }
      players.add((name: name.isEmpty ? 'Player B${i + 1}' : name, team: 'B', isStartingServer: isServer, position: position));
    }

    try {
      await createMatchInDb(
        ref: ref,
        type: _matchType,
        scoringRule: _scoringRule,
        gameCount: _gameCount,
        playTo: _playTo,
        winBy: _winBy,
        players: players,
      );
      if (mounted) { context.go('/match/live'); }
    } catch (e) {
      // Guard against the State being disposed between the await and the
      // snackbar — without this, navigating back during a slow createMatch
      // would throw an unmounted-context error.
      if (!mounted) return;
      _showError('Failed to create match: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text('New Match'),
        ),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (!_hasUnsavedChanges) { if (context.mounted) { context.go('/'); } return; }
          final confirmed = await showConfirmDialog(
            context,
            title: 'Discard setup?',
            message: 'You have unsaved changes. Leave without saving?',
            confirmLabel: 'Discard',
            isDestructive: true,
          );
          if (confirmed == true && context.mounted) { context.go('/'); }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              _buildMatchTypeSelector(theme),
              const SizedBox(height: 16),
              _buildPlayerNamesSection(theme),
              const SizedBox(height: 16),
              _buildStartingServerSelector(theme),
              const SizedBox(height: 16),
              _buildScoringRuleSelector(theme),
              const SizedBox(height: 16),
              _buildGameCountSelector(theme),
              const SizedBox(height: 16),
              _buildPresetPicker(theme),
              const SizedBox(height: 24),
              _buildStartButton(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchTypeSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: _SectionLabel(icon: Icons.sports_tennis_rounded, label: 'Match Type', theme: theme),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'singles', label: Text('Singles'), icon: Icon(Icons.person)),
            ButtonSegment(value: 'doubles', label: Text('Doubles'), icon: Icon(Icons.people)),
          ],
          selected: {_matchType},
          onSelectionChanged: (selected) {
            setState(() { _matchType = selected.first; _rebuildControllers(); });
          },
        ),
      ],
    );
  }

  Widget _buildPlayerNamesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: _SectionLabel(icon: Icons.group_rounded, label: 'Team A', theme: theme, accentColor: courtGreen),
        ),
        const SizedBox(height: 8),
        ..._buildTeamFields('A', _teamAControllers, theme),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: _SectionLabel(icon: Icons.group_rounded, label: 'Team B', theme: theme, accentColor: courtBlue),
        ),
        const SizedBox(height: 8),
        ..._buildTeamFields('B', _teamBControllers, theme),
      ],
    );
  }

  List<Widget> _buildTeamFields(String team, List<TextEditingController> controllers, ThemeData theme) {
    final focusOffset = team == 'A' ? 0 : _teamAControllers.length;
    return List.generate(controllers.length, (i) {
      return Padding(
        padding: EdgeInsets.only(top: i > 0 ? 8 : 0),
        child: _PlayerNameField(
          controller: controllers[i],
          focusNode: _focusNodes[focusOffset + i],
          hint: team == 'A' ? 'Player A${i + 1}' : 'Player B${i + 1}',
          onChanged: () => setState(() {}),
          theme: theme,
        ),
      );
    });
  }

  Widget _buildStartingServerSelector(ThemeData theme) {
    if (_allPlayerNames.every((n) => n.trim().isEmpty) && !widget.quickStart) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: _SectionLabel(icon: Icons.sports_baseball_rounded, label: 'Starting Server', theme: theme),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 4,
          children: List.generate(_totalPlayerCount, (index) {
            final name = _playerDisplayName(index);
            final isSelected = _startingServerIndex == index;
            final teamColor = _teamForIndex(index) == 'A' ? const Color(0xFF4A8C3F) : const Color(0xFF2B5797);
            return ChoiceChip(
              label: Text(name),
              selected: isSelected,
              // Prevent deselection: once a server is picked, tapping
              // the same chip again is a no-op so the user can't
              // accidentally null out the selection.
              onSelected: (selected) { if (selected) { setState(() { _startingServerIndex = index; }); } },
              selectedColor: teamColor.withValues(alpha: 0.3),
              avatar: Icon(Icons.sports_tennis, size: 16, color: isSelected ? teamColor : theme.colorScheme.outline),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildScoringRuleSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: _SectionLabel(icon: Icons.rule_rounded, label: 'Scoring Rule', theme: theme),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'sideout', label: Text('Side-Out')),
            ButtonSegment(value: 'rally', label: Text('Rally')),
          ],
          selected: {_scoringRule},
          onSelectionChanged: (selected) { setState(() { _scoringRule = selected.first; }); },
        ),
      ],
    );
  }

  Widget _buildGameCountSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: _SectionLabel(icon: Icons.casino_rounded, label: 'Games', theme: theme),
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('1 Game')),
            ButtonSegment(value: 3, label: Text('Best of 3')),
          ],
          selected: {_gameCount},
          onSelectionChanged: (selected) { setState(() { _gameCount = selected.first; }); },
        ),
      ],
    );
  }

  Widget _buildPresetPicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: _SectionLabel(icon: Icons.emoji_events_rounded, label: 'Win Condition', theme: theme),
        ),        const SizedBox(height: 8),
        // The Custom item is synthesized live from the text-field values
        // so the dropdown always shows what the Custom row will produce
        // (e.g. "Custom (13, win by 2)"). Value can no longer be null —
        // a non-nullable separator avoids the empty-dropdown flicker.
        Builder(
          builder: (_) {
            final customValue = _currentCustomPreset();
            return DropdownButtonFormField<ScoringPreset>(
              value: _isCustomPreset ? customValue : _selectedPreset,
              items: [
                ...ScoringPreset.defaults.map(
                  (p) => DropdownMenuItem(value: p, child: Text(p.label)),
                ),
                DropdownMenuItem(
                  value: customValue,
                  child: Text(customValue.label),
                ),
              ],
              onChanged: (preset) {
                if (preset == null) return;
                setState(() {
                  if (preset.isCustom) {
                    _isCustomPreset = true;
                  } else {
                    _isCustomPreset = false;
                    _selectedPreset = preset;
                    // Keep the int fields in sync with the built-in
                    // preset so transitioning out of Custom is a no-op
                    // if the user toggles back.
                    _playTo = preset.playTo;
                    _winBy = preset.winBy;
                  }
                });
              },
            );
          },
        ),
        if (_isCustomPreset) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _customPlayToController,
                decoration: const InputDecoration(labelText: 'Play to'),
                keyboardType: TextInputType.number,
                // The dropdown's selected value is `_currentCustomPreset()`,
                // which reads these controllers. Without an onChanged that
                // calls setState, typing in a custom field would rebuild
                // the items list (new synthesized preset) but leave the
                // selected value untouched, causing DropdownButtonFormField
                // to display an empty / stale label.
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 1 || n > 99) {
                    return 'Enter 1\u201399';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _customWinByController,
                decoration: const InputDecoration(labelText: 'Win by'),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 1 || n > 10) {
                    return 'Enter 1\u201310';
                  }
                  return null;
                },
              ),
            ),
          ]),
        ],
      ],
    );
  }

  Widget _buildStartButton(ThemeData theme) {
    return FilledButton.icon(
      onPressed: _startMatch,
      icon: const Icon(Icons.play_arrow_rounded, size: 28),
      label: const Text('Start Match'),
    );
  }
}

// ── Section Label ──

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;
  final Color? accentColor;

  const _SectionLabel({required this.icon, required this.label, required this.theme, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? theme.colorScheme.onSurface;
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── Autocomplete Player Name Field ──

class _PlayerNameField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final VoidCallback? onChanged;
  final ThemeData theme;

  const _PlayerNameField({required this.controller, required this.focusNode, required this.hint, this.onChanged, required this.theme});

  @override
  State<_PlayerNameField> createState() => _PlayerNameFieldState();
}

class _PlayerNameFieldState extends State<_PlayerNameField> {
  Timer? _debounce;
  Completer<List<String>>? _activeCompleter;

  @override
  void dispose() {
    _debounce?.cancel();
    if (_activeCompleter?.isCompleted == false) {
      _activeCompleter!.complete(const []);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        _debounce?.cancel();
        // Cancel any previous pending search so orphaned completers
        // don't leak or complete after disposal.
        if (_activeCompleter?.isCompleted == false) {
          _activeCompleter!.complete(const []);
        }

        if (textEditingValue.text.isEmpty) return Future.value(const []);

        final completer = Completer<List<String>>();
        _activeCompleter = completer;
        _debounce = Timer(const Duration(milliseconds: 200), () async {
          try {
            if (!mounted) {
              if (!completer.isCompleted) completer.complete(const []);
              return;
            }
            final container = ProviderScope.containerOf(context);
            final db = container.read(databaseProvider);
            final recent = await db.getRecentPlayers();
            if (!mounted) {
              if (!completer.isCompleted) completer.complete(const []);
              return;
            }
            final query = textEditingValue.text.toLowerCase();
            final results = recent
                .where((p) => p.name.toLowerCase().contains(query))
                .map((p) => p.name)
                .toList();
            if (!completer.isCompleted) completer.complete(results);
          } catch (_) {
            if (!completer.isCompleted) completer.complete(const []);
          }
        });

        return completer.future;
      },
      onSelected: (option) {
        widget.controller.text = option;
        widget.onChanged?.call();
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onSubmitted) {
        // Sync the inner controller once on build.
        final initialText = widget.controller.text;
        if (textEditingController.text != initialText) {
          textEditingController.text = initialText;
        }
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: widget.hint,
            prefixIcon: const Icon(Icons.person_outline, size: 20),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (value) {
            widget.controller.text = value;
            widget.onChanged?.call();
          },
        );
      },
    );
  }
}
