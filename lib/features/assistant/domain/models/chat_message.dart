/// Papel de quem enviou a mensagem no chat.
enum MessageRole { user, assistant, system }

/// Representa uma mensagem na conversa com o assistente.
class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isError;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isError = false,
  });

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isSystem => role == MessageRole.system;

  /// Cria mensagem do usuário.
  factory ChatMessage.user(String content) => ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        role: MessageRole.user,
        content: content,
        timestamp: DateTime.now(),
      );

  /// Cria resposta do assistente.
  factory ChatMessage.assistant(String content) => ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: content,
        timestamp: DateTime.now(),
      );

  /// Cria mensagem de sistema (ex: "CSV carregado com sucesso").
  factory ChatMessage.system(String content, {bool isError = false}) =>
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        role: MessageRole.system,
        content: content,
        timestamp: DateTime.now(),
        isError: isError,
      );
}

/// Estado completo da sessão de conversa com o assistente.
class ConversationState {
  final List<ChatMessage> messages;
  final bool isLoading;

  /// ID da sessão CSV atual (null = sem CSV carregado).
  final String? csvSessionId;

  /// Nome do arquivo CSV carregado.
  final String? csvFilename;

  const ConversationState({
    this.messages = const [],
    this.isLoading = false,
    this.csvSessionId,
    this.csvFilename,
  });

  bool get hasCsvSession => csvSessionId != null;

  ConversationState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? csvSessionId,
    String? csvFilename,
    bool clearCsv = false,
  }) =>
      ConversationState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        csvSessionId: clearCsv ? null : (csvSessionId ?? this.csvSessionId),
        csvFilename: clearCsv ? null : (csvFilename ?? this.csvFilename),
      );
}
