import 'package:flutter/material.dart';

import '../logic/scoring_engine.dart';
import '../theme/app_theme.dart';

/// Bodyweight + added/removed load -> %BW, live. Added load may be negative
/// (assisted testing).
class LoadCalculator extends StatefulWidget {
  final double initialBodyWeightKg;
  final void Function(double pctBW, double bodyWeightKg, double addedLoadKg)
  onChanged;

  const LoadCalculator({
    super.key,
    required this.initialBodyWeightKg,
    required this.onChanged,
  });

  @override
  State<LoadCalculator> createState() => _LoadCalculatorState();
}

class _LoadCalculatorState extends State<LoadCalculator> {
  late final TextEditingController _bwController;
  final TextEditingController _addedController = TextEditingController(
    text: '0',
  );
  double _pctBW = 100;

  @override
  void initState() {
    super.initState();
    _bwController = TextEditingController(
      text: widget.initialBodyWeightKg > 0
          ? widget.initialBodyWeightKg.toStringAsFixed(1)
          : '',
    );
    _recompute();
  }

  void _recompute() {
    final bw = double.tryParse(_bwController.text) ?? 0;
    final added = double.tryParse(_addedController.text) ?? 0;
    if (bw <= 0) {
      setState(() => _pctBW = 0);
      return;
    }
    final pct = ScoringEngine.pctBWFromLoad(bw, added);
    setState(() => _pctBW = pct);
    widget.onChanged(pct, bw, added);
  }

  @override
  void dispose() {
    _bwController.dispose();
    _addedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _bwController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Bodyweight (kg)'),
          onChanged: (_) => _recompute(),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _addedController,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: const InputDecoration(
            labelText: 'Added load (kg)',
            helperText: 'Negative if assisted',
          ),
          onChanged: (_) => _recompute(),
        ),
        const SizedBox(height: AppSpacing.lg),
        // The computed figure is what actually gets saved, so it is
        // presented as a result readout rather than a stray large number
        // floating under two inputs.
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          child: Column(
            children: [
              Text(
                'RECORDED AS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${_pctBW.toStringAsFixed(0)} %BW',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
