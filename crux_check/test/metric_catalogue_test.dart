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
        expect(
          def.steps.length,
          greaterThanOrEqualTo(2),
          reason: 'a protocol worth following needs more than one step',
        );
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
        expect(
          seen[key],
          isNull,
          reason:
              '${def.shortName} has the same protocol as '
              '${seen[key]?.name}',
        );
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

    test('no test asks for a force reading the equipment cannot produce', () {
      // Critical force needs a load cell to read a falling force off. On a
      // hangboard with hung plates the load is constant by construction, so
      // any protocol asking for a sustained/declining force is unmeasurable
      // with the equipment these tests list.
      for (final def in defs) {
        final protocol =
            '${def.summary} ${def.recordText} ${def.steps.join(' ')}'
                .toLowerCase();
        expect(
          protocol,
          isNot(contains('critical force')),
          reason: '${def.shortName} asks for a load-cell measurement',
        );
      }
    });

    test('the two finger tests vary load and edge size respectively', () {
      final fs = MetricDefinitions.all[MetricId.fingerStrength]!;
      final me = MetricDefinitions.all[MetricId.minEdge]!;
      expect(fs.unit, '%BW');
      expect(me.unit, 'mm');
      // Min edge is the bodyweight test; if it ever grows a load field it has
      // become edge tolerance again, which was cut for duplicating max hang.
      expect(me.equipment.toLowerCase(), contains('no added weight'));
    });

    test('smaller is better on min edge', () {
      final me = MetricDefinitions.all[MetricId.minEdge]!;
      final range = me.maleNormativeRange!;
      expect(range.best, lessThan(range.worst));
      expect(range.percentileFor(range.best), 100);
      expect(range.percentileFor(range.worst), 0);
    });

    test('campus rungs are scored on a reachable scale', () {
      final campus = MetricDefinitions.all[MetricId.rfdContact]!;
      // Rung 4 is a normal result and has to score as one; the old 2-9 range
      // put it at the 29th percentile, so every user was told their contact
      // strength was a weakness.
      expect(campus.maleNormativeRange!.percentileFor(4), 50);
      expect(campus.maleNormativeRange!.percentileFor(6), 100);
      expect(campus.femaleNormativeRange!.percentileFor(3), 50);
    });

    test('power-endurance does not move a grade it cannot predict', () {
      expect(MetricDefinitions.all[MetricId.powerEndurance]!.weight, 0);
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

    testWidgets('finger strength records load, and times the hang off-app', (
      tester,
    ) async {
      await pumpTest(tester, MetricId.fingerStrength);
      expect(find.byType(LoadCalculator), findsOneWidget);
      expect(find.text('Grip'), findsOneWidget);
      // You cannot hang off both hands and work a stopwatch, and the edge is
      // fixed at 20 mm because that is what the grade table is calibrated on.
      expect(find.byType(HangTimer), findsNothing);
      expect(find.text('Edge size'), findsNothing);
    });

    testWidgets('min edge picks an edge and takes no load', (tester) async {
      await pumpTest(tester, MetricId.minEdge);
      expect(find.byType(LoadCalculator), findsNothing);
      expect(find.byType(HangTimer), findsNothing);
      expect(
        find.text('Smallest edge held for 7 s at bodyweight: 14 mm'),
        findsOneWidget,
      );
      await tester.tap(find.text('10'));
      await tester.pump();
      expect(
        find.text('Smallest edge held for 7 s at bodyweight: 10 mm'),
        findsOneWidget,
      );
    });

    testWidgets('power endurance counts moves and offers no stopwatch', (
      tester,
    ) async {
      await pumpTest(tester, MetricId.powerEndurance);
      expect(find.text('Hand moves completed'), findsOneWidget);
      expect(find.byType(HangTimer), findsNothing);
      expect(find.byType(LoadCalculator), findsNothing);
    });

    testWidgets('lock-off keeps the stopwatch', (tester) async {
      await pumpTest(tester, MetricId.lockOff);
      expect(find.byType(HangTimer), findsOneWidget);
    });

    testWidgets('campus reach offers rungs, not a decimal field', (
      tester,
    ) async {
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

    testWidgets('explosive power derives the gain from two measurements', (
      tester,
    ) async {
      await pumpTest(tester, MetricId.explosivePower);
      expect(find.text('Static reach (cm)'), findsOneWidget);
      expect(find.text('Catch height (cm)'), findsOneWidget);
      expect(find.text('GAIN OVER STATIC REACH'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), '210');
      await tester.enterText(find.byType(TextField).at(1), '265');
      await tester.pump();
      expect(find.text('55 cm'), findsOneWidget);
    });

    testWidgets('hip flexion derives a ratio from two measurements', (
      tester,
    ) async {
      await pumpTest(tester, MetricId.hipFlexion);
      await tester.enterText(find.byType(TextField).at(0), '100');
      await tester.enterText(find.byType(TextField).at(1), '90');
      await tester.pump();
      expect(find.text('90 % of leg length'), findsOneWidget);
    });
  });
}
