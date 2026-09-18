import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../logic/grade_conversion.dart';
import '../models/enums.dart';
import '../state/app_state.dart';

/// Formats a grade in whichever scale the user picked during onboarding.
///
/// Reading the preference at the point of display, rather than threading it
/// through every widget constructor, is what keeps this from being skipped —
/// and it was skipped: the choice was collected, stored, and then every screen
/// printed V-grades regardless.
extension GradeFormatting on BuildContext {
  GradeScale get gradeScale =>
      watch<AppState>().user?.gradeScalePref ?? GradeScale.v;

  /// A single grade, e.g. `V6` or `7A`.
  String grade(double vGrade) => gradeLabel(vGrade, gradeScale);

  /// A confidence range, e.g. `V6–V9` or `7A–7C`.
  String gradeRange(double low, double high) =>
      gradeRangeLabel(low, high, gradeScale);

  /// The same range in the scale the user did *not* pick, for the secondary
  /// cross-reference line under the headline grade. Showing the chosen scale
  /// twice would waste the line.
  String gradeRangeAlternate(double low, double high) => gradeRangeLabel(
    low,
    high,
    gradeScale == GradeScale.font ? GradeScale.v : GradeScale.font,
  );
}
