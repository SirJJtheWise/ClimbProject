import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A simple stopwatch for timed protocols (7s hangs, lock-off holds,
/// repeaters). If [targetSeconds] is set, the display flashes green once
/// that duration is reached (e.g. the 7-second hang mark).
class HangTimer extends StatefulWidget {
  final int? targetSeconds;
  final ValueChanged<double>? onStop;

  const HangTimer({super.key, this.targetSeconds, this.onStop});

  @override
  State<HangTimer> createState() => _HangTimerState();
}

class _HangTimerState extends State<HangTimer> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  double _elapsedSeconds = 0;

  void _start() {
    _stopwatch.start();
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() => _elapsedSeconds = _stopwatch.elapsedMilliseconds / 1000);
    });
    setState(() {});
  }

  void _stop() {
    _stopwatch.stop();
    _ticker?.cancel();
    setState(() {});
    widget.onStop?.call(_elapsedSeconds);
  }

  void _reset() {
    _stopwatch.reset();
    _ticker?.cancel();
    setState(() => _elapsedSeconds = 0);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hitTarget = widget.targetSeconds != null &&
        _elapsedSeconds >= widget.targetSeconds!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final levels = theme.extension<LevelPalette>()!;
    final running = _stopwatch.isRunning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        // Tints the whole instrument on success, so the signal is visible
        // from arm's length on a hangboard — not just in the digits.
        color: hitTarget ? levels.strongSurface : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: hitTarget ? levels.strong : scheme.outlineVariant,
          width: hitTarget ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Crossfades to green the instant the target is hit — a real
          // "you made it" signal, not a decorative flourish.
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: (theme.textTheme.displayMedium ?? const TextStyle()).copyWith(
              color: hitTarget ? levels.strong : scheme.onSurface,
            ),
            child: Text('${_elapsedSeconds.toStringAsFixed(1)}s'),
          ),
          if (widget.targetSeconds != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _TargetChip(
              targetSeconds: widget.targetSeconds!,
              hit: hitTarget,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          // Both buttons flex rather than sitting at their theme minimum
          // width: at 320dp the two 120dp minimums plus the gap overflow
          // the row, and equal halves read better than a centred pair
          // anyway.
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: running ? _stop : _start,
                  icon: Icon(
                      running ? Icons.stop_rounded : Icons.play_arrow_rounded),
                  label: Text(running ? 'Stop' : 'Start'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  // Nothing to reset before the first tick — a control
                  // that looks tappable but does nothing is worse than a
                  // clearly disabled one.
                  onPressed: _elapsedSeconds == 0 && !running ? null : _reset,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `target: 7s`, which flips to a checked "target reached" state. Both the
/// glyph and the wording change, so the success state doesn't rely on the
/// colour shift alone.
class _TargetChip extends StatelessWidget {
  final int targetSeconds;
  final bool hit;

  const _TargetChip({required this.targetSeconds, required this.hit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levels = theme.extension<LevelPalette>()!;
    final color = hit ? levels.strong : theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hit ? Icons.check_circle_rounded : Icons.flag_outlined,
          size: 16,
          color: color,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          hit ? 'target reached' : 'target: ${targetSeconds}s',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
