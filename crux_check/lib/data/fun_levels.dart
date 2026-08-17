/// The 1 (worst) - 7 (best) fun-name scale shown next to each tested
/// metric, derived from that metric's percentile relative to the user's
/// current predicted grade (see AssessmentCalculator.perMetricPercentiles).
class FunLevels {
  FunLevels._();

  static const List<String> names = [
    'The Birthday Party Guest',
    'The Fresh Tarantulace Owner',
    'The "Beta" Sprayer',
    'The Shirtless Beanie Bro',
    'The Friction Physicist',
    'The Silent Local Crusher',
    'Magnus Midtbø',
  ];

  /// 1-7, where 1 = names.first and 7 = names.last.
  static int levelForPercentile(double percentile) {
    final p = percentile.clamp(0, 100);
    final level = (p / 100 * names.length).ceil();
    return level.clamp(1, names.length);
  }

  static String nameForLevel(int level) => names[level.clamp(1, names.length) - 1];

  static String nameForPercentile(double percentile) =>
      nameForLevel(levelForPercentile(percentile));
}
