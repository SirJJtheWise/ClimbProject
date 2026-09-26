import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class RadarAxis {
  final String label;
  final double percentile;

  const RadarAxis(this.label, this.percentile);
}

/// Spider/radar chart across metric axes, each axis a 0-100 percentile
/// relative to the predicted grade.
class MetricRadarChart extends StatelessWidget {
  final List<RadarAxis> axes;

  /// Ink colour for the web, fill, and labels. Defaults to the forest
  /// accent; the Test hub's hero card passes `onPrimaryContainer` because
  /// the accent itself would sit on its own container there.
  final Color? color;

  const MetricRadarChart({super.key, required this.axes, this.color});

  @override
  Widget build(BuildContext context) {
    // A radar/star shape needs at least 3 axes to form a polygon; with 1-2
    // points fl_chart just draws a degenerate line, which reads as a
    // rendering bug rather than "not enough data yet". Say that plainly
    // instead.
    final theme = Theme.of(context);
    final ink = color ?? theme.colorScheme.primary;

    if (axes.length < 3) {
      final remaining = 3 - axes.length;
      return AspectRatio(
        aspectRatio: 1,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.radar_rounded, color: ink, size: 28),
                const SizedBox(height: 8),
                Text(
                  axes.isEmpty
                      ? 'Add tests to see your shape'
                      : 'Add $remaining more test${remaining == 1 ? '' : 's'} to see your shape',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: ink),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: Semantics(
        label:
            'Strength profile: '
            '${axes.map((a) => '${a.label} ${a.percentile.round()}th percentile').join(', ')}',
        excludeSemantics: true,
        child: RadarChart(
          RadarChartData(
            radarShape: RadarShape.polygon,
            tickCount: 4,
            ticksTextStyle: const TextStyle(
              color: Colors.transparent,
              fontSize: 0,
            ),
            // No axis titles. fl_chart draws them past the polygon without
            // clipping or wrapping, so any name long enough to read either
            // breaks out of the card or lands on its own data point — there
            // is no offset that avoids both. The LevelBar list directly
            // below names every axis with its grade, so nothing is lost.
            titleTextStyle: const TextStyle(
              color: Colors.transparent,
              fontSize: 0,
            ),
            titlePositionPercentageOffset: 0,
            getTitle: (index, angle) => const RadarChartTitle(text: ''),
            radarBorderData: BorderSide(color: ink.withValues(alpha: 0.35)),
            gridBorderData: BorderSide(color: ink.withValues(alpha: 0.2)),
            dataSets: [
              RadarDataSet(
                fillColor: ink.withValues(alpha: 0.22),
                borderColor: ink,
                borderWidth: 2,
                entryRadius: 3,
                dataEntries: axes
                    .map((a) => RadarEntry(value: a.percentile))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
