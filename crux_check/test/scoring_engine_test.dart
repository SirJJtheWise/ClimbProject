import 'package:flutter_test/flutter_test.dart';

import 'package:crux_check/data/benchmarks.dart';
import 'package:crux_check/logic/assessment_calculator.dart';
import 'package:crux_check/logic/scoring_engine.dart';
import 'package:crux_check/models/enums.dart';
import 'package:crux_check/models/user.dart';

void main() {
  group('pctBWFromLoad', () {
    test('bodyweight only, no added load', () {
      expect(ScoringEngine.pctBWFromLoad(70, 0), 100);
    });

    test('added load increases %BW', () {
      expect(ScoringEngine.pctBWFromLoad(70, 35), 150);
    });

    test('negative (assisted) load decreases %BW', () {
      expect(ScoringEngine.pctBWFromLoad(70, -14), closeTo(80, 0.001));
    });
  });

  group('gradeFromBenchmarkTable (finger strength curve)', () {
    final table = {
      for (final g in Benchmarks.fingerStrengthOneArmEquivMale.keys)
        g: Benchmarks.fingerStrengthCurveFor(Sex.male, g)
    };

    test('exact anchor points map to whole grades', () {
      expect(ScoringEngine.gradeFromBenchmarkTable(table, 49), closeTo(4, 0.01));
      expect(ScoringEngine.gradeFromBenchmarkTable(table, 55), closeTo(5, 0.01));
    });

    test('interpolates between anchors', () {
      final mid = ScoringEngine.gradeFromBenchmarkTable(table, 52);
      expect(mid, closeTo(4.5, 0.01));
    });

    test('extrapolates below the lowest anchor', () {
      final grade = ScoringEngine.gradeFromBenchmarkTable(table, 20);
      expect(grade, lessThan(0));
    });

    test('extrapolates above the highest anchor', () {
      final grade = ScoringEngine.gradeFromBenchmarkTable(table, 130);
      expect(grade, greaterThan(17));
    });
  });

  group('two-arm <-> one-arm-equivalent conversion', () {
    test('V4 anchor point round-trips', () {
      final oneArm = Benchmarks.twoArmToOneArmEquiv(128);
      expect(oneArm, closeTo(49, 0.01));
      expect(Benchmarks.oneArmEquivToTwoArm(oneArm), closeTo(128, 0.01));
    });
  });

  group('percentileToGrade', () {
    test('50th percentile returns the anchor grade', () {
      expect(ScoringEngine.percentileToGrade(50, 7), closeTo(7, 0.001));
    });

    test('100th percentile returns anchor + spread', () {
      expect(ScoringEngine.percentileToGrade(100, 7, spread: 3), closeTo(10, 0.001));
    });

    test('0th percentile returns anchor - spread', () {
      expect(ScoringEngine.percentileToGrade(0, 7, spread: 3), closeTo(4, 0.001));
    });
  });

  group('weightedMeanGrade', () {
    test('equal weights average evenly', () {
      final mean = ScoringEngine.weightedMeanGrade(
        {MetricId.fingerStrength: 5, MetricId.pullingStrength: 7},
        {MetricId.fingerStrength: 1, MetricId.pullingStrength: 1},
      );
      expect(mean, closeTo(6, 0.001));
    });

    test('renormalizes over only the supplied metrics', () {
      final mean = ScoringEngine.weightedMeanGrade(
        {MetricId.fingerStrength: 8},
        {MetricId.fingerStrength: 30, MetricId.pullingStrength: 12},
      );
      expect(mean, closeTo(8, 0.001));
    });
  });

  test('predictedGrade blends ceiling and experience at 0.86/0.14', () {
    expect(ScoringEngine.predictedGrade(8, 5), closeTo(7.58, 0.001));
  });

  group('confidenceBandWidth', () {
    test('base band is 1.0 grade below V10 with no penalties', () {
      final band = ScoringEngine.confidenceBandWidth(
        predictedGrade: 8,
        missingHighWeightMetricCount: 0,
        metricGradeStdDev: 0,
      );
      expect(band, closeTo(1.0, 0.001));
    });

    test('widens above V10, for missing/low-confidence metrics, and scatter', () {
      final band = ScoringEngine.confidenceBandWidth(
        predictedGrade: 12,
        missingHighWeightMetricCount: 2,
        metricGradeStdDev: 2,
        lowConfidenceMetricCount: 1,
      );
      // 1.0 base + (12-10)*0.5 + 2*0.25 + 1*0.15 + 2*0.3 = 3.25
      expect(band, closeTo(3.25, 0.001));
    });
  });

  test('standardDeviation of a simple set', () {
    expect(ScoringEngine.standardDeviation([5, 7]), closeTo(1, 0.001));
  });

  test('limitingFactors surfaces the largest deficits only', () {
    final factors = ScoringEngine.limitingFactors(8, {
      MetricId.fingerStrength: 8, // no deficit, excluded
      MetricId.pullingStrength: 5, // deficit 3
      MetricId.core: 7.5, // deficit 0.5
      MetricId.lockOff: 8.2, // negative deficit, excluded
    });
    expect(factors.length, 2);
    expect(factors.first.metricId, MetricId.pullingStrength);
    expect(factors.first.deficit, closeTo(3, 0.001));
  });

  group('AssessmentCalculator.compute (integration)', () {
    test('produces a sane assessment from finger-strength data alone', () {
      final user = AppUser(sex: Sex.male, heightCm: 178, armSpanCm: 182);
      // Two-arm 7s hang at 128 %BW two-arm -> one-arm-equiv 49 %BW -> V4 anchor.
      final result = AssessmentCalculator.compute(
        user: user,
        rawValues: {MetricId.fingerStrength: 128},
      );

      expect(result.gradesByMetric[MetricId.fingerStrength], closeTo(4, 0.01));
      // Ceiling also folds in the auto-computed ape-index metric (small
      // weight, nudges it slightly off the finger-strength-only figure).
      expect(result.assessment.gradeCeiling, closeTo(4, 0.1));
      // No experience data supplied -> gradeExperience falls back to ceiling.
      expect(result.assessment.gradeExperience, result.assessment.gradeCeiling);
      expect(result.assessment.confidenceLow, lessThan(result.assessment.gradeComposite));
      expect(result.assessment.confidenceHigh, greaterThan(result.assessment.gradeComposite));
      expect(result.anchorIsFallback, isFalse);
    });

    test('falls back to a default anchor when no strength data is supplied', () {
      final user = AppUser(sex: Sex.female, heightCm: 165, armSpanCm: 163);
      final result = AssessmentCalculator.compute(
        user: user,
        rawValues: {MetricId.core: 5},
      );
      expect(result.anchorIsFallback, isTrue);
      expect(result.anchorGrade, 5.0);
    });

    test('weaker pulling strength than fingers is surfaced as a limiter', () {
      final user = AppUser(sex: Sex.male, heightCm: 178, armSpanCm: 182);
      final result = AssessmentCalculator.compute(
        user: user,
        rawValues: {
          MetricId.fingerStrength: 189, // one-arm-equiv ~= 79.5 -> ~V9
          MetricId.pullingStrength: Benchmarks.pullUpCurveFor(Sex.male, 4), // V4
        },
      );
      expect(result.assessment.limitingFactors, isNotEmpty);
      expect(
        result.assessment.limitingFactors.first.metricId,
        MetricId.pullingStrength,
      );
    });
  });
}
