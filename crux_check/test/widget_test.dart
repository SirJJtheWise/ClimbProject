import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:crux_check/state/app_state.dart';

// Note: this deliberately does not pump the real CruxCheckApp widget, since
// its root ChangeNotifierProvider calls AppState.loadFromDb() immediately,
// which needs a platform channel sqflite has no fake for under `flutter
// test` (no Android/iOS/desktop host, and no ffi sqlite3 available in this
// environment). Instead we build the same provider/router shape around a
// fresh, unloaded AppState to exercise the loading UI in isolation.
void main() {
  testWidgets('root router shows a loading indicator before the DB loads', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final appState = context.watch<AppState>();
              if (appState.loading) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
