import 'dart:math' as math;

import '../models/assessment.dart';
import '../models/enums.dart';

/// Pure, stateless scoring functions per the spec's "App Logic — Scoring
/// Algorithm" section. No I/O, no platform dependencies — safe to unit test
/// directly.
class ScoringEngine {
  ScoringEngine._();

  /// Body mass the %BW benchmark curves in [Benchmarks] are taken to be
  /// calibrated at. Only the *deviation* from this mass is corrected, so the
  /// curves stay valid as written.
  static const double referenceMassKg = 70;

  /// Softmin temperature. Picked so the canonical bottleneck profile — V12
  /// pulling, V12 contact strength, V4 fingers — resolves to about V4.3
  /// instead of the ~V9.3 a weighted mean reports.
  static const double softminBeta = 0.5;

  /// %BW = (bodyweight + added load) / bodyweight * 100. [addedLoadKg] may
  /// be negative (assisted / removed weight).
  static double pctBWFromLoad(double bodyWeightKg, double addedLoadKg) {
    return (bodyWeightKg + addedLoadKg) / bodyWeightKg * 100;
  }

  /// Corrects a %BW figure for body size.
  ///
  /// Muscle force scales with cross-sectional area (~m^0.67) while %BW
  /// divides by m^1, so a raw %BW number systematically flatters lighter
  /// climbers and penalises heavier ones. Since S ∝ F/m^0.67 and F ∝ m·pctBW,
  /// the size-independent index is proportional to pctBW·m^0.33.
  ///
  /// Expressed here as "the %BW an equally strong [referenceMassKg] climber
  /// would show", which applies the correction without invalidating the
  /// existing %BW-denominated benchmark curves. Returns [pctBW] unchanged
  /// when bodyweight is unknown.
  static double allometricPctBW(double pctBW, double bodyMassKg) {
    if (bodyMassKg <= 0) return pctBW;
    return pctBW * math.pow(bodyMassKg / referenceMassKg, 0.33).toDouble();
  }

  /// Weighted Softmin ("smooth minimum") over grade-equivalents.
  ///
  /// Climbing is bottleneck-limited: a climber with V12 pulling and V4
  /// fingers climbs near V4, because elite pulling cannot be applied to a
  /// hold the fingers will not hold. A weighted mean reports ~V9 for that
  /// profile and hides the deficit. This biases hard toward the weakest
  /// input while still letting strong metrics contribute a little:
  ///
  ///   J = Σ wᵢ·xᵢ·exp(-β·xᵢ) / Σ wⱼ·exp(-β·xⱼ)
  ///
  /// [beta] is the temperature — 0 collapses to the weighted mean, larger
  /// values approach a hard minimum.
  static double softminGrade(
    Map<MetricId, double> gradesByMetric,
    Map<MetricId, double> weightsByMetric, {
    double beta = softminBeta,
  }) {
    if (gradesByMetric.isEmpty) return 0;
    // Factored around the smallest grade so the exponentials stay in (0, 1]
    // and cannot overflow on a grade the benchmark table extrapolated below
    // V0. The factor cancels between numerator and denominator.
    final minGrade = gradesByMetric.values.reduce(math.min);
    double numerator = 0;
    double denominator = 0;
    for (final entry in gradesByMetric.entries) {
      final w = weightsByMetric[entry.key] ?? 0;
      if (w <= 0) continue;
      final term = w * math.exp(-beta * (entry.value - minGrade));
      numerator += term * entry.value;
      denominator += term;
    }
    if (denominator == 0) return 0;
    return numerator / denominator;
  }

  /// Tier 2 metrics modify the ceiling instead of setting it: they lack the
  /// predictive validity to anchor a grade on their own, but a genuinely
  /// weak core or hip range still costs grades. Maps a 0-100 normative
  /// percentile onto 0.90..1.10, centred so an average result changes
  /// nothing.
  static double tier2Multiplier(double percentile) {
    return 0.90 + (percentile.clamp(0, 100) / 100) * 0.20;
  }

  /// Experience optimises the application of physical traits; it does not
  /// generate force. So it scales the physical ceiling rather than being
  /// averaged into it, on a log curve — the first seasons teach far more
  /// than the tenth — bounded to 0.92..1.05 so it can never overwrite a
  /// physical bottleneck.
  static double experienceMultiplier(double experienceIndex) {
    final x = experienceIndex.clamp(0.0, 100.0) / 100;
    final curve = math.log(1 + 9 * x) / math.ln10;
    return 0.92 + curve * 0.13;
  }

  /// Pulling strength stops tracking grade once it plateaus (male ~160-165
  /// %BW, female ~135-140, both around V10): across the four grades above
  /// that, average pulling barely moves. Compresses the excess so a big
  /// weighted pull-up cannot keep inflating the pulling sub-grade.
  static double plateauPullingGrade(double grade, {double plateau = 10}) {
    if (grade <= plateau) return grade;
    return plateau + (grade - plateau) * 0.4;
  }

  /// Inverts a monotonically-increasing grade -> value benchmark table to
  /// recover a fractional grade-equivalent for a measured [value], linearly
  /// interpolating between rows and linearly extrapolating past the ends
  /// using the slope of the nearest segment.
  static double gradeFromBenchmarkTable(Map<int, double> table, double value) {
    final grades = table.keys.toList()..sort();
    final firstV = table[grades.first]!;
    final lastV = table[grades.last]!;

    if (value <= firstV) {
      final g0 = grades[0], g1 = grades[1];
      final v0 = table[g0]!, v1 = table[g1]!;
      final slope = (v1 - v0) / (g1 - g0);
      return g0 + (value - v0) / slope;
    }
    if (value >= lastV) {
      final gN = grades[grades.length - 1], gNm1 = grades[grades.length - 2];
      final vN = table[gN]!, vNm1 = table[gNm1]!;
      final slope = (vN - vNm1) / (gN - gNm1);
      return gN + (value - vN) / slope;
    }
    for (var i = 0; i < grades.length - 1; i++) {
      final g0 = grades[i], g1 = grades[i + 1];
      final v0 = table[g0]!, v1 = table[g1]!;
      if (value >= v0 && value <= v1) {
        final t = (value - v0) / (v1 - v0);
        return g0 + t * (g1 - g0);
      }
    }
    return grades.last.toDouble();
  }

  /// Percentile (0-100) -> grade-equivalent, centered on [anchorGrade]
  /// (the user's finger-strength grade), with percentile 50 mapping to the
  /// anchor and 0/100 mapping to anchor -/+ [spread] grades.
  static double percentileToGrade(
    double percentile,
    double anchorGrade, {
    double spread = 3,
  }) {
    return anchorGrade + (percentile - 50) / 50 * spread;
  }

  /// G_composite = sum(w_i * G_i) / sum(w_i), renormalized over only the
  /// metrics actually supplied (partial input still yields an estimate).
  static double weightedMeanGrade(
    Map<MetricId, double> gradesByMetric,
    Map<MetricId, double> weightsByMetric,
  ) {
    double sumW = 0;
    double sumWG = 0;
    for (final entry in gradesByMetric.entries) {
      final w = weightsByMetric[entry.key] ?? 0;
      sumW += w;
      sumWG += w * entry.value;
    }
    if (sumW == 0) return 0;
    return sumWG / sumW;
  }

  /// Step 5: confidence half-width, in V-grades, around [predictedGrade].
  ///
  /// Widens for: grades above V10 (encodes the measured R² decline at
  /// elite/higher-elite bouldering), each missing high-weight metric, and
  /// scatter (std-dev) across the individual metric grade-equivalents.
  static double confidenceBandWidth({
    required double predictedGrade,
    required int missingHighWeightMetricCount,
    required double metricGradeStdDev,
    int lowConfidenceMetricCount = 0,
  }) {
    var band = 1.0;
    if (predictedGrade > 10) band += (predictedGrade - 10) * 0.5;
    band += missingHighWeightMetricCount * 0.25;
    band += lowConfidenceMetricCount * 0.15;
    band += metricGradeStdDev * 0.3;
    return band;
  }

  static double standardDeviation(List<double> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
        values.length;
    return variance <= 0 ? 0 : _sqrt(variance);
  }

  static double _sqrt(double x) {
    if (x == 0) return 0;
    var guess = x;
    for (var i = 0; i < 20; i++) {
      guess = 0.5 * (guess + x / guess);
    }
    return guess;
  }

  /// Step 6: limiting-factor detection. deficit_i = ceiling - G_i; the
  /// largest positive deficits are weaknesses. Only surfaces genuine
  /// weaknesses (deficit > 0.25 grades) and caps the count at [top].
  static List<LimitingFactor> limitingFactors(
    double gradeCeiling,
    Map<MetricId, double> gradesByMetric, {
    int top = 3,
  }) {
    final deficits =
        gradesByMetric.entries
            .map(
              (e) => LimitingFactor(
                metricId: e.key,
                deficit: gradeCeiling - e.value,
              ),
            )
            .where((d) => d.deficit > 0.25)
            .toList()
          ..sort((a, b) => b.deficit.compareTo(a.deficit));
    return deficits.take(top).toList();
  }
}
