import 'package:flutter/material.dart';

import '../data/metric_definitions.dart';
import '../logic/assessment_calculator.dart';
import '../logic/grade_conversion.dart';
import '../theme/app_theme.dart';
import 'metric_radar_chart.dart';

/// A compact, always-current star plot + predicted grade, shown at the top
/// of the Test hub. Recomputes from [AppState.livePreview] on every
/// rebuild, so it visibly updates the moment a new test result is saved —
/// no explicit "calculate" step required.
///
/// This is the one element on the screen that answers "so what grade am
/// I?", so it gets the only filled forest surface in the app. Everything
/// below it is cream, which makes the hierarchy unambiguous without a
/// single extra line of chrome.
class LiveGradePreview extends StatelessWidget {
  final AssessmentResult? preview;
  final bool hasAnyTest;

  const LiveGradePreview({
    super.key,
    required this.preview,
    required this.hasAnyTest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (!hasAnyTest || preview == null) {
      return _PreviewShell(
        child: Row(
          children: [
            Icon(Icons.auto_graph_rounded,
                color: scheme.onPrimaryContainer, size: 28),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No estimate yet',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Record any test below and your grade estimate appears '
                    'here instantly.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final assessment = preview!.assessment;
    final axes = assessment.perMetricPercentiles
        .map((p) => RadarAxis(
              MetricDefinitions.all[p.metricId]!.shortName,
              p.percentile,
            ))
        .toList();

    return _PreviewShell(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 132 for the plot + 16 gap + ~150 before "V6-V9" starts
          // wrapping. Above that the side-by-side layout is both tighter
          // and easier to scan; below it (small phones, large text) the
          // two halves are stacked rather than crushed.
          final stacked = constraints.maxWidth < 300;
          final chart = SizedBox(
            width: stacked ? double.infinity : 132,
            height: 132,
            child: MetricRadarChart(
              axes: axes,
              color: scheme.onPrimaryContainer,
              // Unlabelled at this size — it reads as "the shape of you",
              // and the labelled version lives on the Results tab.
              showLabels: false,
            ),
          );
          final summary = _Summary(preview: preview!);

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                summary,
                const SizedBox(height: AppSpacing.lg),
                chart,
              ],
            );
          }
          return Row(
            children: [
              chart,
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: summary),
            ],
          );
        },
      ),
    );
  }
}

/// The filled forest-green container both states share.
class _PreviewShell extends StatelessWidget {
  final Widget child;

  const _PreviewShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: child,
    );
  }
}

class _Summary extends StatelessWidget {
  final AssessmentResult preview;

  const _Summary({required this.preview});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final assessment = preview.assessment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'LIVE ESTIMATE',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onPrimaryContainer,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Crossfades whenever the estimate itself changes (a new test just
        // moved the number) — the one moment on this screen actually worth
        // signaling with motion.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: Text(
            vRangeLabel(assessment.confidenceLow, assessment.confidenceHigh),
            key: ValueKey(
                '${assessment.confidenceLow}-${assessment.confidenceHigh}'),
            style: theme.textTheme.headlineMedium
                ?.copyWith(color: scheme.onPrimaryContainer),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'most likely ${vGradeLabel(assessment.gradeComposite)}',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: scheme.onPrimaryContainer),
        ),
        if (preview.anchorIsFallback) ...[
          const SizedBox(height: AppSpacing.md),
          // Rendered as its own surface rather than red text on green:
          // error-coloured text on a primaryContainer background is a
          // contrast gamble, and this is a nudge, not a failure.
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.controlRadius),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Rough — add a finger or pulling strength test to anchor '
                    'this.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
