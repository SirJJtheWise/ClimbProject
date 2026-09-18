import 'package:flutter_test/flutter_test.dart';

import 'package:crux_check/logic/grade_conversion.dart';
import 'package:crux_check/models/enums.dart';

/// The scale picked during onboarding was stored and then ignored: every
/// screen printed V-grades regardless of it. These lock the preference to what
/// actually reaches the screen.
void main() {
  test('a single grade follows the chosen scale', () {
    expect(gradeLabel(6, GradeScale.v), 'V6');
    expect(gradeLabel(6, GradeScale.font), '7A');
    expect(gradeLabel(11, GradeScale.font), '8A');
  });

  test('a range follows the chosen scale', () {
    expect(gradeRangeLabel(6, 9, GradeScale.v), 'V6–V9');
    expect(gradeRangeLabel(6, 9, GradeScale.font), '7A–7C');
  });

  test('a range collapses when both ends round to the same grade', () {
    expect(gradeRangeLabel(6.1, 6.4, GradeScale.v), 'V6');
    expect(gradeRangeLabel(6.1, 6.4, GradeScale.font), '7A');
  });

  test('fractional grades round rather than truncating', () {
    // Interpolation produces fractional grades throughout, so V6.6 must not
    // display as V6.
    expect(gradeLabel(6.6, GradeScale.v), 'V7');
    expect(gradeLabel(6.4, GradeScale.v), 'V6');
  });

  test('grades past the table ends are clamped, not dropped', () {
    expect(gradeLabel(-3, GradeScale.v), 'V0');
    expect(gradeLabel(99, GradeScale.v), 'V17');
    expect(gradeLabel(99, GradeScale.font), '9A');
  });
}
