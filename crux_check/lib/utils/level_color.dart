import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Where a metric sits relative to the grade the user is predicted to
/// climb: below it, at it, or above it.
enum LevelBand {
  weak,
  atLevel,
  strong;

  static LevelBand forPercentile(double percentile) {
    if (percentile < 35) return LevelBand.weak;
    if (percentile > 65) return LevelBand.strong;
    return LevelBand.atLevel;
  }

  /// Short text label. Colour alone can't carry this meaning — roughly 1
  /// in 12 men can't separate the red from the green — so every place that
  /// tints by band also shows this word or [icon].
  String get label => switch (this) {
        LevelBand.weak => 'Weak spot',
        LevelBand.atLevel => 'At level',
        LevelBand.strong => 'Strength',
      };

  IconData get icon => switch (this) {
        LevelBand.weak => Icons.trending_down,
        LevelBand.atLevel => Icons.trending_flat,
        LevelBand.strong => Icons.trending_up,
      };
}

/// The single red/amber/green semantic scale for "how strong is this
/// metric relative to where you're predicted to climb" — shared by every
/// widget that visualizes a percentile (LevelBar, MetricCard's fun-level
/// badge) so the colour meaning stays consistent across the app.
///
/// Resolved from the theme rather than from `Colors.*`, so the dark theme
/// gets shades that actually clear 4.5:1 on dark surfaces instead of
/// reusing the light-mode ones.
extension LevelBandColors on LevelBand {
  Color color(BuildContext context) {
    final p = Theme.of(context).extension<LevelPalette>()!;
    return switch (this) {
      LevelBand.weak => p.weak,
      LevelBand.atLevel => p.atLevel,
      LevelBand.strong => p.strong,
    };
  }

  /// Tinted background for badges and progress tracks. A solid token, not
  /// the foreground at low alpha — alpha over an unknown parent surface
  /// makes the resulting contrast unpredictable.
  Color surface(BuildContext context) {
    final p = Theme.of(context).extension<LevelPalette>()!;
    return switch (this) {
      LevelBand.weak => p.weakSurface,
      LevelBand.atLevel => p.atLevelSurface,
      LevelBand.strong => p.strongSurface,
    };
  }
}

Color levelColorForPercentile(BuildContext context, double percentile) =>
    LevelBand.forPercentile(percentile).color(context);
