import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

/// A tip jar, shown at the bottom of the Results screen.
///
/// It must stay a pure donation: it unlocks nothing, gates nothing and is not
/// tied to any feature. Google Play requires its own billing system for
/// in-app purchases of digital content, and the moment a payment buys access
/// to something in the app it becomes exactly that. Kept as an outbound link
/// with no in-app consequence, it is a donation rather than a purchase.
///
/// So: do not make anything conditional on this. If a paid tier is ever
/// wanted, that is Play Billing and a different widget.
class SupportCard extends StatelessWidget {
  /// Set this to the real tip-jar page before shipping.
  static final Uri supportUrl = Uri.parse('https://buymeacoffee.com/');

  const SupportCard({super.key});

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final launched = await launchUrl(
        supportUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw Exception('no handler for $supportUrl');
    } catch (_) {
      // A device with no browser is rare but real (and the link can simply
      // fail). A dead-looking button is worse than saying so.
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(Icons.local_cafe_outlined, color: scheme.primary, size: 28),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enjoying Crux Check?',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'It is free, has no ads and collects nothing. A coffee '
                    'keeps it that way.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: () => _open(context),
              child: const Text('Buy a coffee'),
            ),
          ],
        ),
      ),
    );
  }
}
