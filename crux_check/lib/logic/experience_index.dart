/// Composite 0-100 experience index from years climbing, weekly session
/// frequency, and years climbing outdoors (spec metric #15). Already on a
/// 0-100 scale, so it is fed straight in as a percentile by
/// [AssessmentCalculator].
double experienceIndex({
  required double yearsClimbing,
  required double sessionsPerWeek,
  required double yearsClimbingOutdoors,
}) {
  final raw =
      yearsClimbing * 8 + sessionsPerWeek * 4 + yearsClimbingOutdoors * 3;
  return raw.clamp(0, 100);
}
