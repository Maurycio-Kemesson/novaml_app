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

  /// Mapeamento índice → nome original da classe.
  /// Presente quando o backend retorna labels string (ex: "GALAXY", "QSO").
  /// null quando os valores já são numéricos.
  final Map<int, String>? classLabels;

  StoredModel({
    this.id,
    required this.task,
    required this.modelType,
    this.featureNames,
    required this.targetName,
    required this.validationPredictions,
    required this.validationGroundTruth,
    required this.validationScore,
    this.classLabels,
  });

  factory StoredModel.fromJson(Map<String, dynamic> j) {
    final rawPreds = j['validation_predictions'] as List;
    final rawTruth = j['validation_ground_truth'] as List;

    // Detecta se os valores são string labels não numéricas
    // Constrói mapa estável label→índice ordenando alfabeticamente
    final stringLabels = <String>{};
    for (final e in [...rawPreds, ...rawTruth]) {
      if (e is! num && num.tryParse(e.toString()) == null) {
        stringLabels.add(e.toString());
      }
    }

    final Map<String, int> labelToIdx = {};
    if (stringLabels.isNotEmpty) {
      final sorted = stringLabels.toList()..sort();
      for (var i = 0; i < sorted.length; i++) {
        labelToIdx[sorted[i]] = i;
      }
    }

    num parseVal(dynamic e) {
      if (e is num) return e;
      final s = e.toString();
      final n = num.tryParse(s);
      if (n != null) return n;
      // String label → índice estável
      return labelToIdx[s] ?? 0;
    }

    final classLabels = labelToIdx.isEmpty
        ? null
        : {for (final entry in labelToIdx.entries) entry.value: entry.key};

    return StoredModel(
      id: j['id'] is int ? j['id'] as int : int.tryParse(j['id'].toString()),
      task: ApiTask.fromString(j['task'] as String),
      modelType: ApiModelType.fromString(j['model_type'] as String),
      featureNames: (j['feature_names'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      targetName: j['target_name'] as String,
      validationPredictions: rawPreds.map(parseVal).toList(),
      validationGroundTruth: rawTruth.map(parseVal).toList(),
      validationScore: j['validation_score'] is num
          ? (j['validation_score'] as num).toDouble()
          : double.parse(j['validation_score'].toString()),
      classLabels: classLabels,
    );
  }

  /// Score formatado como % para exibição
  String get scoreLabel => '${(validationScore * 100).toStringAsFixed(2)}%';

  /// R² ou Accuracy dependendo da task
  String get scoreMetricLabel =>
      task == ApiTask.regression ? 'R² Score' : 'Accuracy';
}
