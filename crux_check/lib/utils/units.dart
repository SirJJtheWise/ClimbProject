double cmToIn(double cm) => cm / 2.54;
double inToCm(double inches) => inches * 2.54;
double kgToLb(double kg) => kg * 2.20462;
double lbToKg(double lb) => lb / 2.20462;

String formatGrade(double value) {
  return value.toStringAsFixed(1);
}
