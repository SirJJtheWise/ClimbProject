/// V-grade <-> Font (Fontainebleau) conversion.
///
/// Community-consensus approximate mapping per the spec; widen uncertainty
/// at the top end. V-grades are represented as doubles elsewhere in the app
/// (fractional grades come from interpolation), so [vToFont] rounds to the
/// nearest whole V-grade before mapping.
const Map<int, String> _vToFontTable = {
  0: '4/4+',
  1: '5',
  2: '5+',
  3: '6A/6A+',
  4: '6B/6B+',
  5: '6C/6C+',
  6: '7A',
  7: '7A+',
  8: '7B',
  9: '7C',
  10: '7C+',
  11: '8A',
  12: '8A+',
  13: '8B',
  14: '8B+',
  15: '8C',
  16: '8C+',
  17: '9A',
};

String vToFont(double vGrade) {
  final rounded = vGrade.round().clamp(0, 17);
  return _vToFontTable[rounded] ?? '9A+';
}

String vGradeLabel(double vGrade) {
  final rounded = vGrade.round().clamp(0, 17);
  return 'V$rounded';
}

String vRangeLabel(double low, double high) {
  final lo = low.round().clamp(0, 17);
  final hi = high.round().clamp(0, 17);
  if (lo == hi) return 'V$lo';
  return 'V$lo–V$hi';
}

String fontRangeLabel(double low, double high) {
  final lo = low.round().clamp(0, 17);
  final hi = high.round().clamp(0, 17);
  if (lo == hi) return _vToFontTable[lo] ?? '9A+';
  return '${_vToFontTable[lo]}–${_vToFontTable[hi]}';
}
