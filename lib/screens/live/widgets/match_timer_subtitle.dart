import 'dart:async';

import 'package:flutter/material.dart';

/// AppBar subtitle for the live match screen.
///
/// Shows the scoring rule (Side-Out / Rally), the match type
/// (Singles / Doubles), and an elapsed-time clock that ticks once
/// per second. The widget owns a 1Hz [Timer] internally so the rest
/// of the Live screen doesn't rebuild on every tick — the parent
/// renders this widget as is and the timer only triggers
/// `setState` inside the subtitle's own [State].
class MatchTimerSubtitle extends StatefulWidget {
  final String ruleLabel;
  final bool isDoubles;
  final DateTime createdAt;

  const MatchTimerSubtitle({
    super.key,
    required this.ruleLabel,
    required this.isDoubles,
    required this.createdAt,
  });

  @override
  State<MatchTimerSubtitle> createState() => _MatchTimerSubtitleState();
}

class _MatchTimerSubtitleState extends State<MatchTimerSubtitle> {
  late String _elapsedStr;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _elapsedStr = _formatElapsed(widget.createdAt);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedStr = _formatElapsed(widget.createdAt));
      }
    });
  }

  @override
  void didUpdateWidget(covariant MatchTimerSubtitle old) {
    super.didUpdateWidget(old);
    if (old.createdAt != widget.createdAt) {
      _elapsedStr = _formatElapsed(widget.createdAt);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatElapsed(DateTime startTime) {
    final elapsed = DateTime.now().difference(startTime);
    return '${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      '${widget.ruleLabel} \u2022 ${widget.isDoubles ? "Doubles" : "Singles"} \u2022 $_elapsedStr',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
