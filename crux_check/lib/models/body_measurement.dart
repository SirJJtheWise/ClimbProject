class BodyMeasurement {
  final int? id;
  final int userId;
  final DateTime date;
  final double weightKg;
  final double? bodyFatPct;

  const BodyMeasurement({
    this.id,
    required this.userId,
    required this.date,
    required this.weightKg,
    this.bodyFatPct,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'weightKg': weightKg,
      'bodyFatPct': bodyFatPct,
    };
  }

  factory BodyMeasurement.fromMap(Map<String, Object?> map) {
    return BodyMeasurement(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      date: DateTime.parse(map['date'] as String),
      weightKg: (map['weightKg'] as num).toDouble(),
      bodyFatPct: (map['bodyFatPct'] as num?)?.toDouble(),
    );
  }
}
