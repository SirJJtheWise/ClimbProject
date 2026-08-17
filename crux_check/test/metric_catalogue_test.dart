import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:crux_check/data/metric_definitions.dart';
import 'package:crux_check/models/enums.dart';
import 'package:crux_check/screens/test_input_screen.dart';
import 'package:crux_check/state/app_state.dart';
import 'package:crux_check/theme/app_theme.dart';
import 'package:crux_check/widgets/hang_timer.dart';
import 'package:crux_check/widgets/load_calculator.dart';

/// Guards the two properties the catalogue is supposed to have: every test
/// measures something the others do not, and the way a result is entered
/// matches the exercise that produced it. Both regress silently — a
/// duplicated protocol still compiles, and a %BW metric behind a bare
/// number field still saves.
void main() {
  final defs = MetricDefinitions.orderedForHub;

  group('catalogue is fully described', () {
    for (final def in defs) {
      test('${def.shortName} has a complete description', () {
        expect(def.summary, isNotEmpty, reason: 'needs a "what it measures"');
        expect(def.equipment, isNotEmpty, reason: 'needs an equipment line');
        expect(def.recordText, isNotEmpty, reason: 'needs a "what to record"');
        expect(def.steps.length, greaterThanOrEqualTo(2),
            reason: 'a protocol worth following needs more than one step');
        for (final step in def.steps) {
          expect(step.trim(), isNotEmpty);
        }
      });
    }
  });

  group('no two tests are the same test', () {
    test('every protocol is unique', () {
      final seen = <String, MetricId>{};
      for (final def in defs) {
        final key = def.steps.join('|');
        expect(seen[key], isNull,
            reason: '${def.shortName} has the same protocol as '
                '${seen[key]?.name}');
        seen[key] = def.id;
      }
    });

    test('power-endurance is a board test, not a second hangboard test', () {
      final pe = MetricDefinitions.all[MetricId.powerEndurance]!;
      expect(pe.unit, 'moves');
      expect('${pe.summary} ${pe.equipment}'.toLowerCase(), contains('board'));
      expect(pe.steps.join(' ').toLowerCase(), isNot(contains('repeater')));
      expect(pe.steps.join(' ').toLowerCase(), isNot(contains('hangboard')));
    });

    test('finger endurance is the only 7:3 repeater protocol', () {
      final repeaterTests = defs
          .where((d) => d.steps.join(' ').toLowerCase().contains('7:3'))
          .map((d) => d.id)
          .toList();
      expect(repeaterTests, [MetricId.fingerEndurance]);
    });

    test('explosive power does not reuse the campus-reach protocol', () {
      final ep = MetricDefinitions.all[MetricId.explosivePower]!;
      expect(ep.steps.join(' ').toLowerCase(), isNot(contains('campus')));
      expect(ep.steps.join(' ').toLowerCase(), contains('dyno'));
    });

    test('campus reach is the only campus-board protocol', () {
      final campusTests = defs
          .where((d) => d.steps.join(' ').toLowerCase().contains('campus'))
          .map((d) => d.id)
          .toList();
      expect(campusTests, [MetricId.rfdContact]);
    });

    test('the two pull tests measure load and reps respectively', () {
      expect(MetricDefinitions.all[MetricId.pullingStrength]!.unit, '%BW');
      expect(MetricDefinitions.all[MetricId.pullReps]!.unit, 'reps');
    });
  });

  group('the input matches the exercise', () {
    Future<void> pumpTest(WidgetTester tester, MetricId id) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ChangeNotifierProvider(
          // A bare AppState never touches sqflite; only the save path does,
          // and these assertions are all about what gets built.
          create: (_) => AppState(),
          child: MaterialApp(
            theme: AppTheme.light(),
            home: TestInputScreen(metricId: id),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('finger strength gets a 7s timer and the load calculator',
        (tester) async {
      await pumpTest(tester, MetricId.fingerStrength);
      expect(find.byType(HangTimer), findsOneWidget);
      expect(find.byType(LoadCalculator), findsOneWidget);
      expect(find.text('Edge size'), findsOneWidget);
    });

    testWidgets('finger endurance records %BW via the load calculator',
        (tester) async {
      await pumpTest(tester, MetricId.fingerEndurance);
      expect(find.byType(LoadCalculator), findsOneWidget);
      // A single-shot stopwatch cannot run a 4-minute 7:3 interval, so the
      // screen must not pretend it can.
      expect(find.byType(HangTimer), findsNothing);
    });

    testWidgets('power endurance counts moves and offers no stopwatch',
        (tester) async {
      await pumpTest(tester, MetricId.powerEndurance);
      expect(find.text('Hand moves completed'), findsOneWidget);
      expect(find.byType(HangTimer), findsNothing);
      expect(find.byType(LoadCalculator), findsNothing);
    });

    testWidgets('lock-off keeps the stopwatch', (tester) async {
      await pumpTest(tester, MetricId.lockOff);
      expect(find.byType(HangTimer), findsOneWidget);
    });

    testWidgets('campus reach offers rungs, not a decimal field',
        (tester) async {
      await pumpTest(tester, MetricId.rfdContact);
      expect(find.text('Highest rung latched and held: 4'), findsOneWidget);
      await tester.tap(find.text('7'));
      await tester.pump();
      expect(find.text('Highest rung latched and held: 7'), findsOneWidget);
    });

    testWidgets('core shows the named ladder position', (tester) async {
      await pumpTest(tester, MetricId.core);
      expect(find.text('LEVEL 3'), findsOneWidget);
      expect(find.text('Advanced tuck'), findsOneWidget);
    });

    testWidgets('explosive power derives the gain from two measurements',
        (tester) async {
      await pumpTest(tester, MetricId.explosivePower);
      expect(find.text('Static reach (cm)'), findsOneWidget);
      expect(find.text('Catch height (cm)'), findsOneWidget);
      expect(find.text('GAIN OVER STATIC REACH'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), '210');
      await tester.enterText(find.byType(TextField).at(1), '265');
      await tester.pump();
      expect(find.text('55 cm'), findsOneWidget);
    });

    testWidgets('hip flexion derives a ratio from two measurements',
        (tester) async {
      await pumpTest(tester, MetricId.hipFlexion);
      await tester.enterText(find.byType(TextField).at(0), '100');
      await tester.enterText(find.byType(TextField).at(1), '90');
      await tester.pump();
      expect(find.text('90 % of leg length'), findsOneWidget);
    });
  });
}
