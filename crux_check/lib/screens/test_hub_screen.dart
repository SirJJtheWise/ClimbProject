import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/metric_definitions.dart';
import '../logic/assessment_calculator.dart';
import '../models/enums.dart';
import '../models/metric_def.dart';
import '../models/test_result.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/live_grade_preview.dart';
import '../widgets/metric_card.dart';
import '../widgets/profile_button.dart';
import '../widgets/protocol_sheet.dart';
import 'test_input_screen.dart';

class TestHubScreen extends StatelessWidget {
  const TestHubScreen({super.key});

  static const _groupTitles = {
    MetricGroup.fingers: 'Fingers',
    MetricGroup.pullPower: 'Pull / Power',
    MetricGroup.core: 'Core',
    MetricGroup.mobility: 'Mobility',
    MetricGroup.body: 'Body',
    MetricGroup.experience: 'Experience',
  };

  TestResult? _latestFor(AppState state, MetricDef def) {
    if (def.id == MetricId.bodyComposition) {
      final bf = state.latestBody?.bodyFatPct;
      if (bf == null) return null;
      return TestResult(
        userId: state.user!.id!,
        metricId: MetricId.bodyComposition,
        date: state.latestBody!.date,
        rawValue: bf,
        unit: '% body fat',
      );
    }
    if (def.id == MetricId.apeIndex) {
      return TestResult(
        userId: state.user!.id!,
        metricId: MetricId.apeIndex,
        date: DateTime.now(),
        rawValue: state.user!.apeIndexCm,
        unit: 'cm',
      );
    }
    return state.latestResults[def.id];
  }

  double? _percentileFor(AssessmentResult? preview, MetricId id) {
    if (preview == null) return null;
    for (final p in preview.assessment.perMetricPercentiles) {
      if (p.metricId == id) return p.percentile;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final preview = state.livePreview;
    final defs = MetricDefinitions.orderedForHub;
    final grouped = <MetricGroup, List<MetricDef>>{};
    for (final d in defs) {
      grouped.putIfAbsent(d.group, () => []).add(d);
    }
    final testedCount = defs.where((d) => _latestFor(state, d) != null).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test hub'),
        actions: const [ProfileButton(), SizedBox(width: AppSpacing.xs)],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.sm,
            AppSpacing.gutter,
            AppSpacing.scrollBottomInset,
          ),
          children: [
            _CoverageBar(tested: testedCount, total: defs.length),
            const SizedBox(height: AppSpacing.lg),
            LiveGradePreview(
              preview: preview,
              hasAnyTest: state.latestResults.isNotEmpty,
            ),
            for (final group in MetricGroup.values)
              if (grouped[group] != null) ...[
                _SectionHeading(
                  title: _groupTitles[group]!,
                  tested: grouped[group]!
                      .where((d) => _latestFor(state, d) != null)
                      .length,
                  total: grouped[group]!.length,
                ),
                for (final def in grouped[group]!)
                  MetricCard(
                    def: def,
                    latest: _latestFor(state, def),
                    percentile: _percentileFor(preview, def.id),
                    onTest: def.id == MetricId.apeIndex
                        ? () => showProtocolSheet(context, def)
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    TestInputScreen(metricId: def.id),
                              ),
                            ),
                    onHowTo: () => showProtocolSheet(context, def),
                  ),
              ],
          ],
        ),
      ),
    );
  }
}

/// "9 of 14 tests recorded" as a filled bar rather than a line of caption
/// text under the title. Completion is the one number that tells you
/// whether the estimate above is worth trusting yet, so it earns a shape.
class _CoverageBar extends StatelessWidget {
  final int tested;
  final int total;

  const _CoverageBar({required this.tested, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: '$tested of $total tests recorded',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$tested of $total tests recorded',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              Text(
                '${(tested / total * 100).round()}%',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: total == 0 ? 0 : tested / total),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: scheme.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation(scheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small-caps group label with its own completion count. Sits at the
/// section tier of the spacing scale (24 above, 12 below) so the gap alone
/// tells you a new group started.
class _SectionHeading extends StatelessWidget {
  final String title;
  final int tested;
  final int total;

  const _SectionHeading({
    required this.title,
    required this.tested,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs, AppSpacing.xl, AppSpacing.xs, AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Text(
            '$tested/$total',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
