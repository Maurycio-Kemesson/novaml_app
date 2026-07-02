import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:novaml_app/core/models/api_models.dart';

/// Cliente HTTP para o backend NOVAML (FastAPI em localhost:8000).
class NovaMLApiClient {
  static const String _baseUrl = 'http://localhost:8000';

  late final Dio _dio;

  NovaMLApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 60), // treino pode demorar
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,   // mostra body de erros (500/422) nos logs
        logPrint: (obj) => print('[API] $obj'),
      ),
    );
  }

  // ── Error helper ────────────────────────────────────────────────────────

  /// Extrai uma mensagem legível de um [DioException].
  /// FastAPI retorna `{"detail": "..."}` em erros 4xx/5xx.
  static String extractError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final detail = data['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
        if (detail is List && detail.isNotEmpty) {
          // Erros de validação 422 têm lista de objetos {loc, msg, type}
          return detail
              .map((d) => d is Map ? d['msg'] ?? d.toString() : d.toString())
              .join('; ');
        }
      }
      if (data is String && data.isNotEmpty) {
        // Erros 500 não tratados no backend retornam o traceback Python cru
        // como corpo da resposta. Não expor isso na UI — é ilegível para o
        // usuário e pode vazar caminhos internos do servidor.
        final looksLikeTraceback =
            data.contains('Traceback (most recent call last)') ||
                data.length > 300;
        if (!looksLikeTraceback) return data;
      }
      final status = e.response?.statusCode;
      return status != null
          ? 'Erro interno no servidor (HTTP $status). Verifique os logs do backend.'
          : 'Falha de comunicação com o servidor.';
    }
    return e.toString();
  }

  // ── Health ──────────────────────────────────────────────────────────────

  /// Verifica se o backend está respondendo.
  Future<bool> healthCheck() async {
    try {
      final res = await _dio.get('/');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Model Types ─────────────────────────────────────────────────────────

  /// Retorna os tipos de modelo disponíveis no backend.
  Future<List<ApiModelType>> getModelTypes() async {
    final res = await _dio.get<List>('/model_types');
    return (res.data ?? [])
        .map((e) => ApiModelType.fromString(e as String))
        .toList();
  }

  // ── Models ───────────────────────────────────────────────────────────────

  Future<List<StoredModel>> getModels() async {
    final res = await _dio.get<List>('/models');
    return (res.data ?? [])
        .map((e) => StoredModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StoredModel> getModel(int modelId) async {
    final res = await _dio.get<Map<String, dynamic>>('/models/$modelId');
    return StoredModel.fromJson(res.data!);
  }

  Future<StoredModel> deleteModel(int modelId) async {
    final res =
        await _dio.delete<Map<String, dynamic>>('/models/$modelId');
    return StoredModel.fromJson(res.data!);
  }

  Future<String> exportModel(int modelId) async {
    // responseType.plain evita que o Dio tente fazer JSON decode automaticamente,
    // prevenindo ClassCastException quando o backend retorna Map mas tipamos String.
    final res = await _dio.get(
      '/export/$modelId',
      options: Options(responseType: ResponseType.plain),
    );
    final raw = res.data?.toString() ?? '';

    // Backend pode retornar string plana ("/path/to/model.pkl")
    // ou JSON encapsulado ('{"path": "/path/to/model.pkl"}').
    if (raw.trimLeft().startsWith('{')) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return (decoded['path'] ??
                decoded['file_path'] ??
                decoded['export_path'] ??
                raw)
            .toString();
      } catch (_) {/* não é JSON válido — usa raw */}
    }
    return raw;
  }

  // ── Train ────────────────────────────────────────────────────────────────

  /// Envia uma requisição de treinamento e retorna o modelo treinado.
  Future<StoredModel> train(TrainRequest request) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/train',
      data: request.toJson(),
    );
    return StoredModel.fromJson(res.data!);
  }

  // ── Predict ──────────────────────────────────────────────────────────────

  Future<List<num>> predict(PredictRequest request) async {
    final res = await _dio.post<List>(
      '/predict',
      data: request.toJson(),
    );
    return (res.data ?? []).map((e) => e as num).toList();
  }
}
