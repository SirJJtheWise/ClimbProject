import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/safety_disclaimer.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Blocking safety gate shown before anything else, including onboarding.
///
/// Acceptance is deliberately awkward to give by accident: the button stays
/// disabled until the text has actually been scrolled to the end and the
/// checkbox ticked. A disclaimer nobody can have read is not worth much, and
/// the whole point is that the person has seen the injury warning before they
/// hang off a 6 mm edge.
///
/// Shown again whenever [SafetyDisclaimer.version] moves past what the user
/// accepted, so changed terms are re-consented rather than assumed.
class DisclaimerScreen extends StatefulWidget {
  /// When shown from the profile rather than as a launch gate, there is
  /// nothing to accept — it is just the text.
  final bool readOnly;

  const DisclaimerScreen({super.key, this.readOnly = false});

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _accepted = false;
  bool _reachedEnd = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // A short page on a tall screen never scrolls, so nothing would ever mark
    // it as read.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _reachedEnd) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels <= 24) {
      setState(() => _reachedEnd = true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canAccept = _reachedEnd && _accepted;

    return Scaffold(
      appBar: AppBar(
        title: const Text(SafetyDisclaimer.title),
        automaticallyImplyLeading: widget.readOnly,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.lg,
                  AppSpacing.gutter,
                  AppSpacing.lg,
                ),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.health_and_safety_outlined,
                        color: scheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          SafetyDisclaimer.intro,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (widget.readOnly) ...[
                    Builder(
                      builder: (context) {
                        final acceptedAt = context
                            .watch<AppState>()
                            .disclaimerAcceptedAt;
                        if (acceptedAt == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                          child: Text(
                            'Accepted ${DateFormat.yMMMd().add_jm().format(acceptedAt.toLocal())}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  for (final (heading, body) in SafetyDisclaimer.sections) ...[
                    Text(heading, style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ],
              ),
            ),
            if (!widget.readOnly)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.md,
                  AppSpacing.gutter,
                  AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  border: Border(top: BorderSide(color: scheme.outlineVariant)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      value: _accepted,
                      onChanged: _reachedEnd
                          ? (v) => setState(() => _accepted = v ?? false)
                          : null,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        SafetyDisclaimer.acceptLabel,
                        style: theme.textTheme.bodyMedium,
                      ),
                      subtitle: _reachedEnd
                          ? null
                          : Text(
                              'Scroll to the end to continue',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: canAccept
                            ? () => context.read<AppState>().acceptDisclaimer()
                            : null,
                        child: const Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
