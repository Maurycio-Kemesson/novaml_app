import 'package:flutter/material.dart';
import 'package:novaml_app/core/theme/app_colors.dart';

// ─── Status ───────────────────────────────────────────────────────────────────

enum ProjectStatus { idle, active, queued, training, completed, error }

extension ProjectStatusX on ProjectStatus {
  String get label => switch (this) {
        ProjectStatus.idle      => 'IDLE',
        ProjectStatus.active    => 'ACTIVE',
        ProjectStatus.queued    => 'QUEUED',
        ProjectStatus.training  => 'TRAINING...',
        ProjectStatus.completed => 'COMPLETED',
        ProjectStatus.error     => 'ERROR',
      };

  Color get color => switch (this) {
        ProjectStatus.idle      => AppColors.textDisabled,
        ProjectStatus.active    => AppColors.success,
        ProjectStatus.queued    => AppColors.textSecondary,
        ProjectStatus.training  => AppColors.accent,
        ProjectStatus.completed => AppColors.galaxy,
        ProjectStatus.error     => AppColors.error,
      };

  static ProjectStatus fromString(String s) =>
      ProjectStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => ProjectStatus.idle,
      );
}

// ─── Algorithm ────────────────────────────────────────────────────────────────

/// Algoritmos suportados pelo backend (GET /model_types).
/// Mapeiam diretamente para ModelType da API: linear-regression | decision-tree.
enum ProjectAlgorithm { linearRegression, decisionTree }

extension ProjectAlgorithmX on ProjectAlgorithm {
  String get label => switch (this) {
        ProjectAlgorithm.linearRegression => 'Regressão Linear',
        ProjectAlgorithm.decisionTree     => 'Árvore de Decisão',
      };

  /// Descrição resumida exibida no card do workspace.
  String get description => switch (this) {
        ProjectAlgorithm.linearRegression =>
            'Modela relação linear entre features e alvo. Ideal para regressão contínua.',
        ProjectAlgorithm.decisionTree =>
            'Classifica ou regride por particionamento recursivo. Interpretável e rápido.',
      };

  static ProjectAlgorithm fromString(String s) =>
      ProjectAlgorithm.values.firstWhere(
        (e) => e.name == s,
        orElse: () => ProjectAlgorithm.linearRegression,
      );
}

// ─── Model ────────────────────────────────────────────────────────────────────

class Project {
  final int? id;
  final String name;
  final String? description;
  final ProjectAlgorithm algorithm;
  final ProjectStatus status;
  final String? csvPath;
  final double storageMb;
  // ── Configuração do workspace (persistida) ──────────────────────────────
  final double trainSplit;
  /// Nome da coluna alvo (TRGT)
  final String? targetColumn;
  /// Lista de nomes de colunas marcadas como USE (JSON: ["col1","col2"])
  final String? useColumnsJson;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Project({
    this.id,
    required this.name,
    this.description,
    required this.algorithm,
    this.status = ProjectStatus.idle,
    this.csvPath,
    this.storageMb = 0.0,
    this.trainSplit = 0.80,
    this.targetColumn,
    this.useColumnsJson,
    required this.createdAt,
    required this.updatedAt,
  });

  String get storageLabel {
    if (storageMb >= 1024) {
      return '${(storageMb / 1024).toStringAsFixed(1)} GB';
    }
    return '${storageMb.toStringAsFixed(1)} MB';
  }

  String get configLabel => algorithm.label;

  // ── Serialização para/de SQLite ──────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name':           name,
        'description':    description,
        'algorithm':      algorithm.name,
        'status':         status.name,
        'csv_path':       csvPath,
        'storage_mb':     storageMb,
        'train_split':    trainSplit,
        'target_column':  targetColumn,
        'use_columns':    useColumnsJson,
        'created_at':     createdAt.toIso8601String(),
        'updated_at':     updatedAt.toIso8601String(),
      };

  factory Project.fromMap(Map<String, dynamic> m) => Project(
        id:             m['id'] as int?,
        name:           m['name'] as String,
        description:    m['description'] as String?,
        algorithm:      ProjectAlgorithmX.fromString(m['algorithm'] as String),
        status:         ProjectStatusX.fromString(m['status'] as String),
        csvPath:        m['csv_path'] as String?,
        storageMb:      (m['storage_mb'] as num).toDouble(),
        trainSplit:     (m['train_split'] as num?)?.toDouble() ?? 0.80,
        targetColumn:   m['target_column'] as String?,
        useColumnsJson: m['use_columns'] as String?,
        createdAt:      DateTime.parse(m['created_at'] as String),
        updatedAt:      DateTime.parse(m['updated_at'] as String),
      );

  Project copyWith({
    int? id,
    String? name,
    String? description,
    ProjectAlgorithm? algorithm,
    ProjectStatus? status,
    String? csvPath,
    double? storageMb,
    double? trainSplit,
    Object? targetColumn = _sentinel,
    Object? useColumnsJson = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Project(
        id:             id          ?? this.id,
        name:           name        ?? this.name,
        description:    description ?? this.description,
        algorithm:      algorithm   ?? this.algorithm,
        status:         status      ?? this.status,
        csvPath:        csvPath     ?? this.csvPath,
        storageMb:      storageMb   ?? this.storageMb,
        trainSplit:     trainSplit  ?? this.trainSplit,
        targetColumn:   targetColumn  == _sentinel ? this.targetColumn  : targetColumn  as String?,
        useColumnsJson: useColumnsJson == _sentinel ? this.useColumnsJson : useColumnsJson as String?,
        createdAt:      createdAt   ?? this.createdAt,
        updatedAt:      updatedAt   ?? this.updatedAt,
      );

// Sentinel para distinguir null intencional de "não fornecido"
static const Object _sentinel = Object();
}
