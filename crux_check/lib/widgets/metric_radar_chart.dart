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

  /// Axis names around the outside. Turn off below roughly 200dp: metric
  /// names like "Pulling strength" are wider than the radius there and
  /// overlap the plot itself, which makes the shape harder to read rather
  /// than easier. The full-size chart on Results keeps them.
  final bool showLabels;

  const MetricRadarChart({
    super.key,
    required this.axes,
    this.color,
    this.showLabels = true,
  });

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
        label: 'Strength profile: '
            '${axes.map((a) => '${a.label} ${a.percentile.round()}th percentile').join(', ')}',
        excludeSemantics: true,
        child: RadarChart(
          RadarChartData(
            radarShape: RadarShape.polygon,
            tickCount: 4,
            ticksTextStyle:
                const TextStyle(color: Colors.transparent, fontSize: 0),
            radarBorderData: BorderSide(color: ink.withValues(alpha: 0.35)),
            gridBorderData: BorderSide(color: ink.withValues(alpha: 0.2)),
            titleTextStyle: showLabels
                ? theme.textTheme.labelSmall
                    ?.copyWith(color: ink, letterSpacing: 0.2)
                : const TextStyle(color: Colors.transparent, fontSize: 0),
            titlePositionPercentageOffset: showLabels ? 0.18 : 0,
            getTitle: (index, angle) {
              return RadarChartTitle(
                  text: showLabels ? axes[index].label : '');
            },
            dataSets: [
              RadarDataSet(
                fillColor: ink.withValues(alpha: 0.22),
                borderColor: ink,
                borderWidth: 2,
                entryRadius: 3,
                dataEntries:
                    axes.map((a) => RadarEntry(value: a.percentile)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
