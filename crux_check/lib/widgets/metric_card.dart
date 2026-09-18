import 'package:flutter/material.dart';

import '../data/fun_levels.dart';
import '../models/metric_def.dart';
import '../models/test_result.dart';
import '../theme/app_theme.dart';
import '../utils/level_color.dart';

/// One row in the Test hub: status, the recorded value, and where that
/// value puts you relative to your predicted grade.
///
/// The recorded number is the reason this row exists, so it gets the
/// strongest weight in the layout; the fun-level badge sits under it as
/// supporting colour, and the whole card is one tap target with a separate
/// 48dp "how to test" control.
class MetricCard extends StatelessWidget {
  final MetricDef def;
  final TestResult? latest;
  final double? percentile;
  final VoidCallback onTest;
  final VoidCallback onHowTo;

  const MetricCard({
    super.key,
    required this.def,
    required this.latest,
    this.percentile,
    required this.onTest,
    required this.onHowTo,
  });

  /// The figure and its unit, kept apart. Units in this app range from
  /// `%BW` to `cm (span - height)`, so a single "3.0 level (0-9)" string
  /// either overflows the row or squeezes the metric name to nothing —
  /// stacking them keeps the number scannable at any unit length.
  (String, String) get _value {
    final r = latest!;
    final pct = r.computedPctBW;
    return pct != null
        ? (pct.toStringAsFixed(0), '%BW')
        : (r.rawValue.toStringAsFixed(1), def.unit);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tested = latest != null;
    final band = percentile == null
        ? null
        : LevelBand.forPercentile(percentile!);
    final level = percentile == null
        ? null
        : FunLevels.levelForPercentile(percentile!);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTest,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _StatusDot(tested: tested),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              def.shortName,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            flex: 2,
                            child: tested
                                ? _ValueLabel(
                                    figure: _value.$1,
                                    unit: _value.$2,
                                  )
                                : Text(
                                    'Untested',
                                    textAlign: TextAlign.right,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      if (band != null && level != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _LevelChip(band: band, level: level),
                      ],
                    ],
                  ),
                ),
                if (percentile != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _SideScaleBar(percentile: percentile!),
                ],
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'How to test ${def.shortName}',
                  onPressed: onHowTo,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The recorded figure, with its unit set beneath it in a quieter style.
/// Right-aligned so every card's numbers line up down the list even when
/// the metric names differ in length.
class _ValueLabel extends StatelessWidget {
  final String figure;
  final String unit;

  const _ValueLabel({required this.figure, required this.unit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          figure,
          textAlign: TextAlign.right,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          unit,
          textAlign: TextAlign.right,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

/// The percentile as a vertical fill rather than a number — a scale you
/// can read at arm's length across a whole list of cards, the way the
/// [_LevelChip] text can't be. Sits at the trailing edge of the row, next
/// to the info button, so it reads as "how full is this bar" rather than
/// competing with the value column for the same space.
class _SideScaleBar extends StatelessWidget {
  final double percentile;

  const _SideScaleBar({required this.percentile});

  @override
  Widget build(BuildContext context) {
    final band = LevelBand.forPercentile(percentile);
    final color = band.color(context);
    final fraction = (percentile / 100).clamp(0.0, 1.0);

    return Semantics(
      label: '${band.label}, ${percentile.round()}th percentile',
      excludeSemantics: true,
      child: SizedBox(
        width: 8,
        height: 40,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          child: Container(
            color: band.surface(context),
            alignment: Alignment.bottomCenter,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => FractionallySizedBox(
                heightFactor: value,
                widthFactor: 1,
                child: ColoredBox(color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tested/untested at a glance. The glyph carries the meaning, the fill
/// only reinforces it — an untested row reads as a quiet outline rather
/// than a competing coloured badge.
class _StatusDot extends StatelessWidget {
  final bool tested;

  const _StatusDot({required this.tested});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tested ? scheme.primaryContainer : Colors.transparent,
        border: tested ? null : Border.all(color: scheme.outlineVariant),
      ),
      child: Icon(
        tested ? Icons.check_rounded : Icons.remove_rounded,
        size: 20,
        color: tested ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
      ),
    );
  }
}

/// `Lvl 5 · The Friction Physicist`, tinted by band. The band word is
/// carried by [Semantics] so a screen reader gets the meaning the colour
/// is expressing to sighted users.
class _LevelChip extends StatelessWidget {
  final LevelBand band;
  final int level;

  const _LevelChip({required this.band, required this.level});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = band.color(context);
    return Semantics(
      label: '${band.label}, level $level, ${FunLevels.nameForLevel(level)}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: band.surface(context),
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(band.icon, size: 12, color: color),
                const SizedBox(width: 4),
                Text(
                  'Lvl $level',
                  style: theme.textTheme.labelSmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              FunLevels.nameForLevel(level),
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
