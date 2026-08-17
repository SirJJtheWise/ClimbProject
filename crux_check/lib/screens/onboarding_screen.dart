import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/user.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final AppUser? existingUser;
  final double? existingWeightKg;

  const OnboardingScreen({super.key, this.existingUser, this.existingWeightKg});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  late Sex _sex = widget.existingUser?.sex ?? Sex.male;
  late GradeScale _gradeScale =
      widget.existingUser?.gradeScalePref ?? GradeScale.v;
  late DateTime? _birthdate = widget.existingUser?.birthdate;
  late final _heightController = TextEditingController(
      text: widget.existingUser?.heightCm.toStringAsFixed(1) ?? '');
  late final _armSpanController = TextEditingController(
      text: widget.existingUser?.armSpanCm.toStringAsFixed(1) ?? '');
  late final _weightController = TextEditingController(
      text: widget.existingWeightKg?.toStringAsFixed(1) ?? '');

  bool get _isEditing => widget.existingUser != null;

  @override
  void dispose() {
    _heightController.dispose();
    _armSpanController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthdate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final appState = context.read<AppState>();
    final user = AppUser(
      id: widget.existingUser?.id,
      sex: _sex,
      birthdate: _birthdate,
      heightCm: double.parse(_heightController.text),
      armSpanCm: double.parse(_armSpanController.text),
      gradeScalePref: _gradeScale,
    );
    try {
      await appState.saveProfile(user);
      await appState.saveBodyMeasurement(
        weightKg: double.parse(_weightController.text),
      );
      if (_isEditing && mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save profile: $e')),
      );
    }
  }

  String? _requiredPositiveNumber(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final n = double.tryParse(v);
    if (n == null || n <= 0) return 'Enter a valid number';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit profile' : 'Set up')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.sm,
              AppSpacing.gutter,
              AppSpacing.scrollBottomInset,
            ),
            children: [
              if (!_isEditing) ...[
                Text('Crux Check', style: theme.textTheme.displaySmall),
                const SizedBox(height: AppSpacing.sm),
              ],
              // Capped measure — full-width prose is unreadable on a
              // tablet, and this paragraph sets up the whole product.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  'A few basics to anchor your grade estimate. All physical '
                  'tests are optional and can be added later.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              const _FieldLabel('Sex'),
              SegmentedButton<Sex>(
                segments: const [
                  ButtonSegment(value: Sex.male, label: Text('Male')),
                  ButtonSegment(value: Sex.female, label: Text('Female')),
                ],
                selected: {_sex},
                onSelectionChanged: (s) => setState(() => _sex = s.first),
              ),
              const _FieldLabel('Measurements'),
              InkWell(
                borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                onTap: _pickBirthdate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Birthdate (optional)',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    _birthdate == null
                        ? 'Not set'
                        : '${_birthdate!.year}-${_birthdate!.month.toString().padLeft(2, '0')}-${_birthdate!.day.toString().padLeft(2, '0')}',
                    style: _birthdate == null
                        ? TextStyle(color: scheme.onSurfaceVariant)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _heightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Height (cm)'),
                validator: _requiredPositiveNumber,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _armSpanController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Arm span (cm)',
                  helperText: 'Fingertip to fingertip, arms out horizontal',
                ),
                validator: _requiredPositiveNumber,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                decoration:
                    const InputDecoration(labelText: 'Current bodyweight (kg)'),
                validator: _requiredPositiveNumber,
              ),
              const _FieldLabel('Preferred grade scale'),
              SegmentedButton<GradeScale>(
                segments: const [
                  ButtonSegment(value: GradeScale.v, label: Text('V-scale')),
                  ButtonSegment(value: GradeScale.font, label: Text('Font')),
                ],
                selected: {_gradeScale},
                onSelectionChanged: (s) => setState(() => _gradeScale = s.first),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FilledButton(
                onPressed: _submit,
                child:
                    Text(_isEditing ? 'Save changes' : 'Continue to test hub'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Group label above a cluster of controls, carrying the section tier of
/// the spacing scale with it so every form on this screen breathes the
/// same way.
class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
          top: AppSpacing.xl, bottom: AppSpacing.md),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
