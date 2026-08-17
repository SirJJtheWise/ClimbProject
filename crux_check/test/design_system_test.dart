import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crux_check/data/metric_definitions.dart';
import 'package:crux_check/logic/assessment_calculator.dart';
import 'package:crux_check/models/assessment.dart';
import 'package:crux_check/models/enums.dart';
import 'package:crux_check/models/test_result.dart';
import 'package:crux_check/theme/app_theme.dart';
import 'package:crux_check/widgets/hang_timer.dart';
import 'package:crux_check/widgets/level_bar.dart';
import 'package:crux_check/widgets/live_grade_preview.dart';
import 'package:crux_check/widgets/load_calculator.dart';
import 'package:crux_check/widgets/metric_card.dart';

/// Renders the redesigned widgets at the narrowest phone width the app
/// supports, in both brightnesses. `flutter_test` fails a test on any
/// RenderFlex overflow, so these double as regression tests for the
/// spacing/typography changes — the failure mode a colour-and-layout pass
/// is most likely to introduce.
void main() {
  final assessment = Assessment(
    userId: 1,
    date: DateTime(2026, 1, 1),
    gradeComposite: 7.2,
    gradeCeiling: 8.4,
    gradeExperience: 6.1,
    confidenceLow: 6,
    confidenceHigh: 9,
    perMetricPercentiles: const [
      MetricPercentile(
          metricId: MetricId.fingerStrength,
          percentile: 82,
          gradeEquivalent: 8.5),
      MetricPercentile(
          metricId: MetricId.pullingStrength,
          percentile: 51,
          gradeEquivalent: 7.0),
      MetricPercentile(
          metricId: MetricId.core, percentile: 18, gradeEquivalent: 5.2),
      MetricPercentile(
          metricId: MetricId.hipFlexion, percentile: 64, gradeEquivalent: 7.4),
    ],
    limitingFactors: const [
      LimitingFactor(metricId: MetricId.core, deficit: 2.1),
    ],
    missingMetricCount: 3,
  );

  final preview = AssessmentResult(
    assessment: assessment,
    gradesByMetric: const {},
    anchorGrade: 7.2,
    anchorIsFallback: true,
  );

  /// 320dp is narrower than an iPhone SE — if it survives here it survives
  /// on anything shipping.
  Future<void> pumpAtSmallPhone(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(child);
  }

  Widget host(Widget child, Brightness brightness) {
    return MaterialApp(
      theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: child,
        ),
      ),
    );
  }

  for (final brightness in Brightness.values) {
    final mode = brightness.name;

    testWidgets('$mode: LiveGradePreview renders both states', (tester) async {
      await pumpAtSmallPhone(
        tester,
        host(
          const Column(
            children: [
              LiveGradePreview(preview: null, hasAnyTest: false),
              SizedBox(height: AppSpacing.lg),
            ],
          ),
          brightness,
        ),
      );
      expect(find.text('No estimate yet'), findsOneWidget);

      await pumpAtSmallPhone(
        tester,
        host(
          LiveGradePreview(preview: preview, hasAnyTest: true),
          brightness,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('LIVE ESTIMATE'), findsOneWidget);
    });

    testWidgets('$mode: MetricCard renders tested and untested',
        (tester) async {
      final def = MetricDefinitions.all[MetricId.fingerStrength]!;
      await pumpAtSmallPhone(
        tester,
        host(
          Column(
            children: [
              MetricCard(
                def: def,
                latest: TestResult(
                  userId: 1,
                  metricId: MetricId.fingerStrength,
                  date: DateTime(2026, 1, 1),
                  rawValue: 142,
                  unit: '%BW',
                  computedPctBW: 142,
                ),
                percentile: 82,
                onTest: () {},
                onHowTo: () {},
              ),
              MetricCard(
                def: def,
                latest: null,
                onTest: () {},
                onHowTo: () {},
              ),
            ],
          ),
          brightness,
        ),
      );
      expect(find.text('142'), findsOneWidget);
      expect(find.text('%BW'), findsOneWidget);
      expect(find.text('Untested'), findsOneWidget);
    });

    testWidgets('$mode: LevelBar labels every band in words', (tester) async {
      await pumpAtSmallPhone(
        tester,
        host(
          const Column(
            children: [
              LevelBar(label: 'Finger strength', percentile: 18),
              LevelBar(label: 'Pulling strength', percentile: 50),
              LevelBar(label: 'Core', percentile: 91, trailingText: 'V9'),
            ],
          ),
          brightness,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('V9'), findsOneWidget);
    });

    testWidgets('$mode: HangTimer and LoadCalculator render', (tester) async {
      await pumpAtSmallPhone(
        tester,
        host(
          Column(
            children: [
              const HangTimer(targetSeconds: 7),
              const SizedBox(height: AppSpacing.xl),
              LoadCalculator(
                initialBodyWeightKg: 72.5,
                onChanged: (_, _, _) {},
              ),
            ],
          ),
          brightness,
        ),
      );
      expect(find.text('target: 7s'), findsOneWidget);
      expect(find.text('RECORDED AS'), findsOneWidget);
    });
  }

  testWidgets('Reset is disabled until the timer has run', (tester) async {
    await pumpAtSmallPhone(
      tester,
      host(const HangTimer(targetSeconds: 7), Brightness.light),
    );
    final reset = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Reset'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(reset.onPressed, isNull);
  });

  test('both themes carry a LevelPalette for the weak/at-level/strong scale',
      () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      expect(theme.extension<LevelPalette>(), isNotNull);
    }
  });
}
