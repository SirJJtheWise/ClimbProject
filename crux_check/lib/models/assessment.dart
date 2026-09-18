import 'dart:convert';

import 'enums.dart';

class MetricPercentile {
  final MetricId metricId;
  final double percentile;
  final double gradeEquivalent;

  const MetricPercentile({
    required this.metricId,
    required this.percentile,
    required this.gradeEquivalent,
  });

  Map<String, Object?> toJson() => {
    'metricId': metricId.name,
    'percentile': percentile,
    'gradeEquivalent': gradeEquivalent,
  };

  factory MetricPercentile.fromJson(Map<String, Object?> json) {
    return MetricPercentile(
      metricId: MetricId.values.byName(json['metricId'] as String),
      percentile: (json['percentile'] as num).toDouble(),
      gradeEquivalent: (json['gradeEquivalent'] as num).toDouble(),
    );
  }

  /// Null when the stored entry names a metric this version has removed.
  static MetricPercentile? tryFromJson(Map<String, Object?> json) {
    return knownMetric(json['metricId']) == null
        ? null
        : MetricPercentile.fromJson(json);
  }
}

/// The saved metric name if the current [MetricId] enum still has it, else
/// null. Persisted records outlive the catalogue, so callers reading history
/// treat an unknown name as a row to skip rather than an error.
MetricId? knownMetric(Object? storedName) {
  if (storedName is! String) return null;
  for (final metric in MetricId.values) {
    if (metric.name == storedName) return metric;
  }
  return null;
}

class LimitingFactor {
  final MetricId metricId;
  final double deficit;

  const LimitingFactor({required this.metricId, required this.deficit});

  Map<String, Object?> toJson() => {
    'metricId': metricId.name,
    'deficit': deficit,
  };

  factory LimitingFactor.fromJson(Map<String, Object?> json) {
    return LimitingFactor(
      metricId: MetricId.values.byName(json['metricId'] as String),
      deficit: (json['deficit'] as num).toDouble(),
    );
  }

  /// Null when the stored entry names a metric this version has removed.
  static LimitingFactor? tryFromJson(Map<String, Object?> json) {
    return knownMetric(json['metricId']) == null
        ? null
        : LimitingFactor.fromJson(json);
  }
}

class Assessment {
  final int? id;
  final int userId;
  final DateTime date;
  final double gradeComposite;
  final double gradeCeiling;
  final double gradeExperience;
  final double confidenceLow;
  final double confidenceHigh;
  final List<MetricPercentile> perMetricPercentiles;
  final List<LimitingFactor> limitingFactors;
  final int missingMetricCount;

  const Assessment({
    this.id,
    required this.userId,
    required this.date,
    required this.gradeComposite,
    required this.gradeCeiling,
    required this.gradeExperience,
    required this.confidenceLow,
    required this.confidenceHigh,
    required this.perMetricPercentiles,
    required this.limitingFactors,
    required this.missingMetricCount,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'gradeComposite': gradeComposite,
      'gradeCeiling': gradeCeiling,
      'gradeExperience': gradeExperience,
      'confidenceLow': confidenceLow,
      'confidenceHigh': confidenceHigh,
      'perMetricPercentiles': jsonEncode(
        perMetricPercentiles.map((e) => e.toJson()).toList(),
      ),
      'limitingFactors': jsonEncode(
        limitingFactors.map((e) => e.toJson()).toList(),
      ),
      'missingMetricCount': missingMetricCount,
    };
  }

  factory Assessment.fromMap(Map<String, Object?> map) {
    final percentilesJson =
        jsonDecode(map['perMetricPercentiles'] as String) as List;
    final limitingJson = jsonDecode(map['limitingFactors'] as String) as List;
    return Assessment(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      date: DateTime.parse(map['date'] as String),
      gradeComposite: (map['gradeComposite'] as num).toDouble(),
      gradeCeiling: (map['gradeCeiling'] as num).toDouble(),
      gradeExperience: (map['gradeExperience'] as num).toDouble(),
      confidenceLow: (map['confidenceLow'] as num).toDouble(),
      confidenceHigh: (map['confidenceHigh'] as num).toDouble(),
      // A stored assessment names the metrics it scored. Metrics get removed
      // from the catalogue (finger endurance, edge tolerance), so an entry
      // for one this version no longer has is dropped rather than failing the
      // whole history load.
      perMetricPercentiles: percentilesJson
          .map(
            (e) => MetricPercentile.tryFromJson(Map<String, Object?>.from(e)),
          )
          .whereType<MetricPercentile>()
          .toList(),
      limitingFactors: limitingJson
          .map((e) => LimitingFactor.tryFromJson(Map<String, Object?>.from(e)))
          .whereType<LimitingFactor>()
          .toList(),
      missingMetricCount: map['missingMetricCount'] as int,
    );
  }
}
