import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/diagnosis.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'decafia.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE diagnoses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            imagePath TEXT NOT NULL,
            disease TEXT NOT NULL,
            confidence REAL NOT NULL,
            latitude REAL,
            longitude REAL,
            timestamp TEXT NOT NULL,
            notes TEXT NOT NULL DEFAULT ''
          )
        ''');
      },
    );
  }

  Future<int> insertDiagnosis(Diagnosis d) async {
    final db = await database;
    return db.insert('diagnoses', d.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Diagnosis>> getAllDiagnoses() async {
    final db = await database;
    final rows =
        await db.query('diagnoses', orderBy: 'timestamp DESC');
    return rows.map(Diagnosis.fromMap).toList();
  }

  Future<int> deleteDiagnosis(int id) async {
    final db = await database;
    return db.delete('diagnoses', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateNotes(int id, String notes) async {
    final db = await database;
    return db.update(
      'diagnoses',
      {'notes': notes},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('diagnoses');
  }

  Future<Map<String, int>> diseaseStats() async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT disease, COUNT(*) as count FROM diagnoses GROUP BY disease');
    return {for (final r in rows) r['disease'] as String: r['count'] as int};
  }

  Future<int> countFallbackCoordinateRows() async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT COUNT(*) AS cnt FROM diagnoses '
        'WHERE ABS(latitude  - 6.441083)     < 0.0001 '
        '  AND ABS(longitude - (-73.215445)) < 0.0001');
    return (rows.first['cnt'] as int?) ?? 0;
  }
}
