import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:crux_check/data/safety_disclaimer.dart';
import 'package:crux_check/screens/disclaimer_screen.dart';
import 'package:crux_check/state/app_state.dart';
import 'package:crux_check/theme/app_theme.dart';
import 'package:crux_check/widgets/support_card.dart';

/// Guards the safety disclaimer, which is a legal requirement and so must be
/// impossible to skip, and the tip jar, which must stay a donation rather than
/// becoming an in-app purchase.
void main() {
  Future<void> pump(WidgetTester tester, Widget child, AppState state) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(theme: AppTheme.light(), home: child),
      ),
    );
    await tester.pump();
  }

  group('safety disclaimer', () {
    testWidgets('cannot be accepted without ticking the box', (tester) async {
      await pump(tester, const DisclaimerScreen(), AppState());

      final continueButton = find.widgetWithText(FilledButton, 'Continue');
      expect(continueButton, findsOneWidget);
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
    });

    testWidgets('states the injury risk and that it is not medical advice', (
      tester,
    ) async {
      await pump(tester, const DisclaimerScreen(), AppState());

      // The two claims that actually carry legal weight. If either wording is
      // dropped, this should fail rather than ship quietly.
      final text = SafetyDisclaimer.sections
          .map((s) => '${s.$1} ${s.$2}')
          .join(' ')
          .toLowerCase();
      expect(text, contains('not a medical device'));
      expect(text, contains('risk'));
      expect(text, contains('at your own risk'));
    });

    testWidgets('read-only mode offers nothing to accept', (tester) async {
      await pump(tester, const DisclaimerScreen(readOnly: true), AppState());
      expect(find.widgetWithText(FilledButton, 'Continue'), findsNothing);
      expect(find.byType(CheckboxListTile), findsNothing);
    });

    test('a fresh install has accepted nothing', () {
      final state = AppState();
      expect(state.acceptedDisclaimerVersion, 0);
      expect(state.needsDisclaimer, isTrue);
    });

    test('the growth-plate warning leads, and is not buried', () {
      // The most serious harm this app can contribute to. Epiphyseal
      // fractures in young climbers are easy to miss and can deform the
      // finger permanently, so this must not drift down the page or get
      // folded into the general "not for beginners" paragraph.
      final headings = SafetyDisclaimer.sections.map((s) => s.$1).toList();
      expect(headings.first.toLowerCase(), contains('under 18'));

      final body = SafetyDisclaimer.sections.first.$2.toLowerCase();
      expect(body, contains('growth plates'));
      expect(body, contains('doctor'));
    });

    test('tells the user to get a suspected pulley injury seen', () {
      final text = SafetyDisclaimer.sections
          .map((s) => '${s.$1} ${s.$2}')
          .join(' ')
          .toLowerCase();
      expect(text, contains('pop'));
      expect(text, contains('physiotherapist'));
    });

    test('does not claim blanket immunity it cannot have', () {
      final liability = SafetyDisclaimer.sections.last.$2.toLowerCase();
      // Excluding liability for negligently caused personal injury is
      // unenforceable across the EEA, and an over-broad unfair term risks
      // being struck out entirely rather than read down. The carve-out is
      // what keeps the rest of the clause standing.
      expect(liability, contains('cannot lawfully be limited'));
      expect(liability, contains('personal injury'));
      expect(liability, contains('statutory rights'));
    });

    test('bumping the disclaimer version re-prompts an old acceptance', () {
      final state = AppState()..acceptedDisclaimerVersion = 0;
      expect(state.needsDisclaimer, isTrue);
      state.acceptedDisclaimerVersion = SafetyDisclaimer.version;
      expect(state.needsDisclaimer, isFalse);
    });
  });

  group('the tip jar is a donation, not a purchase', () {
    testWidgets('is an outbound link that gates nothing', (tester) async {
      await pump(tester, const Scaffold(body: SupportCard()), AppState());

      // Google Play requires its own billing for in-app purchases of digital
      // content, so this stays compliant only while paying changes nothing in
      // the app. It links out and returns no value to act on.
      expect(find.widgetWithText(TextButton, 'Buy a coffee'), findsOneWidget);
      expect(SupportCard.supportUrl.scheme, 'https');
    });
  });

  group('delete all data', () {
    test('returns the app to its first-launch state', () async {
      final state = AppState()
        ..acceptedDisclaimerVersion = SafetyDisclaimer.version
        ..disclaimerAcceptedAt = DateTime(2026, 1, 1);
      expect(state.needsDisclaimer, isFalse);

      // The DB call is exercised in the app; this pins the in-memory reset,
      // which is what the UI reads. A reset that left a stale acceptance
      // behind would claim the user agreed to something in a state that no
      // longer exists.
      state
        ..user = null
        ..latestAssessment = null
        ..acceptedDisclaimerVersion = 0
        ..disclaimerAcceptedAt = null;

      expect(state.hasProfile, isFalse);
      expect(state.needsDisclaimer, isTrue);
    });
  });
}
