import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:crux_check/models/assessment.dart';
import 'package:crux_check/models/enums.dart';
import 'package:crux_check/models/test_result.dart';

/// The stored database outlives the MetricId enum. Two metrics have already
/// been removed (finger endurance, edge tolerance) and a saved row naming one
/// of them used to throw out of `byName`, which failed the entire load — so
/// every other recorded result silently disappeared too.
void main() {
  Map<String, Object?> row(String metricId) => {
    'id': 1,
    'userId': 1,
    'metricId': metricId,
    'date': '2026-01-01T00:00:00.000',
    'rawValue': 150.0,
    'unit': '%BW',
    'addedLoadKg': 35.0,
    'computedPctBW': 150.0,
    'edgeSizeMm': 20.0,
    'gripType': 'halfCrimp',
    'hitTrueMax': 1,
  };

  test('reads a row for a metric that still exists', () {
    final result = TestResult.tryFromMap(row('fingerStrength'));
    expect(result, isNotNull);
    expect(result!.metricId, MetricId.fingerStrength);
    expect(result.computedPctBW, 150.0);
  });

  test('skips a row naming a removed metric instead of throwing', () {
    expect(TestResult.tryFromMap(row('fingerEndurance')), isNull);
    expect(TestResult.tryFromMap(row('edgeTolerance')), isNull);
  });

  test('one unreadable row does not take the readable ones with it', () {
    final rows = [row('fingerStrength'), row('fingerEndurance'), row('core')];
    final parsed = rows
        .map(TestResult.tryFromMap)
        .whereType<TestResult>()
        .toList();
    expect(parsed.map((r) => r.metricId), [
      MetricId.fingerStrength,
      MetricId.core,
    ]);
  });

  test('a saved assessment survives naming a removed metric', () {
    // Assessments store the metrics they scored, so they hit the same problem
    // from a second direction: history failed to load, not just results.
    final stored = {
      'id': 1,
      'userId': 1,
      'date': '2026-01-01T00:00:00.000',
      'gradeComposite': 6.0,
      'gradeCeiling': 6.2,
      'gradeExperience': 5.5,
      'confidenceLow': 5.0,
      'confidenceHigh': 7.0,
      'perMetricPercentiles': jsonEncode([
        {
          'metricId': 'fingerStrength',
          'percentile': 60.0,
          'gradeEquivalent': 6.0,
        },
        {
          'metricId': 'fingerEndurance',
          'percentile': 40.0,
          'gradeEquivalent': 5.0,
        },
      ]),
      'limitingFactors': jsonEncode([
        {'metricId': 'edgeTolerance', 'deficit': 1.0},
        {'metricId': 'core', 'deficit': 0.5},
      ]),
      'missingMetricCount': 9,
    };

    final assessment = Assessment.fromMap(stored);
    expect(assessment.perMetricPercentiles.map((p) => p.metricId), [
      MetricId.fingerStrength,
    ]);
    expect(assessment.limitingFactors.map((l) => l.metricId), [MetricId.core]);
    expect(assessment.gradeComposite, 6.0);
  });
}
