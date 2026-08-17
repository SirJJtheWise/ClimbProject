import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/level_color.dart';

/// A horizontal percentile bar, colour-coded by [LevelBand]: red =
/// weakness (<35th percentile relative to predicted grade), amber =
/// at-level, green = strength (>65th).
///
/// The band is also spelled out in words next to the bar. Colour is a
/// fast second channel here, never the only one.
class LevelBar extends StatelessWidget {
  final String label;
  final double percentile;
  final String? trailingText;

  const LevelBar({
    super.key,
    required this.label,
    required this.percentile,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final band = LevelBand.forPercentile(percentile);
    final color = band.color(context);
    final fraction = (percentile / 100).clamp(0.0, 1.0);

    return Semantics(
      container: true,
      label: '$label, ${band.label}, ${percentile.round()}th percentile'
          '${trailingText == null ? '' : ', $trailingText'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(band.icon, size: 16, color: color),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  trailingText ?? '${percentile.round()}th pct',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              // Animates the fill on every value change (new test saved,
              // assessment recalculated) so the bar visibly reports "this
              // number just moved" instead of snapping between states.
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: band.surface(context),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
