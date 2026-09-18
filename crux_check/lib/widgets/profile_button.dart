import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/disclaimer_screen.dart';
import '../screens/onboarding_screen.dart';
import '../state/app_state.dart';

/// Profile and safety, as an app-bar action on every top-level screen.
///
/// It used to be a [FloatingActionButton] in the shell, which put a
/// permanently visible circle over whichever tab you were on — obscuring
/// the last list row and claiming the primary-action slot for something
/// that is neither primary nor per-screen. An app-bar action is reachable
/// from all three tabs without covering any of them.
///
/// The safety notice has to stay reachable after it has been accepted. A
/// warning you can read exactly once, at the moment you are trying to get
/// into the app, is not one the user can be said to have available to them.
enum _ProfileAction { editProfile, safetyNotice, deleteData }

class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ProfileAction>(
      icon: const Icon(Icons.account_circle_outlined),
      tooltip: 'Profile and safety',
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _ProfileAction.editProfile,
          child: ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Edit profile'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _ProfileAction.safetyNotice,
          child: ListTile(
            leading: Icon(Icons.health_and_safety_outlined),
            title: Text('Safety notice'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _ProfileAction.deleteData,
          child: ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text('Delete all my data'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      onSelected: (action) async {
        final appState = context.read<AppState>();
        final navigator = Navigator.of(context);

        if (action == _ProfileAction.deleteData) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete all my data?'),
              content: const Text(
                'This erases your profile, every test result and your whole '
                'grade history from this device.\n\n'
                'Nothing is stored anywhere else, so there is no backup and '
                'this cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete everything'),
                ),
              ],
            ),
          );
          if (confirmed ?? false) await appState.deleteAllData();
          return;
        }

        navigator.push(switch (action) {
          _ProfileAction.editProfile => MaterialPageRoute<void>(
            builder: (_) => OnboardingScreen(
              existingUser: appState.user,
              existingWeightKg: appState.latestBody?.weightKg,
            ),
          ),
          _ProfileAction.safetyNotice => MaterialPageRoute<void>(
            builder: (_) => const DisclaimerScreen(readOnly: true),
          ),
          _ProfileAction.deleteData => throw StateError('handled above'),
        });
      },
    );
  }
}
