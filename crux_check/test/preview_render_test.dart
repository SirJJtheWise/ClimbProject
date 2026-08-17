@Tags(['preview'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:crux_check/data/metric_definitions.dart';
import 'package:crux_check/logic/assessment_calculator.dart';
import 'package:crux_check/models/assessment.dart';
import 'package:crux_check/models/enums.dart';
import 'package:crux_check/models/test_result.dart';
import 'package:crux_check/screens/test_input_screen.dart';
import 'package:crux_check/state/app_state.dart';
import 'package:crux_check/theme/app_theme.dart';
import 'package:crux_check/widgets/level_bar.dart';
import 'package:crux_check/widgets/live_grade_preview.dart';
import 'package:crux_check/widgets/metric_card.dart';

/// Renders representative screens to PNG so the design can be reviewed as
/// an image rather than inferred from code. Tagged `preview` and excluded
/// from the default run (see dart_test.yaml) — regenerate deliberately
/// with:
///
///     flutter test --tags preview --update-goldens
///
/// Real Roboto is loaded from the Flutter SDK first; without it the test
/// renderer draws every glyph as a filled box and the output is useless
/// for judging type.
/// Walks up from the test runner executable looking for the SDK's bundled
/// `material_fonts`, whose depth differs by platform and engine layout.
Directory? _materialFontsDir() {
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    final candidate = Directory('${dir.path}/material_fonts');
    if (candidate.existsSync()) return candidate;
    if (dir.parent.path == dir.path) break;
    dir = dir.parent;
  }
  return null;
}

Future<bool> _loadRoboto() async {
  final dir = _materialFontsDir();
  if (dir == null) return false;
  final loader = FontLoader('Roboto');
  var loaded = false;
  for (final file in const [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-black.ttf',
  ]) {
    final f = File('${dir.path}/$file');
    if (f.existsSync()) {
      loader.addFont(Future.value(ByteData.sublistView(await f.readAsBytes())));
      loaded = true;
    }
  }
  if (loaded) await loader.load();
  return loaded;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(await _loadRoboto(), isTrue,
        reason: 'previews are unreadable without a real font');
  });

  final assessment = Assessment(
    userId: 1,
    date: DateTime(2026, 8, 14, 9, 30),
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
      MetricPercentile(
          metricId: MetricId.apeIndex, percentile: 73, gradeEquivalent: 7.8),
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
    anchorIsFallback: false,
  );

  TestResult result(MetricId id, double value, {double? pctBW}) => TestResult(
        userId: 1,
        metricId: id,
        date: DateTime(2026, 8, 1),
        rawValue: value,
        unit: '%BW',
        computedPctBW: pctBW,
      );

  Widget page(Widget child, Brightness brightness) {
    final base =
        brightness == Brightness.light ? AppTheme.light() : AppTheme.dark();
    // The app leaves `fontFamily` null so each platform uses its own system
    // face; the test renderer's default is a box glyph, so pin the preview
    // to the SDK's Roboto purely so the output is legible.
    final theme = base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Roboto'),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: child,
    );
  }

  /// A stand-in for the Test hub that skips the provider/database wiring
  /// but uses the same widgets, spacing, and hierarchy as the real screen.
  Widget testHubLike() {
    final finger = MetricDefinitions.all[MetricId.fingerStrength]!;
    final pull = MetricDefinitions.all[MetricId.pullingStrength]!;
    final core = MetricDefinitions.all[MetricId.core]!;
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      Widget heading(String t) => Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs, AppSpacing.xl, AppSpacing.xs, AppSpacing.md),
            child: Text(t.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                )),
          );
      return Scaffold(
        appBar: AppBar(
          title: const Text('Test hub'),
          actions: const [
            Icon(Icons.account_circle_outlined),
            SizedBox(width: AppSpacing.lg),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 0,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.checklist_rounded), label: 'Test hub'),
            NavigationDestination(
                icon: Icon(Icons.insights_outlined), label: 'Results'),
            NavigationDestination(
                icon: Icon(Icons.timeline_outlined), label: 'Progress'),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm,
              AppSpacing.gutter, AppSpacing.scrollBottomInset),
          children: [
            Row(children: [
              Expanded(
                  child: Text('9 of 14 tests recorded',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant))),
              Text('64%',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ]),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              child: LinearProgressIndicator(
                value: 0.64,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
                valueColor:
                    AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            LiveGradePreview(preview: preview, hasAnyTest: true),
            heading('Fingers'),
            MetricCard(
                def: finger,
                latest: result(MetricId.fingerStrength, 142, pctBW: 142),
                percentile: 82,
                onTest: () {},
                onHowTo: () {}),
            heading('Pull / Power'),
            MetricCard(
                def: pull,
                latest: result(MetricId.pullingStrength, 118, pctBW: 118),
                percentile: 51,
                onTest: () {},
                onHowTo: () {}),
            heading('Core'),
            MetricCard(
                def: core,
                latest: result(MetricId.core, 3),
                percentile: 18,
                onTest: () {},
                onHowTo: () {}),
            MetricCard(
                def: MetricDefinitions.all[MetricId.fingerEndurance]!,
                latest: null,
                onTest: () {},
                onHowTo: () {}),
          ],
        ),
      );
    });
  }

  /// The Results screen's hero + limiter + profile stack, again without
  /// the provider wiring.
  Widget resultsLike() => Builder(builder: (context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final levels = theme.extension<LevelPalette>()!;
        return Scaffold(
          appBar: AppBar(title: const Text('Results')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                AppSpacing.sm, AppSpacing.gutter, AppSpacing.scrollBottomInset),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xxl, horizontal: AppSpacing.xl),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                ),
                child: Column(children: [
                  Text('YOUR GRADE RANGE',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onPrimary, letterSpacing: 1.4)),
                  const SizedBox(height: AppSpacing.md),
                  Text('V6-V9',
                      style: theme.textTheme.displaySmall
                          ?.copyWith(color: scheme.onPrimary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('most likely V7',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: scheme.onPrimary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('7A-7C font',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onPrimary)),
                ]),
              ),
              const SizedBox(height: AppSpacing.xl),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    IntrinsicHeight(
                      child: Row(children: [
                        Expanded(
                            child: Column(children: [
                          Text('Physical ceiling',
                              style: theme.textTheme.labelMedium?.copyWith(
                                  color: scheme.onSurfaceVariant)),
                          const SizedBox(height: AppSpacing.xs),
                          Text('V8',
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(color: scheme.primary)),
                        ])),
                        const VerticalDivider(width: 1),
                        Expanded(
                            child: Column(children: [
                          Text('Experience-typical',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelMedium?.copyWith(
                                  color: scheme.onSurfaceVariant)),
                          const SizedBox(height: AppSpacing.xs),
                          Text('V7',
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(color: scheme.primary)),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.fitness_center_rounded,
                          size: 18, color: scheme.onSurfaceVariant),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                          child: Text(
                              "Your fingers/body support a higher grade than your experience suggests you're climbing — technique and mileage are likely your limiter.",
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant))),
                    ]),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xs,
                    AppSpacing.xl, AppSpacing.xs, AppSpacing.md),
                child: Text('YOUR TOP LIMITERS',
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant, letterSpacing: 1.2)),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: levels.weakSurface,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border:
                      Border.all(color: levels.weak.withValues(alpha: 0.35)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.trending_down_rounded, color: levels.weak),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(children: [
                          Expanded(
                              child: Text('Core',
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(color: scheme.onSurface))),
                          Text('V5',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(color: levels.weak)),
                        ]),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                            'Your physical ceiling is V8 — core is holding you back by about 2.1 grades.',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurface)),
                      ])),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xs,
                    AppSpacing.xl, AppSpacing.xs, AppSpacing.md),
                child: Text('PROFILE',
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant, letterSpacing: 1.2)),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(children: [
                    for (final p in assessment.perMetricPercentiles)
                      LevelBar(
                        label: MetricDefinitions.all[p.metricId]!.shortName,
                        percentile: p.percentile,
                        trailingText: 'V${p.gradeEquivalent.round()}',
                      ),
                  ]),
                ),
              ),
            ],
          ),
        );
      });

  /// The real input screen, not a stand-in — it builds fine against a bare
  /// AppState, since only the save path touches sqflite.
  Widget realInput(MetricId id) => ChangeNotifierProvider(
        create: (_) => AppState(),
        child: TestInputScreen(metricId: id),
      );

  final pages = <String, Widget Function()>{
    'test-hub': testHubLike,
    'results': resultsLike,
    'input-finger-strength': () => realInput(MetricId.fingerStrength),
    'input-power-endurance': () => realInput(MetricId.powerEndurance),
    'input-core': () => realInput(MetricId.core),
    'input-explosive-power': () => realInput(MetricId.explosivePower),
  };

  for (final entry in pages.entries) {
    for (final brightness in Brightness.values) {
      testWidgets('preview ${entry.key} ${brightness.name}', (tester) async {
        tester.view.physicalSize = const Size(390, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(page(entry.value(), brightness));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('previews/${entry.key}-${brightness.name}.png'),
        );
      });
    }
  }

  // The full protocol reference, reached from the input screen's info
  // action — rendered by driving the real control rather than rebuilding
  // the sheet's contents by hand.
  testWidgets('preview protocol-sheet light', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        page(realInput(MetricId.fingerStrength), Brightness.light));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('previews/protocol-sheet-light.png'),
    );
  });
}
