import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novaml_app/core/services/chat_api_client.dart';
import 'package:novaml_app/features/assistant/domain/models/chat_message.dart';

// ── Singleton do cliente ─────────────────────────────────────────────────────

final chatApiClientProvider = Provider<ChatApiClient>((_) => ChatApiClient());

// ── Status do serviço de chat ─────────────────────────────────────────────────
// Polling simples de health check — sem dependência de processo local.

enum ChatServiceStatus { online, starting, offline }

final chatServiceStatusProvider =
    StreamProvider<ChatServiceStatus>((ref) async* {
  // Primeira verificação imediata
  yield ChatServiceStatus.starting;

  while (true) {
    final client = ref.read(chatApiClientProvider);
    final ok = await client.healthCheck();
    yield ok ? ChatServiceStatus.online : ChatServiceStatus.offline;
    await Future<void>.delayed(const Duration(seconds: 5));
  }
});

// ── Conversa ─────────────────────────────────────────────────────────────────

class ChatNotifier extends Notifier<ConversationState> {
  static final _epoch = DateTime(2000);

  @override
  ConversationState build() => ConversationState(
        messages: [
          ChatMessage(
            id: 'welcome',
            role: MessageRole.assistant,
            content:
                'Olá! Sou o assistente NOVAML, especializado em Machine Learning aplicado à astronomia.\n\n'
                'Posso responder perguntas sobre algoritmos, datasets astronômicos e ajudar a interpretar seus dados. '
                'Você também pode fazer upload de um CSV para análise contextualizada.\n\n'
                'Como posso ajudar?',
            timestamp: _epoch,
          ),
        ],
      );

  ChatApiClient get _client => ref.read(chatApiClientProvider);

  // ── Enviar mensagem ────────────────────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isLoading) return;

    final userMsg = ChatMessage.user(text.trim());
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    try {
      final response = await _client.sendMessage(
        text.trim(),
        sessionId: state.csvSessionId,
      );
      final assistantMsg = ChatMessage.assistant(response.answer);
      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isLoading: false,
      );
    } catch (e) {
      final errMsg = ChatMessage.system(
        'Erro ao contatar o assistente: ${ChatApiClient.extractError(e)}\n'
        'Verifique se a API remota está disponível.',
        isError: true,
      );
      state = state.copyWith(
        messages: [...state.messages, errMsg],
        isLoading: false,
      );
    }
  }

  // ── Upload CSV ─────────────────────────────────────────────────────────────

  Future<void> uploadCsv({
    required String filename,
    required Uint8List bytes,
  }) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    final sysMsg = ChatMessage.system('Carregando arquivo "$filename"...');
    state = state.copyWith(messages: [...state.messages, sysMsg]);

    try {
      final response = await _client.uploadCsv(
        filename: filename,
        bytes: bytes,
      );

      final successMsg = ChatMessage.system(
        '✓ Dataset carregado: $filename\n\n${response.summary}',
      );

      state = state.copyWith(
        messages: [...state.messages, successMsg],
        isLoading: false,
        csvSessionId: response.sessionId,
        csvFilename: filename,
      );

      final promptMsg = ChatMessage.assistant(
        'Dataset carregado com sucesso! Posso agora responder perguntas '
        'contextualizadas com seus dados. O que gostaria de saber?',
      );
      state = state.copyWith(
        messages: [...state.messages, promptMsg],
      );
    } catch (e) {
      final errMsg = ChatMessage.system(
        'Erro ao carregar CSV: ${ChatApiClient.extractError(e)}',
        isError: true,
      );
      state = state.copyWith(
        messages: [...state.messages, errMsg],
        isLoading: false,
      );
    }
  }

  // ── Limpar conversa ────────────────────────────────────────────────────────

  void clearConversation() => state = build();

  /// Remove o CSV da sessão atual sem limpar o histórico.
  void detachCsv() {
    state = state.copyWith(clearCsv: true);
    final sysMsg = ChatMessage.system('Dataset removido da sessão.');
    state = state.copyWith(messages: [...state.messages, sysMsg]);
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ConversationState>(
  ChatNotifier.new,
);
