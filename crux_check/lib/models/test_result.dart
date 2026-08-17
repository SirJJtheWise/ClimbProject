import 'enums.dart';

enum GripType { halfCrimp, openCrimp, fullCrimp }

class TestResult {
  final int? id;
  final int userId;
  final MetricId metricId;
  final DateTime date;
  final double rawValue;
  final String unit;
  final double? addedLoadKg;
  final double? computedPctBW;
  final double? edgeSizeMm;
  final GripType? gripType;
  final bool hitTrueMax;

  const TestResult({
    this.id,
    required this.userId,
    required this.metricId,
    required this.date,
    required this.rawValue,
    required this.unit,
    this.addedLoadKg,
    this.computedPctBW,
    this.edgeSizeMm,
    this.gripType,
    this.hitTrueMax = true,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'userId': userId,
      'metricId': metricId.name,
      'date': date.toIso8601String(),
      'rawValue': rawValue,
      'unit': unit,
      'addedLoadKg': addedLoadKg,
      'computedPctBW': computedPctBW,
      'edgeSizeMm': edgeSizeMm,
      'gripType': gripType?.name,
      'hitTrueMax': hitTrueMax ? 1 : 0,
    };
  }

  factory TestResult.fromMap(Map<String, Object?> map) {
    return TestResult(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      metricId: MetricId.values.byName(map['metricId'] as String),
      date: DateTime.parse(map['date'] as String),
      rawValue: (map['rawValue'] as num).toDouble(),
      unit: map['unit'] as String,
      addedLoadKg: (map['addedLoadKg'] as num?)?.toDouble(),
      computedPctBW: (map['computedPctBW'] as num?)?.toDouble(),
      edgeSizeMm: (map['edgeSizeMm'] as num?)?.toDouble(),
      gripType: map['gripType'] == null
          ? null
          : GripType.values.byName(map['gripType'] as String),
      hitTrueMax: (map['hitTrueMax'] as int? ?? 1) == 1,
    );
  }
}
