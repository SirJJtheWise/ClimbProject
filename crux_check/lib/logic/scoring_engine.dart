import '../models/assessment.dart';
import '../models/enums.dart';

/// Pure, stateless scoring functions per the spec's "App Logic — Scoring
/// Algorithm" section. No I/O, no platform dependencies — safe to unit test
/// directly.
class ScoringEngine {
  ScoringEngine._();

  /// %BW = (bodyweight + added load) / bodyweight * 100. [addedLoadKg] may
  /// be negative (assisted / removed weight).
  static double pctBWFromLoad(double bodyWeightKg, double addedLoadKg) {
    return (bodyWeightKg + addedLoadKg) / bodyWeightKg * 100;
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

  /// Step 4: predicted / experience-typical grade.
  static double predictedGrade(double gradeCeiling, double gradeExperience) {
    return 0.86 * gradeCeiling + 0.14 * gradeExperience;
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
    final deficits = gradesByMetric.entries
        .map((e) => LimitingFactor(metricId: e.key, deficit: gradeCeiling - e.value))
        .where((d) => d.deficit > 0.25)
        .toList()
      ..sort((a, b) => b.deficit.compareTo(a.deficit));
    return deficits.take(top).toList();
  }
}
