import 'package:flutter/foundation.dart';

import '../data/db_helper.dart';
import '../logic/assessment_calculator.dart';
import '../models/assessment.dart';
import '../models/body_measurement.dart';
import '../models/enums.dart';
import '../models/test_result.dart';
import '../models/user.dart';

/// Central app state: the current user, their latest measurements/test
/// results/assessment, kept in sync with sqflite. Screens read via
/// `context.watch<AppState>()` / `context.read<AppState>()`.
class AppState extends ChangeNotifier {
  final DbHelper _db = DbHelper.instance;

  AppUser? user;
  BodyMeasurement? latestBody;
  Map<MetricId, TestResult> latestResults = {};
  Assessment? latestAssessment;
  AssessmentResult? latestResultDetail;
  bool loading = true;

  Future<void> loadFromDb() async {
    loading = true;
    notifyListeners();

    try {
      user = await _db.getFirstUser();
      if (user != null) {
        final uid = user!.id!;
        latestBody = await _db.getLatestBodyMeasurement(uid);
        latestResults = await _db.getLatestTestResults(uid);
        latestAssessment = await _db.getLatestAssessment(uid);
      }
    } catch (e, st) {
      // A DB init failure shouldn't leave the user stuck on a spinner
      // forever — fall through to onboarding instead.
      debugPrint('AppState.loadFromDb failed: $e\n$st');
    }

    loading = false;
    notifyListeners();
  }

  bool get hasProfile => user != null;

  Future<void> saveProfile(AppUser updated) async {
    final id = await _db.upsertUser(updated);
    user = updated.copyWith(id: id);
    notifyListeners();
  }

  Future<void> saveBodyMeasurement({
    required double weightKg,
    double? bodyFatPct,
  }) async {
    if (user?.id == null) return;
    final measurement = BodyMeasurement(
      userId: user!.id!,
      date: DateTime.now(),
      weightKg: weightKg,
      bodyFatPct: bodyFatPct,
    );
    await _db.insertBodyMeasurement(measurement);
    latestBody = measurement;
    notifyListeners();
  }

  Future<void> saveTestResult({
    required MetricId metricId,
    required double rawValue,
    required String unit,
    double? addedLoadKg,
    double? computedPctBW,
    double? edgeSizeMm,
    GripType? gripType,
    bool hitTrueMax = true,
  }) async {
    if (user?.id == null) return;
    final result = TestResult(
      userId: user!.id!,
      metricId: metricId,
      date: DateTime.now(),
      rawValue: rawValue,
      unit: unit,
      addedLoadKg: addedLoadKg,
      computedPctBW: computedPctBW,
      edgeSizeMm: edgeSizeMm,
      gripType: gripType,
      hitTrueMax: hitTrueMax,
    );
    await _db.insertTestResult(result);
    latestResults = {...latestResults, metricId: result};
    notifyListeners();
  }

  Future<List<TestResult>> testHistory(MetricId metricId) {
    return _db.getTestResultHistory(user!.id!, metricId);
  }

  Future<List<Assessment>> assessmentHistory() {
    return _db.getAssessmentHistory(user!.id!);
  }

  /// Builds the canonical-unit raw-value map the scoring engine expects,
  /// from whatever test results / body measurement have been recorded so
  /// far. Metrics with no recorded result are simply omitted (partial input
  /// is supported end-to-end).
  Map<MetricId, double> _rawValuesForCalculator() {
    final values = <MetricId, double>{};
    for (final entry in latestResults.entries) {
      if (entry.key == MetricId.fingerStrength ||
          entry.key == MetricId.pullingStrength ||
          entry.key == MetricId.edgeTolerance ||
          entry.key == MetricId.fingerEndurance) {
        values[entry.key] = entry.value.computedPctBW ?? entry.value.rawValue;
      } else {
        values[entry.key] = entry.value.rawValue;
      }
    }
    if (latestBody?.bodyFatPct != null) {
      values[MetricId.bodyComposition] = latestBody!.bodyFatPct!;
    }
    return values;
  }

  AssessmentResult _computeLive() {
    final rawValues = _rawValuesForCalculator();
    final lowConfidence = {
      for (final entry in latestResults.entries)
        if (!entry.value.hitTrueMax) entry.key,
    };
    return AssessmentCalculator.compute(
      user: user!,
      rawValues: rawValues,
      lowConfidenceMetricIds: lowConfidence,
    );
  }

  /// A live, unsaved assessment computed from whatever is currently entered
  /// — recomputed on every access, so it reflects the latest state
  /// immediately after any save. Null until a profile exists. Unlike
  /// [runAssessment], this never writes to the DB or touches
  /// [latestAssessment]/history, so it's safe to read on every rebuild
  /// (e.g. from the Test hub's live star-plot preview).
  AssessmentResult? get livePreview => user == null ? null : _computeLive();

  Future<AssessmentResult> runAssessment() async {
    final result = _computeLive();
    await _db.insertAssessment(result.assessment);
    latestAssessment = result.assessment;
    latestResultDetail = result;
    notifyListeners();
    return result;
  }
}
