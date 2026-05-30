/// DTOs alinhados ao schema OpenAPI do NOVAML backend.
/// Referência: novaml-swagger-docs.json

// ─── Enums ────────────────────────────────────────────────────────────────────

enum ApiModelType {
  linearRegression('linear-regression', 'Regressão Linear'),
  decisionTree('decision-tree', 'Árvore de Decisão');

  const ApiModelType(this.value, this.label);
  final String value;
  final String label;

  static ApiModelType fromString(String s) =>
      ApiModelType.values.firstWhere(
        (e) => e.value == s,
        orElse: () => ApiModelType.linearRegression,
      );
}

enum ApiTask {
  regression('regression'),
  classification('classification');

  const ApiTask(this.value);
  final String value;

  static ApiTask fromString(String s) =>
      ApiTask.values.firstWhere(
        (e) => e.value == s,
        orElse: () => ApiTask.regression,
      );
}

// ─── Train ────────────────────────────────────────────────────────────────────

class TrainRequest {
  final ApiModelType modelType;
  final String datasetFilePath;
  final String targetName;
  final List<String>? featureNames;
  final double testSize;

  const TrainRequest({
    required this.modelType,
    required this.datasetFilePath,
    required this.targetName,
    required this.featureNames,
    this.testSize = 0.2,
  });

  Map<String, dynamic> toJson() => {
        'model_type':        modelType.value,
        'dataset_file_path': datasetFilePath,
        'target_name':       targetName,
        'feature_names':     featureNames,
        'test_size':         testSize,
      };
}

// ─── Predict ──────────────────────────────────────────────────────────────────

class PredictRequest {
  final int modelId;
  final String instancesFilePath;

  const PredictRequest({
    required this.modelId,
    required this.instancesFilePath,
  });

  Map<String, dynamic> toJson() => {
        'model_id':            modelId,
        'instances_file_path': instancesFilePath,
      };
}

// ─── StoredModel ──────────────────────────────────────────────────────────────

class StoredModel {
  final int? id;
  final ApiTask task;
  final ApiModelType modelType;
  final List<String>? featureNames;
  final String targetName;
  final List<num> validationPredictions;
  final List<num> validationGroundTruth;
  final double validationScore;

  const StoredModel({
    this.id,
    required this.task,
    required this.modelType,
    this.featureNames,
    required this.targetName,
    required this.validationPredictions,
    required this.validationGroundTruth,
    required this.validationScore,
  });

  factory StoredModel.fromJson(Map<String, dynamic> j) => StoredModel(
        id:          j['id'] as int?,
        task:        ApiTask.fromString(j['task'] as String),
        modelType:   ApiModelType.fromString(j['model_type'] as String),
        featureNames: (j['feature_names'] as List?)
            ?.map((e) => e as String)
            .toList(),
        targetName:  j['target_name'] as String,
        validationPredictions: (j['validation_predictions'] as List)
            .map((e) => e as num)
            .toList(),
        validationGroundTruth: (j['validation_ground_truth'] as List)
            .map((e) => e as num)
            .toList(),
        validationScore: (j['validation_score'] as num).toDouble(),
      );

  /// Score formatado como % para exibição
  String get scoreLabel =>
      '${(validationScore * 100).toStringAsFixed(2)}%';

  /// R² ou Accuracy dependendo da task
  String get scoreMetricLabel =>
      task == ApiTask.regression ? 'R² Score' : 'Accuracy';
}
