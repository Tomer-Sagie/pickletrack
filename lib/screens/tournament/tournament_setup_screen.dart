import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/scoring_preset.dart';
import '../../models/tournament.dart';
import '../../providers/database_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../services/tournament_service.dart';
import '../../theme/colors.dart';
import '../../widgets/confirm_dialog.dart';
import 'dart:convert';

class TournamentSetupScreen extends ConsumerStatefulWidget {
  const TournamentSetupScreen({super.key});

  @override
  ConsumerState<TournamentSetupScreen> createState() =>
      _TournamentSetupScreenState();
}

class _TournamentSetupScreenState
    extends ConsumerState<TournamentSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Tournament');
  final List<TextEditingController> _playerControllers = [];
  TournamentFormat _format = TournamentFormat.singleElim;
  ScoringPreset _preset = ScoringPreset.standard;
  bool _isCustomPreset = false;
  final _customPlayToController = TextEditingController(text: '11');
  final _customWinByController = TextEditingController(text: '2');
  String _matchType = 'singles';
  String _scoringRule = 'sideout';
  int _gameCount = 1;
  int _playerCount = 4;

  @override
  void initState() {
    super.initState();
    _rebuildControllers();
  }

  void _rebuildControllers() {
    final oldTexts = _playerControllers.map((c) => c.text).toList();
    for (final c in _playerControllers) {
      c.dispose();
    }
    _playerControllers.clear();
    for (var i = 0; i < _playerCount; i++) {
      _playerControllers.add(TextEditingController(
        text: i < oldTexts.length ? oldTexts[i] : '',
      ));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _playerControllers) {
      c.dispose();
    }
    _customPlayToController.dispose();
    _customWinByController.dispose();
    super.dispose();
  }

  int get _playTo =>
      _isCustomPreset ? int.tryParse(_customPlayToController.text) ?? 11 : _preset.playTo;
  int get _winBy =>
      _isCustomPreset ? int.tryParse(_customWinByController.text) ?? 2 : _preset.winBy;

  bool get _hasUnsavedChanges {
    if (_nameController.text != 'Tournament') return true;
    if (_playerControllers.any((c) => c.text.isNotEmpty)) return true;
    if (_format != TournamentFormat.singleElim) return true;
    if (_matchType != 'singles') return true;
    return false;
  }

  Future<void> _createTournament() async {
    if (!_formKey.currentState!.validate()) return;

    final names = _playerControllers.map((c) => c.text.trim()).toList();
    final filledNames = names.where((n) => n.isNotEmpty).length;
    if (filledNames < 2) {
      _showError('Please enter at least 2 player names.');
      return;
    }

    try {
      final db = ref.read(databaseProvider);

      // Build seeded players
      final players = <TournamentPlayer>[];
      for (var i = 0; i < names.length; i++) {
        players.add(TournamentPlayer(
          name: names[i].isNotEmpty ? names[i] : 'Player ${i + 1}',
          seed: i + 1,
        ));
      }

      // Generate bracket
      final bracket = TournamentService.generateBracket(_format, players);
      final playersJson =
          jsonEncode(players.map((p) => p.toJson()).toList());
      final bracketJson = bracket.toJsonString();

      // Save to DB
      final id = await db.createTournament(
        name: _nameController.text.trim().isEmpty
            ? 'Tournament'
            : _nameController.text.trim(),
        format: _format.json,
        type: _matchType,
        scoringRule: _scoringRule,
        playTo: _playTo,
        winBy: _winBy,
        gameCount: _gameCount,
        playersJson: playersJson,
        bracketJson: bracketJson,
      );

      // Record player names for autocomplete
      for (final name in names) {
        if (name.isNotEmpty && !name.startsWith('Player ')) {
          await db.recordPlayer(name);
        }
      }

      ref.invalidate(tournamentsProvider);
      if (mounted) {
        context.go('/tournament/$id');
      }
    } catch (e) {
      if (mounted) _showError('Failed to create tournament: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Tournament'),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (!_hasUnsavedChanges) {
            if (context.mounted) context.go('/');
            return;
          }
          final confirmed = await showConfirmDialog(
            context,
            title: 'Discard setup?',
            message: 'You have unsaved changes. Leave without saving?',
            confirmLabel: 'Discard',
            isDestructive: true,
          );
          if (confirmed == true && context.mounted) context.go('/');
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              _buildNameField(theme),
              const SizedBox(height: 24),
              _buildFormatSelector(theme),
              const SizedBox(height: 24),
              _buildMatchTypeSelector(theme),
              const SizedBox(height: 24),
              _buildPlayerCountSelector(theme),
              const SizedBox(height: 24),
              _buildPlayerNamesSection(theme),
              const SizedBox(height: 24),
              _buildScoringRuleSelector(theme),
              const SizedBox(height: 24),
              _buildGameCountSelector(theme),
              const SizedBox(height: 24),
              _buildPresetPicker(theme),
              const SizedBox(height: 32),
              _buildCreateButton(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: _SectionLabel(
            icon: Icons.emoji_events_rounded,
            label: 'Tournament Name',
            theme: theme,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Tournament name',
            prefixIcon: Icon(Icons.label_outline, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: _SectionLabel(
            icon: Icons.account_tree_rounded,
            label: 'Format',
            theme: theme,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: TournamentFormat.values.map((f) {
            final isSelected = _format == f;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => setState(() => _format = f),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        f == TournamentFormat.singleElim
                            ? Icons.sports_tennis_rounded
                            : f == TournamentFormat.doubleElim
                                ? Icons.repeat_rounded
                                : Icons.loop_rounded,
                        size: 22,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.label,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              f == TournamentFormat.singleElim
                                  ? 'Lose once and you\'re out'
                                  : f == TournamentFormat.doubleElim
                                      ? 'Two losses to be eliminated'
                                      : 'Everyone plays everyone',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle,
                            color: theme.colorScheme.primary, size: 22),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMatchTypeSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: _SectionLabel(
            icon: Icons.sports_tennis_rounded,
            label: 'Match Type',
            theme: theme,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'singles', label: Text('Singles'), icon: Icon(Icons.person)),
            ButtonSegment(value: 'doubles', label: Text('Doubles'), icon: Icon(Icons.people)),
          ],
          selected: {_matchType},
          onSelectionChanged: (selected) => setState(() => _matchType = selected.first),
        ),
      ],
    );
  }

  Widget _buildPlayerCountSelector(ThemeData theme) {
    final counts = _format == TournamentFormat.roundRobin
        ? [3, 4, 5, 6, 7, 8]
        : [2, 4, 8, 16];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: _SectionLabel(
            icon: Icons.group_rounded,
            label: 'Players',
            theme: theme,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: counts.map((count) {
            final isSelected = _playerCount == count;
            return ChoiceChip(
              label: Text('$count players'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _playerCount = count;
                    _rebuildControllers();
                  });
                }
              },
              selectedColor: theme.colorScheme.primaryContainer,
            );
          }).toList(),
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
          child: _SectionLabel(
            icon: Icons.person_outline,
            label: 'Player Names (seeds 1-$_playerCount)',
            theme: theme,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Seed 1 plays the lowest seed first. Empty names use "Player N".',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(_playerCount, (i) {
          return Padding(
            padding: EdgeInsets.only(top: i > 0 ? 8 : 0),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: i == 0
                        ? courtGreen.withValues(alpha: 0.15)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: i == 0 ? courtGreen : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _playerControllers[i],
                    decoration: InputDecoration(
                      labelText: 'Player ${i + 1}',
                      prefixIcon: const Icon(Icons.person_outline, size: 18),
                      isDense: true,
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildScoringRuleSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: _SectionLabel(
            icon: Icons.rule_rounded,
            label: 'Scoring Rule',
            theme: theme,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'sideout', label: Text('Side-Out')),
            ButtonSegment(value: 'rally', label: Text('Rally')),
          ],
          selected: {_scoringRule},
          onSelectionChanged: (selected) =>
              setState(() => _scoringRule = selected.first),
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
          child: _SectionLabel(
            icon: Icons.casino_rounded,
            label: 'Match Format',
            theme: theme,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('1 Game')),
            ButtonSegment(value: 3, label: Text('Best of 3')),
          ],
          selected: {_gameCount},
          onSelectionChanged: (selected) =>
              setState(() => _gameCount = selected.first),
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
          child: _SectionLabel(
            icon: Icons.score_rounded,
            label: 'Win Condition',
            theme: theme,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ScoringPreset>(
          value: _isCustomPreset ? null : _preset,
          items: [
            ...ScoringPreset.defaults.map((p) =>
                DropdownMenuItem(value: p, child: Text(p.label))),
            const DropdownMenuItem(value: null, child: Text('Custom...')),
          ],
          onChanged: (preset) {
            setState(() {
              if (preset != null) {
                _isCustomPreset = false;
                _preset = preset;
              } else {
                _isCustomPreset = true;
              }
            });
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
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 1 || n > 99) return 'Enter 1–99';
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
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 1 || n > 10) return 'Enter 1–10';
                  return null;
                },
              ),
            ),
          ]),
        ],
      ],
    );
  }

  Widget _buildCreateButton(ThemeData theme) {
    return FilledButton.icon(
      onPressed: _createTournament,
      icon: const Icon(Icons.emoji_events_rounded, size: 28),
      label: const Text('Create Tournament'),
    );
  }
}

// ── Section Label ──

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;

  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
