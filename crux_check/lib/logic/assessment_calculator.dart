import '../data/benchmarks.dart';
import '../data/metric_definitions.dart';
import '../models/assessment.dart';
import '../models/enums.dart';
import '../models/user.dart';
import 'scoring_engine.dart';

/// Metrics whose absence most widens the confidence band (weight >= 6).
const Set<MetricId> _highWeightMetrics = {
  MetricId.fingerStrength,
  MetricId.pullingStrength,
  MetricId.rfdContact,
  MetricId.bodyComposition,
};

/// The buckets that make up the "physical ceiling" (everything except
/// experience/skill).
const Set<MetricBucket> _ceilingBuckets = {
  MetricBucket.trainablePhysical,
  MetricBucket.bodyComposition,
  MetricBucket.fixedAnthropometric,
};

class AssessmentResult {
  final Assessment assessment;
  final Map<MetricId, double> gradesByMetric;
  final double anchorGrade;
  final bool anchorIsFallback;

  const AssessmentResult({
    required this.assessment,
    required this.gradesByMetric,
    required this.anchorGrade,
    required this.anchorIsFallback,
  });
}

/// Raw, per-metric input values already expressed in each metric's
/// canonical unit (see [MetricDef.unit]) — e.g. %BW for finger/pull
/// strength (already converted from added load via
/// [ScoringEngine.pctBWFromLoad]), seconds for lock-off, cm for explosive
/// power, the 0-9 ladder level for core, etc. Two-arm hang %BW for
/// fingerStrength is converted to one-arm-equivalent internally.
class AssessmentCalculator {
  AssessmentCalculator._();

  static AssessmentResult compute({
    required AppUser user,
    required Map<MetricId, double> rawValues,
    Set<MetricId> lowConfidenceMetricIds = const {},
  }) {
    final sex = user.sex;

    // Auto-computed inputs the UI doesn't need to supply explicitly.
    final effectiveRaw = Map<MetricId, double>.from(rawValues);
    effectiveRaw.putIfAbsent(MetricId.apeIndex, () => user.apeIndexCm);

    // --- Anchor grade (finger strength is primary; pulling is fallback) ---
    double anchorGrade;
    bool anchorIsFallback = false;
    double? fingerStrengthGrade;
    if (effectiveRaw.containsKey(MetricId.fingerStrength)) {
      final oneArmEquiv =
          Benchmarks.twoArmToOneArmEquiv(effectiveRaw[MetricId.fingerStrength]!);
      final table = {
        for (final g in Benchmarks.fingerStrengthOneArmEquivMale.keys)
          g: Benchmarks.fingerStrengthCurveFor(sex, g)
      };
      fingerStrengthGrade =
          ScoringEngine.gradeFromBenchmarkTable(table, oneArmEquiv);
      anchorGrade = fingerStrengthGrade;
    } else if (effectiveRaw.containsKey(MetricId.pullingStrength)) {
      final table = {
        for (final g in Benchmarks.pullUpPctBWMale.keys)
          g: Benchmarks.pullUpCurveFor(sex, g)
      };
      anchorGrade = ScoringEngine.gradeFromBenchmarkTable(
          table, effectiveRaw[MetricId.pullingStrength]!);
    } else {
      anchorGrade = 5.0;
      anchorIsFallback = true;
    }

    // --- Per-metric grade-equivalents ---
    final gradesByMetric = <MetricId, double>{};

    if (fingerStrengthGrade != null) {
      gradesByMetric[MetricId.fingerStrength] = fingerStrengthGrade;
    }
    if (effectiveRaw.containsKey(MetricId.pullingStrength)) {
      final table = {
        for (final g in Benchmarks.pullUpPctBWMale.keys)
          g: Benchmarks.pullUpCurveFor(sex, g)
      };
      gradesByMetric[MetricId.pullingStrength] = ScoringEngine
          .gradeFromBenchmarkTable(table, effectiveRaw[MetricId.pullingStrength]!);
    }

    for (final def in MetricDefinitions.all.values) {
      if (def.hasGradeTable) continue; // already handled above
      final raw = effectiveRaw[def.id];
      if (raw == null) continue;
      final range = def.normativeRangeFor(sex);
      final percentile = def.id == MetricId.experience
          ? raw.clamp(0, 100)
          : (range?.percentileFor(raw) ?? 50);
      gradesByMetric[def.id] =
          ScoringEngine.percentileToGrade(percentile.toDouble(), anchorGrade);
    }

    // --- Physical ceiling (excludes experience bucket) ---
    final ceilingGrades = <MetricId, double>{};
    final ceilingWeights = <MetricId, double>{};
    for (final entry in gradesByMetric.entries) {
      final def = MetricDefinitions.all[entry.key]!;
      if (_ceilingBuckets.contains(def.bucket) && def.weight > 0) {
        ceilingGrades[entry.key] = entry.value;
        ceilingWeights[entry.key] = def.weight;
      }
    }
    final gradeCeiling = ceilingGrades.isEmpty
        ? anchorGrade
        : ScoringEngine.weightedMeanGrade(ceilingGrades, ceilingWeights);

    // --- Experience-typical prediction ---
    final gradeExperience =
        gradesByMetric[MetricId.experience] ?? gradeCeiling;
    final predicted =
        ScoringEngine.predictedGrade(gradeCeiling, gradeExperience);

    // --- Confidence band ---
    final missingHighWeight = _highWeightMetrics
        .where((m) => !effectiveRaw.containsKey(m))
        .length;
    final stdDev =
        ScoringEngine.standardDeviation(ceilingGrades.values.toList());
    final lowConfidenceInCeiling =
        lowConfidenceMetricIds.where(ceilingGrades.containsKey).length;
    final band = ScoringEngine.confidenceBandWidth(
      predictedGrade: predicted,
      missingHighWeightMetricCount: missingHighWeight,
      metricGradeStdDev: stdDev,
      lowConfidenceMetricCount: lowConfidenceInCeiling,
    );
    final confidenceLow = (predicted - band).clamp(0.0, 17.0);
    final confidenceHigh = (predicted + band).clamp(0.0, 17.0);

    // --- Limiting factors (physical-ceiling components only) ---
    final limiting =
        ScoringEngine.limitingFactors(gradeCeiling, ceilingGrades);

    // --- Per-metric percentiles for the radar chart, relative to the
    // predicted grade (spec step 7). ---
    final percentiles = gradesByMetric.entries.map((e) {
      final pct = (50 + (e.value - predicted) / 3 * 50).clamp(0.0, 100.0);
      return MetricPercentile(
        metricId: e.key,
        percentile: pct,
        gradeEquivalent: e.value,
      );
    }).toList();

    final assessment = Assessment(
      userId: user.id ?? 0,
      date: DateTime.now(),
      gradeComposite: predicted,
      gradeCeiling: gradeCeiling,
      gradeExperience: gradeExperience,
      confidenceLow: confidenceLow,
      confidenceHigh: confidenceHigh,
      perMetricPercentiles: percentiles,
      limitingFactors: limiting,
      missingMetricCount:
          MetricDefinitions.all.length - effectiveRaw.length,
    );

    return AssessmentResult(
      assessment: assessment,
      gradesByMetric: gradesByMetric,
      anchorGrade: anchorGrade,
      anchorIsFallback: anchorIsFallback,
    );
  }
}
