import '../models/enums.dart';

/// Grade-benchmark curves used as the composite's anchors.
///
/// These are priors, not ground truth (see spec "Recommendations" /
/// "Trigger to recalibrate"): once real user outcome data accumulates they
/// should be refit, especially the two-arm -> one-arm-equivalent conversion
/// and the female offsets, which are currently single-anchor-point
/// approximations.
class Benchmarks {
  Benchmarks._();

  /// Male one-arm-equivalent max hang, 20 mm edge, %BW, by V-grade.
  /// Source: community reverse-engineering of the Lattice bouldering
  /// dataset ("Approximating Lattice's Finger Strength Dataset", wmgclimbing
  /// 2024). Below V4 the curve is extrapolated at ~6-8%/grade with high
  /// uncertainty per the spec.
  static const Map<int, double> fingerStrengthOneArmEquivMale = {
    0: 25,
    1: 31,
    2: 37,
    3: 43,
    4: 49,
    5: 55,
    6: 61,
    7: 67,
    8: 73,
    9: 79,
    10: 85,
    11: 91,
    12: 96,
    13: 101,
    14: 106,
    15: 110,
    16: 114,
    17: 118,
  };

  /// Female offset applied to the male finger-strength curve, in %BW.
  /// Small and shrinking at higher grades: relative finger strength is not
  /// significantly different once normalized to body mass (Baláš/Berta
  /// 2025), but the Lattice "perfect climber" standard still shows a small
  /// gap (95% vs 100% one-arm hang).
  static double femaleFingerStrengthOffset(int vGrade) {
    final shrink = (vGrade - 10).clamp(0, 10) * 0.3;
    return (5 - shrink).clamp(1, 5);
  }

  /// Converts a two-arm 7-second hang (%BW) — the app's chosen protocol,
  /// safest and easiest for recreational users — into the one-arm-equivalent
  /// value the anchor curve above is expressed in.
  ///
  /// Calibrated against the single published anchor point available: Lattice
  /// cite a two-arm benchmark of ~128 %BW for V4 (per UKC user reports),
  /// against a one-arm-equivalent of 49 %BW at V4 in the table above:
  /// 128 * 0.5 - 15 = 49. This is a one-point calibration and should be
  /// refit once real outcome data is available (spec "Trigger to
  /// recalibrate").
  static double twoArmToOneArmEquiv(double twoArmPctBW) {
    return twoArmPctBW * 0.5 - 15;
  }

  static double oneArmEquivToTwoArm(double oneArmEquivPctBW) {
    return (oneArmEquivPctBW + 15) / 0.5;
  }

  /// Male weighted pull-up 2RM, %BW total load, by V-grade. Anchored on the
  /// 9c strength test (Christophersen & Mobråten) and the Lattice "perfect
  /// climber" ceiling; linearly interpolated/extrapolated between the
  /// published anchor points (V4, V6, V8, V10, V12, V14). Coach-derived, not
  /// peer-reviewed - held looser than the finger-strength curve.
  static const Map<int, double> pullUpPctBWMale = {
    0: 95,
    1: 100,
    2: 105,
    3: 110,
    4: 115,
    5: 120,
    6: 125,
    7: 132.5,
    8: 140,
    9: 145,
    10: 150,
    11: 155,
    12: 160,
    13: 162.5,
    14: 165,
    15: 167.5,
    16: 170,
    17: 172.5,
  };

  /// Female offset subtracted from the male pull-up curve, in %BW. Large and
  /// flat: the Lattice "perfect climber" standard shows female pulling ~30
  /// %BW below male (135% vs 165% for 2 pull-ups).
  static const double femalePullUpOffset = 27.5;

  static double fingerStrengthCurveFor(Sex sex, int vGrade) {
    final male = fingerStrengthOneArmEquivMale[vGrade.clamp(0, 17)]!;
    if (sex == Sex.male) return male;
    return male - femaleFingerStrengthOffset(vGrade);
  }

  static double pullUpCurveFor(Sex sex, int vGrade) {
    final male = pullUpPctBWMale[vGrade.clamp(0, 17)]!;
    if (sex == Sex.male) return male;
    return male - femalePullUpOffset;
  }
}
