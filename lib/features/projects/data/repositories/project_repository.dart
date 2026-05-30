import 'package:novaml_app/core/database/app_database.dart';
import 'package:novaml_app/features/projects/domain/models/project_model.dart';

/// Repositório responsável por todas as operações CRUD de projetos no SQLite.
class ProjectRepository {
  static const _table = 'projects';

  final _db = AppDatabase.instance;

  // ── Leitura ──────────────────────────────────────────────────────────────

  Future<List<Project>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(_table, orderBy: 'created_at DESC');
    return rows.map(Project.fromMap).toList();
  }

  Future<Project?> getById(int id) async {
    final db = await _db.database;
    final rows =
        await db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Project.fromMap(rows.first);
  }

  Future<List<Project>> search(String query) async {
    final db = await _db.database;
    final rows = await db.query(
      _table,
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return rows.map(Project.fromMap).toList();
  }

  // ── Escrita ──────────────────────────────────────────────────────────────

  Future<Project> create(Project project) async {
    final db = await _db.database;
    final now = DateTime.now();
    final toInsert = project.copyWith(
      createdAt: now,
      updatedAt: now,
    );
    final id = await db.insert(_table, toInsert.toMap());
    return toInsert.copyWith(id: id);
  }

  Future<void> update(Project project) async {
    assert(project.id != null, 'update() requer project.id != null');
    final db = await _db.database;
    await db.update(
      _table,
      project.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateStatus(int id, ProjectStatus status) async {
    final db = await _db.database;
    await db.update(
      _table,
      {
        'status':     status.name,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateCsvPath(int id, String csvPath, double storageMb) async {
    final db = await _db.database;
    await db.update(
      _table,
      {
        'csv_path':   csvPath,
        'storage_mb': storageMb,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Persiste toda a configuração do workspace de uma vez.
  Future<void> saveWorkspaceConfig({
    required int id,
    required double trainSplit,
    required ProjectAlgorithm algorithm,
    String? targetColumn,
    String? useColumnsJson,
    String? csvPath,
    double? storageMb,
  }) async {
    final db = await _db.database;
    await db.update(
      _table,
      {
        'train_split':   trainSplit,
        'algorithm':     algorithm.name,
        'target_column': targetColumn,
        'use_columns':   useColumnsJson,
        if (csvPath != null) 'csv_path':   csvPath,
        if (storageMb != null) 'storage_mb': storageMb,
        'updated_at':    DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
