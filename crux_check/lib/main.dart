import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/disclaimer_screen.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CruxCheckApp());
}

class CruxCheckApp extends StatelessWidget {
  const CruxCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..loadFromDb(),
      child: MaterialApp(
        title: 'Crux Check',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const _RootRouter(),
      ),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // Ahead of onboarding: the injury warning has to land before the app has
    // asked for anything, not after.
    if (appState.needsDisclaimer) {
      return const DisclaimerScreen();
    }
    if (!appState.hasProfile) {
      return const OnboardingScreen();
    }
    return const HomeShell();
  }
}
