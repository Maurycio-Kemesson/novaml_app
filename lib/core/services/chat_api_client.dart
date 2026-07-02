import 'dart:typed_data';
import 'package:dio/dio.dart';

/// Resposta de uma mensagem de chat.
class ChatResponse {
  final String answer;
  const ChatResponse({required this.answer});

  /// Aceita tanto `{ "answer": "..." }` quanto uma string plana.
  factory ChatResponse.fromDynamic(dynamic data) {
    if (data is Map<String, dynamic>) {
      return ChatResponse(answer: data['answer'] as String? ?? '');
    }
    return ChatResponse(answer: data?.toString() ?? '');
  }
}

/// Resposta do upload de CSV.
class CsvUploadResponse {
  final String sessionId;
  final String summary;
  const CsvUploadResponse({required this.sessionId, required this.summary});

  /// Aceita tanto `{ "session_id": ..., "summary": ... }` quanto string plana.
  factory CsvUploadResponse.fromDynamic(dynamic data) {
    if (data is Map<String, dynamic>) {
      return CsvUploadResponse(
        sessionId: data['session_id'] as String? ?? '',
        summary: data['summary'] as String? ?? '',
      );
    }
    // Resposta plana — considera como summary sem session_id persistente
    return CsvUploadResponse(
      sessionId: '',
      summary: data?.toString() ?? '',
    );
  }
}

/// URL base da API de chat NOVAML.
/// Pode ser sobrescrita via variável de ambiente NOVAML_CHAT_URL.
const String kChatBaseUrl = 'https://truffle-regally-dominion.ngrok-free.dev';

/// Cliente HTTP para o serviço de chat NOVAML (FastAPI + RAG).
class ChatApiClient {
  late final Dio _dio;

  ChatApiClient({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? kChatBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 120), // LLM pode demorar
        headers: {
          'Content-Type': 'application/json',
          // Necessário para contornar o interstitial do ngrok em clientes não-browser
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('[CHAT-API] $obj'),
      ),
    );
  }

  // ── Error helper ────────────────────────────────────────────────────────

  /// Extrai mensagem legível de um [DioException].
  static String extractError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final detail = data['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
      }
      if (data is String && data.isNotEmpty) return data;
      final status = e.response?.statusCode;
      if (status != null) return 'Servidor retornou HTTP $status';
    }
    return e.toString();
  }

  // ── Health ──────────────────────────────────────────────────────────────

  Future<bool> healthCheck() async {
    try {
      final res = await _dio.get<dynamic>('/health');
      final data = res.data;
      if (data is Map) return data['status'] == 'ok';
      // Resposta plana "ok" ou qualquer 2xx é suficiente
      return res.statusCode != null && res.statusCode! < 400;
    } catch (_) {
      return false;
    }
  }

  // ── Chat ─────────────────────────────────────────────────────────────────

  /// Envia uma pergunta ao assistente.
  /// [sessionId] é opcional — quando presente, inclui contexto do CSV carregado.
  Future<ChatResponse> sendMessage(String question, {String? sessionId}) async {
    final res = await _dio.post<dynamic>(
      '/chat',
      data: {
        'question': question,
        if (sessionId != null) 'session_id': sessionId,
      },
    );
    return ChatResponse.fromDynamic(res.data);
  }

  // ── Upload CSV ───────────────────────────────────────────────────────────

  /// Envia um arquivo CSV para análise.
  /// Retorna um [CsvUploadResponse] com session_id e resumo automático.
  Future<CsvUploadResponse> uploadCsv({
    required String filename,
    required Uint8List bytes,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType('text', 'csv'),
      ),
    });

    final res = await _dio.post<dynamic>(
      '/upload-csv',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        headers: {'ngrok-skip-browser-warning': 'true'},
      ),
    );
    return CsvUploadResponse.fromDynamic(res.data);
  }
}
