import '../data/benchmarks.dart';
import '../data/metric_definitions.dart';
import '../models/assessment.dart';
import '../models/enums.dart';
import '../models/user.dart';
import 'scoring_engine.dart';

/// Metrics whose absence most widens the confidence band.
const Set<MetricId> _highWeightMetrics = {
  MetricId.fingerStrength,
  MetricId.pullingStrength,
  MetricId.rfdContact,
  MetricId.bodyComposition,
};

/// Tier 1 — the metrics with enough independent predictive validity to set a
/// ceiling on their own. The Softmin runs over exactly these, so a weak one
/// drags the estimate down instead of being averaged away.
const Set<MetricId> _tier1Metrics = {
  MetricId.fingerStrength,
  MetricId.pullingStrength,
  MetricId.rfdContact,
};

/// The buckets that make up the "physical ceiling" (everything except
/// experience/skill).
const Set<MetricBucket> _ceilingBuckets = {
  MetricBucket.trainablePhysical,
  MetricBucket.bodyComposition,
  MetricBucket.fixedAnthropometric,
};

/// Measured and displayed, but never scored. Ape index explains under 4% of
/// performance variance once functional strength is in the model, and it
/// auto-fills from the profile — leaving it in the ceiling meant a user who
/// had tested nothing at all still got a grade computed from their arm span.
const Set<MetricId> _unscoredMetrics = {MetricId.apeIndex};

class AssessmentResult {
  final Assessment assessment;
  final Map<MetricId, double> gradesByMetric;
  final double anchorGrade;
  final bool anchorIsFallback;

  /// True when nothing scorable has been recorded. The profile alone cannot
  /// predict a grade, so callers show an empty state rather than a number.
  final bool insufficientData;

  const AssessmentResult({
    required this.assessment,
    required this.gradesByMetric,
    required this.anchorGrade,
    required this.anchorIsFallback,
    this.insufficientData = false,
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

    // Ape index auto-fills, so "the map is non-empty" is not the same as
    // "something was tested".
    final hasScorableInput = effectiveRaw.keys.any(
      (id) => !_unscoredMetrics.contains(id),
    );

    // --- Anchor grade (finger strength is primary; pulling is fallback) ---
    double anchorGrade;
    bool anchorIsFallback = false;
    double? fingerStrengthGrade;
    if (effectiveRaw.containsKey(MetricId.fingerStrength)) {
      final oneArmEquiv = Benchmarks.twoArmToOneArmEquiv(
        effectiveRaw[MetricId.fingerStrength]!,
      );
      final table = {
        for (final g in Benchmarks.fingerStrengthOneArmEquivMale.keys)
          g: Benchmarks.fingerStrengthCurveFor(sex, g),
      };
      fingerStrengthGrade = ScoringEngine.gradeFromBenchmarkTable(
        table,
        oneArmEquiv,
      );
      anchorGrade = fingerStrengthGrade;
    } else if (effectiveRaw.containsKey(MetricId.pullingStrength)) {
      final table = {
        for (final g in Benchmarks.pullUpPctBWMale.keys)
          g: Benchmarks.pullUpCurveFor(sex, g),
      };
      anchorGrade = ScoringEngine.gradeFromBenchmarkTable(
        table,
        effectiveRaw[MetricId.pullingStrength]!,
      );
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
          g: Benchmarks.pullUpCurveFor(sex, g),
      };
      gradesByMetric[MetricId.pullingStrength] =
          ScoringEngine.plateauPullingGrade(
            ScoringEngine.gradeFromBenchmarkTable(
              table,
              effectiveRaw[MetricId.pullingStrength]!,
            ),
          );
    }

    // Percentile-scored metrics. These express "better or worse than your
    // anchor suggests", which is why they cannot anchor a grade themselves.
    final percentilesByMetric = <MetricId, double>{};
    for (final def in MetricDefinitions.all.values) {
      if (def.hasGradeTable) continue; // already handled above
      final raw = effectiveRaw[def.id];
      if (raw == null) continue;
      final range = def.normativeRangeFor(sex);
      final percentile = def.id == MetricId.experience
          ? raw.clamp(0, 100).toDouble()
          : (range?.percentileFor(raw) ?? 50);
      percentilesByMetric[def.id] = percentile;
      gradesByMetric[def.id] = ScoringEngine.percentileToGrade(
        percentile,
        anchorGrade,
      );
    }

    // --- Physical ceiling: Softmin over Tier 1, modified by Tier 2 ---
    //
    // Physical attributes are not compensatory. Averaging lets a strong
    // secondary metric mask a critical deficit, so the ceiling is a smooth
    // minimum over the anchors and everything else only nudges it.
    final tier1Grades = <MetricId, double>{};
    final tier1Weights = <MetricId, double>{};
    final tier2Multipliers = <MetricId, double>{};
    final tier2Weights = <MetricId, double>{};
    for (final entry in gradesByMetric.entries) {
      if (_unscoredMetrics.contains(entry.key)) continue;
      final def = MetricDefinitions.all[entry.key]!;
      if (!_ceilingBuckets.contains(def.bucket) || def.weight <= 0) continue;
      if (_tier1Metrics.contains(entry.key)) {
        tier1Grades[entry.key] = entry.value;
        tier1Weights[entry.key] = def.weight;
      } else {
        tier2Multipliers[entry.key] = ScoringEngine.tier2Multiplier(
          percentilesByMetric[entry.key] ?? 50,
        );
        tier2Weights[entry.key] = def.weight;
      }
    }

    final softminCeiling = tier1Grades.isEmpty
        ? anchorGrade
        : ScoringEngine.softminGrade(tier1Grades, tier1Weights);

    // Averaged, not compounded: eight multipliers multiplied together would
    // run away to the bounds on any lopsided profile.
    var tier2Factor = 1.0;
    if (tier2Multipliers.isNotEmpty) {
      double sumW = 0;
      double sumWM = 0;
      for (final entry in tier2Multipliers.entries) {
        final w = tier2Weights[entry.key]!;
        sumW += w;
        sumWM += w * entry.value;
      }
      if (sumW > 0) tier2Factor = sumWM / sumW;
    }
    final gradeCeiling = softminCeiling * tier2Factor;

    // --- Experience scales the ceiling, it does not average against it ---
    final gradeExperience = gradesByMetric[MetricId.experience] ?? gradeCeiling;
    final experienceIndex = effectiveRaw[MetricId.experience];
    final predicted = experienceIndex == null
        ? gradeCeiling
        : gradeCeiling * ScoringEngine.experienceMultiplier(experienceIndex);

    // --- Confidence band ---
    //
    // Scatter is measured across Tier 1 only: those are the grades that are
    // supposed to agree with each other, and a disagreement between them is
    // what genuinely makes a prediction uncertain.
    final missingHighWeight = _highWeightMetrics
        .where((m) => !effectiveRaw.containsKey(m))
        .length;
    final stdDev = ScoringEngine.standardDeviation(tier1Grades.values.toList());
    final scoredMetrics = {...tier1Grades.keys, ...tier2Multipliers.keys};
    final lowConfidenceInCeiling = lowConfidenceMetricIds
        .where(scoredMetrics.contains)
        .length;
    final band = ScoringEngine.confidenceBandWidth(
      predictedGrade: predicted,
      missingHighWeightMetricCount: missingHighWeight,
      metricGradeStdDev: stdDev,
      lowConfidenceMetricCount: lowConfidenceInCeiling,
    );
    final confidenceLow = (predicted - band).clamp(0.0, 17.0);
    final confidenceHigh = (predicted + band).clamp(0.0, 17.0);

    // --- Limiting factors ---
    //
    // Measured against the weighted *mean*, not against the Softmin ceiling.
    // The ceiling already sits down at the weakest metric, so comparing
    // against it would show nothing as a weakness — the deficit that matters
    // is the one dragging the Softmin down in the first place.
    final scoredGrades = {
      for (final id in scoredMetrics) id: gradesByMetric[id]!,
    };
    final scoredWeights = {
      for (final id in scoredMetrics)
        id: MetricDefinitions.all[id]!.weight.toDouble(),
    };
    final referenceMean = scoredGrades.isEmpty
        ? gradeCeiling
        : ScoringEngine.weightedMeanGrade(scoredGrades, scoredWeights);
    final limiting = ScoringEngine.limitingFactors(referenceMean, scoredGrades);

    // --- Per-metric percentiles ---
    //
    // Where a normative range exists the raw percentile is reported as-is, so
    // the bars show standing in the climbing population rather than standing
    // relative to your own predicted grade. Previously these were re-derived
    // from the grade gap, which shifted every bar by (anchor - predicted).
    // The two table-scored anchors have no normative range, so they keep the
    // grade-relative reading.
    final percentiles = gradesByMetric.entries.map((e) {
      final normative = percentilesByMetric[e.key];
      final pct =
          normative ?? (50 + (e.value - predicted) / 3 * 50).clamp(0.0, 100.0);
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
      missingMetricCount: MetricDefinitions.all.keys
          .where(
            (id) =>
                !_unscoredMetrics.contains(id) && !effectiveRaw.containsKey(id),
          )
          .length,
    );

    return AssessmentResult(
      assessment: assessment,
      gradesByMetric: gradesByMetric,
      anchorGrade: anchorGrade,
      anchorIsFallback: anchorIsFallback,
      insufficientData: !hasScorableInput,
    );
  }
}
