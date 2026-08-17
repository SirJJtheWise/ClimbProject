import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/assessment.dart';
import '../models/body_measurement.dart';
import '../models/enums.dart';
import '../models/test_result.dart';
import '../models/user.dart';

class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  /// Bump this whenever a stored value changes meaning, and handle it in
  /// [_onUpgrade].
  static const int _schemaVersion = 2;

  Future<Database> _open() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return databaseFactory.openDatabase(
        'crux_check.db',
        options: OpenDatabaseOptions(
          version: _schemaVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'crux_check.db');
    return openDatabase(
      path,
      version: _schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v2: power-endurance switched protocol from "7:3 repeaters to failure"
    // (seconds) to "board max moves" (moves), so stored values no longer
    // mean what the normative range now expects — a 180-second result would
    // be scored as 180 moves. The rows are not convertible, so drop them
    // and let the user retest under the new protocol. Assessments are
    // left alone: they are point-in-time records, and the next
    // recalculation supersedes them.
    if (oldVersion < 2) {
      await db.delete(
        'test_results',
        where: 'metricId = ?',
        whereArgs: [MetricId.powerEndurance.name],
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sex TEXT NOT NULL,
        birthdate TEXT,
        heightCm REAL NOT NULL,
        armSpanCm REAL NOT NULL,
        useMetric INTEGER NOT NULL,
        gradeScalePref TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE body_measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        date TEXT NOT NULL,
        weightKg REAL NOT NULL,
        bodyFatPct REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE test_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        metricId TEXT NOT NULL,
        date TEXT NOT NULL,
        rawValue REAL NOT NULL,
        unit TEXT NOT NULL,
        addedLoadKg REAL,
        computedPctBW REAL,
        edgeSizeMm REAL,
        gripType TEXT,
        hitTrueMax INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE assessments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        date TEXT NOT NULL,
        gradeComposite REAL NOT NULL,
        gradeCeiling REAL NOT NULL,
        gradeExperience REAL NOT NULL,
        confidenceLow REAL NOT NULL,
        confidenceHigh REAL NOT NULL,
        perMetricPercentiles TEXT NOT NULL,
        limitingFactors TEXT NOT NULL,
        missingMetricCount INTEGER NOT NULL
      )
    ''');
  }

  // --- User ---

  Future<int> upsertUser(AppUser user) async {
    final db = await database;
    if (user.id == null) {
      return db.insert('users', user.toMap()..remove('id'));
    }
    await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
    return user.id!;
  }

  Future<AppUser?> getFirstUser() async {
    final db = await database;
    final rows = await db.query('users', limit: 1);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  // --- Body measurements ---

  Future<int> insertBodyMeasurement(BodyMeasurement m) async {
    final db = await database;
    return db.insert('body_measurements', m.toMap()..remove('id'));
  }

  Future<BodyMeasurement?> getLatestBodyMeasurement(int userId) async {
    final db = await database;
    final rows = await db.query(
      'body_measurements',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BodyMeasurement.fromMap(rows.first);
  }

  Future<List<BodyMeasurement>> getBodyMeasurementHistory(int userId) async {
    final db = await database;
    final rows = await db.query(
      'body_measurements',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date ASC',
    );
    return rows.map(BodyMeasurement.fromMap).toList();
  }

  // --- Test results ---

  Future<int> insertTestResult(TestResult r) async {
    final db = await database;
    return db.insert('test_results', r.toMap()..remove('id'));
  }

  /// Latest result per metric for [userId].
  Future<Map<MetricId, TestResult>> getLatestTestResults(int userId) async {
    final db = await database;
    final rows = await db.query(
      'test_results',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date ASC',
    );
    final latest = <MetricId, TestResult>{};
    for (final row in rows) {
      final result = TestResult.fromMap(row);
      latest[result.metricId] = result; // later rows overwrite earlier ones
    }
    return latest;
  }

  Future<List<TestResult>> getTestResultHistory(
    int userId,
    MetricId metricId,
  ) async {
    final db = await database;
    final rows = await db.query(
      'test_results',
      where: 'userId = ? AND metricId = ?',
      whereArgs: [userId, metricId.name],
      orderBy: 'date ASC',
    );
    return rows.map(TestResult.fromMap).toList();
  }

  // --- Assessments ---

  Future<int> insertAssessment(Assessment a) async {
    final db = await database;
    return db.insert('assessments', a.toMap()..remove('id'));
  }

  Future<List<Assessment>> getAssessmentHistory(int userId) async {
    final db = await database;
    final rows = await db.query(
      'assessments',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date ASC',
    );
    return rows.map(Assessment.fromMap).toList();
  }

  Future<Assessment?> getLatestAssessment(int userId) async {
    final db = await database;
    final rows = await db.query(
      'assessments',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Assessment.fromMap(rows.first);
  }
}
