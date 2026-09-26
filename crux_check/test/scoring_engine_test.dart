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
        g: Benchmarks.fingerStrengthCurveFor(Sex.male, g),
    };

    test('exact anchor points map to whole grades', () {
      expect(
        ScoringEngine.gradeFromBenchmarkTable(table, 49),
        closeTo(4, 0.01),
      );
      expect(
        ScoringEngine.gradeFromBenchmarkTable(table, 55),
        closeTo(5, 0.01),
      );
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
      expect(
        ScoringEngine.percentileToGrade(100, 7, spread: 3),
        closeTo(10, 0.001),
      );
    });

    test('0th percentile returns anchor - spread', () {
      expect(
        ScoringEngine.percentileToGrade(0, 7, spread: 3),
        closeTo(4, 0.001),
      );
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

  group('softminGrade', () {
    final even = {
      MetricId.fingerStrength: 1.0,
      MetricId.pullingStrength: 1.0,
      MetricId.rfdContact: 1.0,
    };

    test('a weak link drags the result down near the minimum', () {
      final grades = {
        MetricId.pullingStrength: 12.0,
        MetricId.rfdContact: 12.0,
        MetricId.fingerStrength: 4.0,
      };
      // The whole point: a weighted mean reports V9.3 for this profile and
      // hides the deficit that actually caps the climber.
      expect(
        ScoringEngine.weightedMeanGrade(grades, even),
        closeTo(9.33, 0.01),
      );
      expect(ScoringEngine.softminGrade(grades, even), closeTo(4.28, 0.01));
    });

    test('an even profile is barely penalised', () {
      final grades = {
        MetricId.fingerStrength: 8.0,
        MetricId.pullingStrength: 8.0,
        MetricId.rfdContact: 8.0,
      };
      expect(ScoringEngine.softminGrade(grades, even), closeTo(8.0, 0.001));
    });

    test('beta 0 collapses to the weighted mean', () {
      final grades = {
        MetricId.fingerStrength: 4.0,
        MetricId.pullingStrength: 12.0,
      };
      final weights = {
        MetricId.fingerStrength: 3.0,
        MetricId.pullingStrength: 1.0,
      };
      expect(
        ScoringEngine.softminGrade(grades, weights, beta: 0),
        closeTo(ScoringEngine.weightedMeanGrade(grades, weights), 0.001),
      );
    });

    test('survives a grade extrapolated below V0 without overflowing', () {
      final grades = {
        MetricId.fingerStrength: -40.0,
        MetricId.pullingStrength: 12.0,
      };
      final result = ScoringEngine.softminGrade(grades, even);
      expect(result.isFinite, isTrue);
      expect(result, closeTo(-40, 0.01));
    });
  });

  group('plateauPullingGrade', () {
    test('is linear up to the plateau', () {
      expect(ScoringEngine.plateauPullingGrade(8), 8);
      expect(ScoringEngine.plateauPullingGrade(10), 10);
    });

    test('compresses above it, so more pull cannot keep buying grades', () {
      expect(ScoringEngine.plateauPullingGrade(12), closeTo(10.8, 0.001));
      expect(ScoringEngine.plateauPullingGrade(15), closeTo(12.0, 0.001));
    });
  });

  group('experienceMultiplier', () {
    test('is bounded so it can never overwrite a physical bottleneck', () {
      expect(ScoringEngine.experienceMultiplier(0), closeTo(0.92, 0.001));
      expect(ScoringEngine.experienceMultiplier(100), closeTo(1.05, 0.001));
    });

    test('rises fastest over the first years', () {
      final early =
          ScoringEngine.experienceMultiplier(25) -
          ScoringEngine.experienceMultiplier(0);
      final late =
          ScoringEngine.experienceMultiplier(100) -
          ScoringEngine.experienceMultiplier(75);
      expect(early, greaterThan(late));
    });
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

    test(
      'widens above V10, for missing/low-confidence metrics, and scatter',
      () {
        final band = ScoringEngine.confidenceBandWidth(
          predictedGrade: 12,
          missingHighWeightMetricCount: 2,
          metricGradeStdDev: 2,
          lowConfidenceMetricCount: 1,
        );
        // 1.0 base + (12-10)*0.5 + 2*0.25 + 1*0.15 + 2*0.3 = 3.25
        expect(band, closeTo(3.25, 0.001));
      },
    );
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
      // Ape index is measured but unscored, so a lone Tier 1 result carries
      // the ceiling by itself.
      expect(result.assessment.gradeCeiling, closeTo(4, 0.01));
      // No experience data supplied -> gradeExperience falls back to ceiling.
      expect(result.assessment.gradeExperience, result.assessment.gradeCeiling);
      expect(
        result.assessment.confidenceLow,
        lessThan(result.assessment.gradeComposite),
      );
      expect(
        result.assessment.confidenceHigh,
        greaterThan(result.assessment.gradeComposite),
      );
      expect(result.anchorIsFallback, isFalse);
    });

    test(
      'falls back to a default anchor when no strength data is supplied',
      () {
        final user = AppUser(sex: Sex.female, heightCm: 165, armSpanCm: 163);
        final result = AssessmentCalculator.compute(
          user: user,
          rawValues: {MetricId.core: 5},
        );
        expect(result.anchorIsFallback, isTrue);
        expect(result.anchorGrade, 5.0);
      },
    );

    test('weaker pulling strength than fingers is surfaced as a limiter', () {
      final user = AppUser(sex: Sex.male, heightCm: 178, armSpanCm: 182);
      final result = AssessmentCalculator.compute(
        user: user,
        rawValues: {
          MetricId.fingerStrength: 189, // one-arm-equiv ~= 79.5 -> ~V9
          MetricId.pullingStrength: Benchmarks.pullUpCurveFor(
            Sex.male,
            4,
          ), // V4
        },
      );
      expect(result.assessment.limitingFactors, isNotEmpty);
      expect(
        result.assessment.limitingFactors.first.metricId,
        MetricId.pullingStrength,
      );
    });

    test('a profile with nothing tested is flagged, not scored', () {
      final user = AppUser(sex: Sex.male, heightCm: 178, armSpanCm: 190);
      final result = AssessmentCalculator.compute(
        user: user,
        rawValues: const {},
      );
      // Ape index auto-fills from arm span. It used to be the only metric in
      // the ceiling average, so an untested user was handed a confident V4.88.
      expect(result.insufficientData, isTrue);
    });

    test('ape index is shown but never moves the grade', () {
      AssessmentResult forSpan(double armSpanCm) =>
          AssessmentCalculator.compute(
            user: AppUser(sex: Sex.male, heightCm: 178, armSpanCm: armSpanCm),
            rawValues: {MetricId.fingerStrength: 170},
          );
      final short = forSpan(168); // -10 cm
      final long = forSpan(193); // +15 cm

      // Still reported, so the profile view keeps the number...
      expect(long.gradesByMetric.containsKey(MetricId.apeIndex), isTrue);
      // ...but a 25 cm swing in arm span changes nothing about the estimate.
      expect(
        long.assessment.gradeComposite,
        closeTo(short.assessment.gradeComposite, 0.0001),
      );
      expect(
        long.assessment.limitingFactors.any(
          (l) => l.metricId == MetricId.apeIndex,
        ),
        isFalse,
      );
    });

    test('elite pulling cannot mask weak fingers', () {
      final user = AppUser(sex: Sex.male, heightCm: 178, armSpanCm: 182);
      final result = AssessmentCalculator.compute(
        user: user,
        rawValues: {
          MetricId.fingerStrength: 128, // V4
          MetricId.pullingStrength: Benchmarks.pullUpCurveFor(Sex.male, 12),
          MetricId.rfdContact: 6, // elite campus
        },
      );
      // Averaging put this profile near V7. The bottleneck is the fingers.
      expect(result.assessment.gradeCeiling, lessThan(5));
      expect(
        result.assessment.limitingFactors.first.metricId,
        MetricId.fingerStrength,
      );
    });

    test(
      'display percentiles are population-relative, not anchor-relative',
      () {
        final user = AppUser(sex: Sex.male, heightCm: 178, armSpanCm: 182);
        final result = AssessmentCalculator.compute(
          user: user,
          rawValues: {MetricId.fingerStrength: 189, MetricId.core: 6},
        );
        final core = result.assessment.perMetricPercentiles.firstWhere(
          (p) => p.metricId == MetricId.core,
        );
        // Core 6 of 9 is the 66.7th percentile of the normative range and must
        // report as that, regardless of how far the prediction sits from the
        // finger-strength anchor.
        expect(core.percentile, closeTo(66.7, 0.1));
      },
    );
  });
}
