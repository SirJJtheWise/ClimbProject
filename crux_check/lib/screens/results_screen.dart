import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/metric_definitions.dart';
import '../models/assessment.dart';
import '../state/app_state.dart';
import '../utils/grade_format.dart';
import '../theme/app_theme.dart';
import '../widgets/level_bar.dart';
import '../widgets/metric_radar_chart.dart';
import '../widgets/profile_button.dart';
import '../widgets/support_card.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _calculating = false;

  Future<void> _calculate(AppState appState) async {
    setState(() => _calculating = true);
    try {
      await appState.runAssessment();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not calculate assessment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _calculating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final assessment = appState.latestAssessment;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        actions: const [
          ProfileButton(),
          SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        top: false,
        child: assessment == null
            ? _EmptyState(
                calculating: _calculating,
                onCalculate: () => _calculate(appState),
              )
            : RefreshIndicator(
                onRefresh: () => _calculate(appState),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.sm,
                    AppSpacing.gutter,
                    AppSpacing.scrollBottomInset,
                  ),
                  children: [
                    _GradeHeader(assessment: assessment),
                    const SizedBox(height: AppSpacing.xl),
                    _CeilingVsExperience(assessment: assessment),
                    if (assessment.limitingFactors.isNotEmpty) ...[
                      const _SectionHeading('Your top limiters'),
                      ...assessment.limitingFactors.map(
                        (f) => _LimiterCard(factor: f, assessment: assessment),
                      ),
                    ],
                    const _SectionHeading('Profile'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            MetricRadarChart(
                              axes: assessment.perMetricPercentiles
                                  .map(
                                    (p) => RadarAxis(
                                      MetricDefinitions
                                          .all[p.metricId]!
                                          .shortName,
                                      p.percentile,
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const Divider(height: AppSpacing.lg),
                            ...assessment.perMetricPercentiles.map(
                              (p) => LevelBar(
                                label: MetricDefinitions
                                    .all[p.metricId]!
                                    .shortName,
                                percentile: p.percentile,
                                trailingText: context.grade(p.gradeEquivalent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    OutlinedButton.icon(
                      onPressed: _calculating
                          ? null
                          : () => _calculate(appState),
                      icon: _calculating
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded),
                      label: Text(
                        _calculating
                            ? 'Calculating…'
                            : 'Recalculate with latest tests',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Last calculated '
                      '${DateFormat.yMMMd().add_jm().format(assessment.date.toLocal())}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const SupportCard(),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Shared small-caps section label, matching the Test hub's rhythm so the
/// two scrolling screens feel like one app.
class _SectionHeading extends StatelessWidget {
  final String title;

  const _SectionHeading(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool calculating;
  final VoidCallback onCalculate;

  const _EmptyState({required this.calculating, required this.onCalculate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer,
              ),
              child: Icon(
                Icons.insights_rounded,
                size: 40,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('No grade estimate yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            // Capped measure: a full-width paragraph is unreadable on a
            // tablet, and this is the first sentence a new user reads.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                'Record at least a finger-strength or pulling-strength test in '
                'the Test hub, then calculate your grade estimate here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: calculating ? null : onCalculate,
              child: Text(calculating ? 'Calculating…' : 'Calculate my grade'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The payoff. Solid forest on cream — the single loudest surface in the
/// app, because this one number is what the whole product exists to
/// produce.
class _GradeHeader extends StatelessWidget {
  final Assessment assessment;

  const _GradeHeader({required this.assessment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxl,
        horizontal: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Column(
        children: [
          Text(
            'YOUR GRADE RANGE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onPrimary,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.gradeRange(
              assessment.confidenceLow,
              assessment.confidenceHigh,
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'most likely ${context.grade(assessment.gradeComposite)}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.gradeRangeAlternate(
              assessment.confidenceLow,
              assessment.confidenceHigh,
            ),
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onPrimary),
          ),
          if (assessment.gradeComposite > 10) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.onPrimary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppTheme.controlRadius),
              ),
              child: Text(
                'Physical predictors explain less of the picture above V11 — '
                'this range is wider than a lower-grade estimate would be.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CeilingVsExperience extends StatelessWidget {
  final Assessment assessment;

  const _CeilingVsExperience({required this.assessment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = assessment.gradeCeiling - assessment.gradeExperience;
    final (IconData icon, String note) = switch (diff) {
      > 0.75 => (
        Icons.fitness_center_rounded,
        "Your fingers/body support a higher grade than your experience "
            "suggests you're climbing — technique and mileage are likely your "
            "limiter. Climb more, especially outdoors.",
      ),
      < -0.75 => (
        Icons.trending_up_rounded,
        'You climb above your raw physical numbers — targeted strength '
            'training would likely raise your ceiling further.',
      ),
      _ => (
        Icons.balance_rounded,
        'Your physical ceiling and climbing experience are well matched.',
      ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _MarkerStat(
                      label: 'Physical ceiling',
                      grade: assessment.gradeCeiling,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _MarkerStat(
                      label: 'Experience-typical',
                      grade: assessment.gradeComposite,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    note,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkerStat extends StatelessWidget {
  final String label;
  final double grade;

  const _MarkerStat({required this.label, required this.grade});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.grade(grade),
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

/// A metric that is holding the grade estimate down.
///
/// Painted on the level scale's solid "weak" surface rather than
/// `errorContainer` at 40% alpha: compositing a container colour over an
/// unknown parent and then writing full-strength `onErrorContainer` on top
/// makes the resulting contrast unverifiable. Solid token, body text in
/// `onSurface`, accent colour reserved for the icon and figure.
class _LimiterCard extends StatelessWidget {
  final LimitingFactor factor;
  final Assessment assessment;

  const _LimiterCard({required this.factor, required this.assessment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final levels = theme.extension<LevelPalette>()!;
    final def = MetricDefinitions.all[factor.metricId]!;
    final metricGrade = assessment.perMetricPercentiles
        .firstWhere((p) => p.metricId == factor.metricId)
        .gradeEquivalent;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: levels.weakSurface,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: levels.weak.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.trending_down_rounded, color: levels.weak),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          def.shortName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        context.grade(metricGrade),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: levels.weak,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    // Says what the number is rather than what we wish it
                    // were: `deficit` is the gap to your average result, not
                    // the grades you would gain by fixing this. Under a
                    // Softmin those differ a lot (see Weakness Analysis in
                    // the spec). Also keeps the metric name cased — lowercasing
                    // turned "RFD / contact" into "rfd / contact".
                    '${def.shortName} is about '
                    '${factor.deficit.toStringAsFixed(1)} grades below your '
                    'average result. Your physical ceiling is '
                    '${context.grade(assessment.gradeCeiling)}.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
