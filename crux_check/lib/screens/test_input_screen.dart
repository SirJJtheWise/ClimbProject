import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/metric_definitions.dart';
import '../logic/experience_index.dart';
import '../models/enums.dart';
import '../models/metric_def.dart';
import '../models/test_result.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/hang_timer.dart';
import '../widgets/load_calculator.dart';
import '../widgets/protocol_sheet.dart';

/// Metrics recorded as %BW via the load calculator.
const _loadBasedMetrics = {
  MetricId.fingerStrength,
  MetricId.pullingStrength,
  MetricId.edgeTolerance,
  MetricId.fingerEndurance,
};

/// Metrics whose protocol is a single continuous hold, so the built-in
/// stopwatch is the right instrument. Power-endurance deliberately is not
/// here: it is a board max-moves test now, and a stopwatch cannot run a
/// counted-move protocol.
const _timedMetrics = {
  MetricId.lockOff,
};

/// Load-based metrics that hang on an edge, so the edge-size and grip
/// selectors apply and a 7-second target is meaningful.
const _sevenSecondHangMetrics = {
  MetricId.fingerStrength,
  MetricId.edgeTolerance,
};

/// Human-readable grip names. The enum values are camelCase identifiers;
/// showing them raw in a dropdown reads as a leaked implementation detail.
const _gripLabels = {
  GripType.halfCrimp: 'Half crimp',
  GripType.openCrimp: 'Open hand',
  GripType.fullCrimp: 'Full crimp',
};

/// The front-lever ladder, spelled out where the value is entered rather
/// than left as a "0-9" box the user has to decode from the protocol.
const _coreLadder = {
  0: 'Cannot hold a tuck front lever',
  1: 'Tuck, briefly',
  2: 'Tuck, held 5 s+',
  3: 'Advanced tuck',
  4: 'Advanced tuck, held 10 s+',
  5: 'One-leg front lever',
  6: 'One-leg, held 10 s+',
  7: 'Full front lever',
  8: 'Full front lever, held 10 s+',
  9: 'Full front lever, held 20 s+',
};

class TestInputScreen extends StatefulWidget {
  final MetricId metricId;

  const TestInputScreen({super.key, required this.metricId});

  @override
  State<TestInputScreen> createState() => _TestInputScreenState();
}

class _TestInputScreenState extends State<TestInputScreen> {
  bool _hitTrueMax = true;
  bool _saving = false;

  // Load-based
  double _pctBW = 0;
  double _bodyWeightKg = 0;
  double _addedLoadKg = 0;
  double _edgeSizeMm = 20;
  GripType _gripType = GripType.halfCrimp;

  // Discrete pickers
  int _rungReached = 4;
  int _coreLevel = 3;

  // Timed / numeric
  final _numberController = TextEditingController();
  final _secondaryController = TextEditingController(); // leg length, reach

  // Experience sub-form
  final _yearsClimbingController = TextEditingController();
  final _sessionsPerWeekController = TextEditingController();
  final _yearsOutdoorController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    _secondaryController.dispose();
    _yearsClimbingController.dispose();
    _sessionsPerWeekController.dispose();
    _yearsOutdoorController.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext context) async {
    final appState = context.read<AppState>();
    setState(() => _saving = true);
    try {
      if (widget.metricId == MetricId.bodyComposition) {
        final bf = double.tryParse(_numberController.text);
        if (bf == null) return;
        final bw = appState.latestBody?.weightKg ?? 0;
        await appState.saveBodyMeasurement(weightKg: bw, bodyFatPct: bf);
      } else if (widget.metricId == MetricId.experience) {
        final years = double.tryParse(_yearsClimbingController.text) ?? 0;
        final sessions = double.tryParse(_sessionsPerWeekController.text) ?? 0;
        final outdoor = double.tryParse(_yearsOutdoorController.text) ?? 0;
        final index = experienceIndex(
          yearsClimbing: years,
          sessionsPerWeek: sessions,
          yearsClimbingOutdoors: outdoor,
        );
        await appState.saveTestResult(
          metricId: MetricId.experience,
          rawValue: index,
          unit: 'index (0-100)',
          hitTrueMax: true,
        );
      } else if (widget.metricId == MetricId.rfdContact) {
        await appState.saveTestResult(
          metricId: MetricId.rfdContact,
          rawValue: _rungReached.toDouble(),
          unit: 'rung',
          hitTrueMax: _hitTrueMax,
        );
      } else if (widget.metricId == MetricId.core) {
        await appState.saveTestResult(
          metricId: MetricId.core,
          rawValue: _coreLevel.toDouble(),
          unit: 'level (0-9)',
          hitTrueMax: _hitTrueMax,
        );
      } else if (widget.metricId == MetricId.explosivePower) {
        // The metric is the gain over static reach, not the absolute catch
        // height — otherwise it just measures how tall the climber is.
        final catchHeight = double.tryParse(_numberController.text);
        final staticReach = double.tryParse(_secondaryController.text);
        if (catchHeight == null || staticReach == null) return;
        final gain = catchHeight - staticReach;
        if (gain <= 0) {
          _showError('Your catch height needs to be above your static reach.');
          return;
        }
        await appState.saveTestResult(
          metricId: MetricId.explosivePower,
          rawValue: gain,
          unit: 'cm',
          hitTrueMax: _hitTrueMax,
        );
      } else if (widget.metricId == MetricId.hipAbduction) {
        final distanceCm = double.tryParse(_numberController.text);
        final heightCm = appState.user!.heightCm;
        if (distanceCm == null || heightCm <= 0) return;
        final pctHeight = distanceCm / heightCm * 100;
        await appState.saveTestResult(
          metricId: MetricId.hipAbduction,
          rawValue: pctHeight,
          unit: '% of height',
          hitTrueMax: _hitTrueMax,
        );
      } else if (widget.metricId == MetricId.hipFlexion) {
        final footHeightCm = double.tryParse(_numberController.text);
        final legLengthCm = double.tryParse(_secondaryController.text);
        if (footHeightCm == null || legLengthCm == null || legLengthCm <= 0) {
          return;
        }
        final pctLeg = footHeightCm / legLengthCm * 100;
        await appState.saveTestResult(
          metricId: MetricId.hipFlexion,
          rawValue: pctLeg,
          unit: '% of leg length',
          hitTrueMax: _hitTrueMax,
        );
      } else if (_loadBasedMetrics.contains(widget.metricId)) {
        if (_bodyWeightKg <= 0) return;
        final isEdgeHang = _sevenSecondHangMetrics.contains(widget.metricId);
        await appState.saveTestResult(
          metricId: widget.metricId,
          rawValue: _pctBW,
          unit: '%BW',
          addedLoadKg: _addedLoadKg,
          computedPctBW: _pctBW,
          edgeSizeMm: isEdgeHang ? _edgeSizeMm : null,
          gripType: isEdgeHang ? _gripType : null,
          hitTrueMax: _hitTrueMax,
        );
      } else {
        final value = double.tryParse(_numberController.text);
        if (value == null) return;
        final def = MetricDefinitions.all[widget.metricId]!;
        await appState.saveTestResult(
          metricId: widget.metricId,
          rawValue: value,
          unit: def.unit,
          hitTrueMax: _hitTrueMax,
        );
      }
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) _showError('Could not save result: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildBody(BuildContext context, MetricDef def) {
    final appState = context.read<AppState>();

    if (widget.metricId == MetricId.bodyComposition) {
      _numberController.text =
          appState.latestBody?.bodyFatPct?.toStringAsFixed(1) ?? '';
      return TextField(
        controller: _numberController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Body fat %'),
      );
    }

    if (widget.metricId == MetricId.experience) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _yearsClimbingController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Years climbing (total)',
              helperText: 'Not counting long breaks',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _sessionsPerWeekController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Sessions per week',
              helperText: 'Honest average over the last year',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _yearsOutdoorController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Years climbing outdoors',
              helperText: 'Weighted more heavily than gym time',
            ),
          ),
        ],
      );
    }

    // Campus reach is a rung number on a fixed ladder, not a free decimal.
    if (widget.metricId == MetricId.rfdContact) {
      return _RungPicker(
        value: _rungReached,
        onChanged: (v) => setState(() => _rungReached = v),
      );
    }

    // The front-lever ladder is a named scale, so pick the position rather
    // than typing a number whose meaning lives on another screen.
    if (widget.metricId == MetricId.core) {
      return _CoreLevelPicker(
        value: _coreLevel,
        onChanged: (v) => setState(() => _coreLevel = v),
      );
    }

    // Two measurements, because the recorded value is the difference.
    if (widget.metricId == MetricId.explosivePower) {
      return _DerivedTwoFieldInput(
        primaryController: _numberController,
        secondaryController: _secondaryController,
        primaryLabel: 'Catch height (cm)',
        secondaryLabel: 'Static reach (cm)',
        resultLabel: 'GAIN OVER STATIC REACH',
        compute: (catchHeight, staticReach) => catchHeight - staticReach,
        format: (gain) => '${gain.toStringAsFixed(0)} cm',
        invalidHint: 'Catch height must be above static reach',
      );
    }

    if (widget.metricId == MetricId.powerEndurance) {
      return _BoardMovesInput(controller: _numberController);
    }

    if (widget.metricId == MetricId.hipAbduction) {
      return TextField(
        controller: _numberController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Pubic symphysis to floor (cm)',
          helperText: 'Lower is better — converted to a % of your height',
        ),
      );
    }

    if (widget.metricId == MetricId.hipFlexion) {
      return _DerivedTwoFieldInput(
        primaryController: _numberController,
        secondaryController: _secondaryController,
        primaryLabel: 'Foot height off floor (cm)',
        secondaryLabel: 'Leg length: hip to floor (cm)',
        resultLabel: 'HIGH-STEP RANGE',
        compute: (foot, leg) => leg <= 0 ? 0 : foot / leg * 100,
        format: (pct) => '${pct.toStringAsFixed(0)} % of leg length',
        invalidHint: 'Enter both measurements',
      );
    }

    if (_loadBasedMetrics.contains(widget.metricId)) {
      final isEdgeHang = _sevenSecondHangMetrics.contains(widget.metricId);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isEdgeHang) ...[
            const HangTimer(targetSeconds: 7),
            const SizedBox(height: AppSpacing.xl),
            // Stacked, not side by side: at 320-400dp two dropdowns in a row
            // leave ~114dp each, which "Half crimp" overflows. Full-width
            // also lets the grip names stay readable rather than abbreviated.
            DropdownButtonFormField<double>(
              initialValue: _edgeSizeMm,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Edge size'),
              items: const [8, 10, 14, 20, 25]
                  .map((mm) => DropdownMenuItem(
                        value: mm.toDouble(),
                        child: Text('$mm mm'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _edgeSizeMm = v ?? 20),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<GripType>(
              initialValue: _gripType,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Grip'),
              items: GripType.values
                  .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(_gripLabels[g]!),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _gripType = v ?? GripType.halfCrimp),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          if (widget.metricId == MetricId.fingerEndurance)
            // The 4-minute 7:3 protocol needs an interval timer, which the
            // built-in single-shot stopwatch cannot provide — so say that
            // plainly instead of offering the wrong instrument.
            const _ProtocolNote(
              icon: Icons.timer_outlined,
              text: 'Run a 7 s on / 3 s off interval timer for 4 minutes, then '
                  'enter the load you were still holding in the last 30 '
                  'seconds.',
            ),
          if (widget.metricId == MetricId.fingerEndurance)
            const SizedBox(height: AppSpacing.xl),
          LoadCalculator(
            initialBodyWeightKg: appState.latestBody?.weightKg ?? 0,
            onChanged: (pct, bw, added) {
              _pctBW = pct;
              _bodyWeightKg = bw;
              _addedLoadKg = added;
            },
          ),
        ],
      );
    }

    if (_timedMetrics.contains(widget.metricId)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HangTimer(
            onStop: (seconds) {
              _numberController.text = seconds.toStringAsFixed(1);
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _numberController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Result (${def.unit})',
              helperText: 'Auto-filled by the timer above, or enter manually',
            ),
          ),
        ],
      );
    }

    // Generic numeric metrics: pullReps.
    return TextField(
      controller: _numberController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: 'Result (${def.unit})'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final def = MetricDefinitions.all[widget.metricId]!;
    final needsConfidenceToggle = widget.metricId != MetricId.bodyComposition &&
        widget.metricId != MetricId.experience;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(def.shortName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Full protocol for ${def.shortName}',
            onPressed: () => showProtocolSheet(context, def),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.sm,
            AppSpacing.gutter,
            AppSpacing.scrollBottomInset,
          ),
          children: [
            Text(
              def.summary,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ProtocolSteps(def: def),
            const SizedBox(height: AppSpacing.xl),
            _SectionLabel(def.recordText),
            _buildBody(context, def),
            if (needsConfidenceToggle) ...[
              const SizedBox(height: AppSpacing.xl),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Did you hit a true max?'),
                subtitle: const Text(
                    'Turn off if you think you had more in the tank — '
                    'widens your confidence range'),
                value: _hitTrueMax,
                onChanged: (v) => setState(() => _hitTrueMax = v),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _saving ? null : () => _save(context),
              child: _saving
                  // Sized to the label's line height so the button doesn't
                  // change height when it flips to the spinner.
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                  : const Text('Save result'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The protocol as a collapsible numbered list. Expanded by default —
/// you are standing in front of a hangboard, not browsing — but
/// collapsible once you know the test by heart.
class _ProtocolSteps extends StatefulWidget {
  final MetricDef def;

  const _ProtocolSteps({required this.def});

  @override
  State<_ProtocolSteps> createState() => _ProtocolStepsState();
}

class _ProtocolStepsState extends State<_ProtocolSteps> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md,
                  AppSpacing.md, AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'HOW TO TEST',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProtocolNote(
                    icon: Icons.inventory_2_outlined,
                    text: widget.def.equipment,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (var i = 0; i < widget.def.steps.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: i == widget.def.steps.length - 1
                              ? 0
                              : AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 20,
                            child: Text(
                              '${i + 1}.',
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(color: scheme.primary),
                            ),
                          ),
                          Expanded(
                            child: Text(widget.def.steps[i],
                                style: theme.textTheme.bodySmall),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ProtocolNote extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ProtocolNote({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// Sits directly above the input, saying which number belongs in it.
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.edit_outlined,
                size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Campus rungs 1-9 as a row of tap targets. The value is an ordinal on a
/// physical ladder, so a picker beats a text field: no decimals, no typos,
/// and the available range is visible.
class _RungPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _RungPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (var rung = 1; rung <= 9; rung++)
              Semantics(
                selected: rung == value,
                button: true,
                label: 'Rung $rung',
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => onChanged(rung),
                  borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: rung == value
                          ? scheme.primary
                          : scheme.surfaceContainer,
                      borderRadius:
                          BorderRadius.circular(AppTheme.controlRadius),
                      border: Border.all(
                        color: rung == value
                            ? scheme.primary
                            : scheme.outlineVariant,
                      ),
                    ),
                    child: Text(
                      '$rung',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: rung == value
                            ? scheme.onPrimary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Highest rung latched and held: $value',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// The front-lever ladder as a labelled slider. A slider fits an ordered
/// 0-9 progression better than a dropdown, and showing the position's name
/// underneath means the user never has to remember what "5" was.
class _CoreLevelPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _CoreLevelPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          child: Column(
            children: [
              Text(
                'LEVEL $value',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _coreLadder[value]!,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: scheme.onPrimaryContainer),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Slider(
          value: value.toDouble(),
          min: 0,
          max: 9,
          divisions: 9,
          label: 'Level $value',
          onChanged: (v) => onChanged(v.round()),
        ),
        Text(
          'Held cleanly for at least 5 seconds',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Board max-moves: the count, plus the board and problem it was measured
/// on. The problem identity is the whole point — the number only means
/// something when compared against itself.
class _BoardMovesInput extends StatelessWidget {
  final TextEditingController controller;

  const _BoardMovesInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Hand moves completed',
            helperText: 'Total across all laps, before you fell',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _ProtocolNote(
          icon: Icons.push_pin_outlined,
          text: 'Note down which board and which problem you used. Retesting '
              'on a different problem makes your progress line meaningless.',
        ),
      ],
    );
  }
}

/// Two measurements where the saved value is a function of both, with the
/// computed result shown live. Prevents the commonest recording error on
/// these tests: entering the raw measurement instead of the derived one.
class _DerivedTwoFieldInput extends StatefulWidget {
  final TextEditingController primaryController;
  final TextEditingController secondaryController;
  final String primaryLabel;
  final String secondaryLabel;
  final String resultLabel;
  final double Function(double primary, double secondary) compute;
  final String Function(double result) format;
  final String invalidHint;

  const _DerivedTwoFieldInput({
    required this.primaryController,
    required this.secondaryController,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.resultLabel,
    required this.compute,
    required this.format,
    required this.invalidHint,
  });

  @override
  State<_DerivedTwoFieldInput> createState() => _DerivedTwoFieldInputState();
}

class _DerivedTwoFieldInputState extends State<_DerivedTwoFieldInput> {
  double? get _result {
    final a = double.tryParse(widget.primaryController.text);
    final b = double.tryParse(widget.secondaryController.text);
    if (a == null || b == null) return null;
    final r = widget.compute(a, b);
    return r <= 0 ? null : r;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final result = _result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.secondaryController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: widget.secondaryLabel),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: widget.primaryController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(labelText: widget.primaryLabel),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: result == null
                ? scheme.surfaceContainer
                : scheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          child: Column(
            children: [
              Text(
                widget.resultLabel,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: result == null
                      ? scheme.onSurfaceVariant
                      : scheme.onPrimaryContainer,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                result == null ? widget.invalidHint : widget.format(result),
                textAlign: TextAlign.center,
                style: result == null
                    ? theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)
                    : theme.textTheme.headlineSmall
                        ?.copyWith(color: scheme.onPrimaryContainer),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
