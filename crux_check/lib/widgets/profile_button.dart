import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/onboarding_screen.dart';
import '../state/app_state.dart';

/// "Edit profile", as an app-bar action on every top-level screen.
///
/// It used to be a [FloatingActionButton] in the shell, which put a
/// permanently visible circle over whichever tab you were on — obscuring
/// the last list row and claiming the primary-action slot for something
/// that is neither primary nor per-screen. An app-bar action is reachable
/// from all three tabs without covering any of them.
class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.account_circle_outlined),
      tooltip: 'Edit profile',
      onPressed: () {
        final appState = context.read<AppState>();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OnboardingScreen(
              existingUser: appState.user,
              existingWeightKg: appState.latestBody?.weightKg,
            ),
          ),
        );
      },
    );
  }
}
