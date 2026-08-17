import 'package:flutter_test/flutter_test.dart';

import 'package:crux_check/logic/grade_conversion.dart';

void main() {
  test('vGradeLabel rounds to the nearest whole grade', () {
    expect(vGradeLabel(7.4), 'V7');
    expect(vGradeLabel(7.6), 'V8');
  });

  test('vToFont maps known anchors', () {
    expect(vToFont(7), '7A+');
    expect(vToFont(0), '4/4+');
    expect(vToFont(17), '9A');
  });

  test('vRangeLabel collapses equal bounds to a single grade', () {
    expect(vRangeLabel(6.1, 6.3), 'V6');
    expect(vRangeLabel(6.4, 8.2), 'V6–V8');
  });

  test('fontRangeLabel mirrors vRangeLabel', () {
    expect(fontRangeLabel(6, 8), '7A–7B');
  });
}
