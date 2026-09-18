import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/metric_definitions.dart';
import '../models/assessment.dart';
import '../models/enums.dart';
import '../models/test_result.dart';
import '../state/app_state.dart';
import '../utils/grade_format.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_button.dart';

enum _HistorySeries { grade, metric }

/// Shared bottom-axis date labels for the history line charts: one label
/// per data point, thinned out with an interval so they don't collide when
/// there are many sessions.
AxisTitles _dateBottomTitles(BuildContext context, List<DateTime> dates) {
  final style = Theme.of(context).textTheme.bodySmall?.copyWith(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
  final interval = dates.length <= 5 ? 1 : (dates.length / 5).ceil();
  return AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 28,
      interval: interval.toDouble(),
      getTitlesWidget: (value, meta) {
        final i = value.round();
        if (i < 0 || i >= dates.length) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(DateFormat.Md().format(dates[i]), style: style),
        );
      },
    ),
  );
}

/// Shared subtle horizontal grid + hidden chart border, so both history
/// charts read from the same, theme-aware system instead of fl_chart's
/// unstyled grey defaults.
FlGridData _gridData(BuildContext context) => FlGridData(
  drawVerticalLine: false,
  getDrawingHorizontalLine: (_) => FlLine(
    color: Theme.of(context).colorScheme.outlineVariant,
    strokeWidth: 1,
  ),
);

/// Shared line styling: a solid stroke, dots the same colour as the line,
/// and a soft fill beneath it so a sparse series still reads as a trend
/// rather than a few disconnected marks.
LineChartBarData _seriesBar(List<FlSpot> spots, Color color) =>
    LineChartBarData(
      spots: spots,
      isCurved: false,
      color: color,
      barWidth: 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) =>
            FlDotCirclePainter(radius: 4, color: color, strokeWidth: 0),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.12),
      ),
    );

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _HistorySeries _series = _HistorySeries.grade;
  MetricId _selectedMetric = MetricId.fingerStrength;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: const [
          ProfileButton(),
          SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.sm,
            AppSpacing.gutter,
            AppSpacing.gutter,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<_HistorySeries>(
                segments: const [
                  ButtonSegment(
                    value: _HistorySeries.grade,
                    icon: Icon(Icons.landscape_outlined),
                    label: Text('Grade'),
                  ),
                  ButtonSegment(
                    value: _HistorySeries.metric,
                    icon: Icon(Icons.show_chart_rounded),
                    label: Text('Metric'),
                  ),
                ],
                selected: {_series},
                onSelectionChanged: (s) => setState(() => _series = s.first),
              ),
              if (_series == _HistorySeries.metric) ...[
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<MetricId>(
                  initialValue: _selectedMetric,
                  decoration: const InputDecoration(labelText: 'Metric'),
                  items: MetricDefinitions.orderedForHub
                      .map(
                        (d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(d.shortName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedMetric = v ?? _selectedMetric),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xl,
                      AppSpacing.xl,
                      AppSpacing.md,
                    ),
                    child: _series == _HistorySeries.grade
                        ? _GradeHistoryChart(appState: appState)
                        : _MetricHistoryChart(
                            appState: appState,
                            metricId: _selectedMetric,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Consistent "nothing here yet" treatment for both charts — an icon, a
/// one-line reason, and no chart frame, so an empty state never looks like
/// a chart that failed to draw.
class _ChartEmptyState extends StatelessWidget {
  final String message;

  const _ChartEmptyState(this.message);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timeline_rounded,
              size: 36,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeHistoryChart extends StatelessWidget {
  final AppState appState;

  const _GradeHistoryChart({required this.appState});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Assessment>>(
      future: appState.assessmentHistory(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return const _ChartEmptyState(
            'No assessments recorded yet.\nCalculate a grade on the Results '
            'tab to start the line.',
          );
        }
        final theme = Theme.of(context);
        final spots = [
          for (var i = 0; i < data.length; i++)
            FlSpot(i.toDouble(), data[i].gradeComposite),
        ];
        return LineChart(
          LineChartData(
            minY: 0,
            maxY: 17,
            gridData: _gridData(context),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (v, meta) => Text(
                    context.grade(v),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              bottomTitles: _dateBottomTitles(
                context,
                data.map((a) => a.date).toList(),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            lineBarsData: [_seriesBar(spots, theme.colorScheme.primary)],
          ),
        );
      },
    );
  }
}

class _MetricHistoryChart extends StatelessWidget {
  final AppState appState;
  final MetricId metricId;

  const _MetricHistoryChart({required this.appState, required this.metricId});

  @override
  Widget build(BuildContext context) {
    final def = MetricDefinitions.all[metricId]!;
    return FutureBuilder<List<TestResult>>(
      future: appState.testHistory(metricId),
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return _ChartEmptyState(
            'No ${def.shortName} tests recorded yet.\nRecord one in the Test '
            'hub to start the line.',
          );
        }
        final theme = Theme.of(context);
        final spots = [
          for (var i = 0; i < data.length; i++)
            FlSpot(i.toDouble(), data[i].computedPctBW ?? data[i].rawValue),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: Text(
                '${def.shortName} · ${def.unit}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: _gridData(context),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (v, meta) => Text(
                          v.toStringAsFixed(0),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: _dateBottomTitles(
                      context,
                      data.map((r) => r.date).toList(),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    _seriesBar(spots, theme.colorScheme.secondary),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
