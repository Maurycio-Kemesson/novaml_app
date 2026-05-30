import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Singleton de acesso ao banco SQLite local do NOVAML.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = Directory(p.join(
      Platform.environment['LOCALAPPDATA'] ?? '.',
      'NOVAML',
    ));
    await dir.create(recursive: true);

    final dbPath = p.join(dir.path, 'novaml.db');

    return openDatabase(
      dbPath,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        name            TEXT    NOT NULL,
        description     TEXT,
        algorithm       TEXT    NOT NULL DEFAULT 'linearRegression',
        status          TEXT    NOT NULL DEFAULT 'idle',
        csv_path        TEXT,
        storage_mb      REAL    NOT NULL DEFAULT 0.0,
        train_split     REAL    NOT NULL DEFAULT 0.8,
        target_column   TEXT,
        use_columns     TEXT,
        created_at      TEXT    NOT NULL,
        updated_at      TEXT    NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 → v2: adiciona colunas de configuração do workspace
      await db.execute(
          'ALTER TABLE projects ADD COLUMN train_split REAL NOT NULL DEFAULT 0.8');
      await db.execute(
          'ALTER TABLE projects ADD COLUMN target_column TEXT');
      await db.execute(
          'ALTER TABLE projects ADD COLUMN use_columns TEXT');
    }
    if (oldVersion < 3) {
      // v2 → v3: normaliza algoritmos inválidos para linearRegression.
      // xgboost, randomForest e mlp não são suportados pela API.
      await db.execute("""
        UPDATE projects
        SET algorithm = 'linearRegression'
        WHERE algorithm NOT IN ('linearRegression', 'decisionTree')
      """);
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
