import 'enums.dart';

class AppUser {
  final int? id;
  final Sex sex;
  final DateTime? birthdate;
  final double heightCm;
  final double armSpanCm;
  final bool useMetric;
  final GradeScale gradeScalePref;

  const AppUser({
    this.id,
    required this.sex,
    this.birthdate,
    required this.heightCm,
    required this.armSpanCm,
    this.useMetric = true,
    this.gradeScalePref = GradeScale.v,
  });

  double get apeIndexCm => armSpanCm - heightCm;

  int? get age {
    if (birthdate == null) return null;
    final now = DateTime.now();
    var years = now.year - birthdate!.year;
    if (now.month < birthdate!.month ||
        (now.month == birthdate!.month && now.day < birthdate!.day)) {
      years--;
    }
    return years;
  }

  AppUser copyWith({
    int? id,
    Sex? sex,
    DateTime? birthdate,
    double? heightCm,
    double? armSpanCm,
    bool? useMetric,
    GradeScale? gradeScalePref,
  }) {
    return AppUser(
      id: id ?? this.id,
      sex: sex ?? this.sex,
      birthdate: birthdate ?? this.birthdate,
      heightCm: heightCm ?? this.heightCm,
      armSpanCm: armSpanCm ?? this.armSpanCm,
      useMetric: useMetric ?? this.useMetric,
      gradeScalePref: gradeScalePref ?? this.gradeScalePref,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'sex': sex.name,
      'birthdate': birthdate?.toIso8601String(),
      'heightCm': heightCm,
      'armSpanCm': armSpanCm,
      'useMetric': useMetric ? 1 : 0,
      'gradeScalePref': gradeScalePref.name,
    };
  }

  factory AppUser.fromMap(Map<String, Object?> map) {
    return AppUser(
      id: map['id'] as int?,
      sex: Sex.values.byName(map['sex'] as String),
      birthdate: map['birthdate'] == null
          ? null
          : DateTime.parse(map['birthdate'] as String),
      heightCm: (map['heightCm'] as num).toDouble(),
      armSpanCm: (map['armSpanCm'] as num).toDouble(),
      useMetric: (map['useMetric'] as int) == 1,
      gradeScalePref: GradeScale.values.byName(map['gradeScalePref'] as String),
    );
  }
}
