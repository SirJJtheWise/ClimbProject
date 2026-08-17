import 'enums.dart';

/// A normalized 0-100 normative band used to convert a raw test value into
/// a percentile when the metric has no direct grade-benchmark table.
///
/// [worst] is the raw value mapped to percentile 0 and [best] the raw value
/// mapped to percentile 100. Direction is encoded by which is numerically
/// larger: for "lower is better" metrics (e.g. hip-abduction
/// distance-to-floor) set worst > best.
class NormativeRange {
  final double worst;
  final double best;

  const NormativeRange({required this.worst, required this.best});

  double percentileFor(double value) {
    final span = best - worst;
    if (span == 0) return 50;
    final pct = (value - worst) / span * 100;
    return pct.clamp(0, 100);
  }
}

class MetricDef {
  final MetricId id;
  final String name;
  final String shortName;
  final MetricGroup group;
  final MetricBucket bucket;
  final double weight;
  final String unit;
  final bool hasGradeTable;

  /// One sentence: what this test actually measures and why it earns a slot.
  /// Shown at the top of the input screen, where it has to answer "why am I
  /// doing this one?" before the user starts loading a belt.
  final String summary;

  /// What to have to hand before starting, so nobody discovers halfway
  /// through a warm-up that they need a partner or an interval timer.
  final String equipment;

  /// The protocol as ordered steps. Replaces the single dense paragraph
  /// these used to be — this is read one line at a time, mid-session, often
  /// with chalky hands.
  final List<String> steps;

  /// Exactly which number goes in the field. The commonest way a
  /// self-administered test goes wrong is recording the right measurement
  /// in the wrong form.
  final List<String> commonMistakes;

  /// How the recorded value is derived, spelled out next to the input.
  final String recordText;

  final String safetyNote;
  final String evidenceNote;
  final EvidenceStrength evidenceStrength;
  final NormativeRange? maleNormativeRange;
  final NormativeRange? femaleNormativeRange;

  const MetricDef({
    required this.id,
    required this.name,
    required this.shortName,
    required this.group,
    required this.bucket,
    required this.weight,
    required this.unit,
    required this.hasGradeTable,
    required this.summary,
    required this.equipment,
    required this.steps,
    required this.recordText,
    this.commonMistakes = const [],
    required this.safetyNote,
    required this.evidenceNote,
    required this.evidenceStrength,
    this.maleNormativeRange,
    this.femaleNormativeRange,
  });

  NormativeRange? normativeRangeFor(Sex sex) =>
      sex == Sex.male ? maleNormativeRange : femaleNormativeRange;
}
