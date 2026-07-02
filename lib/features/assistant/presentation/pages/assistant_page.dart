import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';
import 'package:novaml_app/features/assistant/domain/models/chat_message.dart';
import 'package:novaml_app/features/assistant/presentation/providers/chat_provider.dart';

/// Página principal do assistente IA — interface de chat com RAG astronômico.
class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _focusNode.requestFocus();
    await ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _pickCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    await ref.read(chatProvider.notifier).uploadCsv(
          filename: file.name,
          bytes: Uint8List.fromList(file.bytes!),
        );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final conversation = ref.watch(chatProvider);
    final serviceStatus = ref.watch(chatServiceStatusProvider);

    // Auto-scroll ao receber nova mensagem
    ref.listen(chatProvider, (_, __) => _scrollToBottom());

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          // ── Painel principal de chat ────────────────────────────────────
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _ChatHeader(
                  serviceStatus: serviceStatus,
                  hasCsv: conversation.hasCsvSession,
                  csvFilename: conversation.csvFilename,
                  onClearCsv: () => ref.read(chatProvider.notifier).detachCsv(),
                  onClearConversation: () =>
                      ref.read(chatProvider.notifier).clearConversation(),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: _MessageList(
                    messages: conversation.messages,
                    isLoading: conversation.isLoading,
                    scrollController: _scrollController,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _InputBar(
                  controller: _textController,
                  focusNode: _focusNode,
                  isLoading: conversation.isLoading,
                  hasCsv: conversation.hasCsvSession,
                  onSend: _send,
                  onPickCsv: _pickCsv,
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.lg),

          // ── Painel lateral de informações ───────────────────────────────
          SizedBox(
            width: 280,
            child: _InfoPanel(
              conversation: conversation,
              serviceStatus: serviceStatus,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.serviceStatus,
    required this.hasCsv,
    required this.csvFilename,
    required this.onClearCsv,
    required this.onClearConversation,
  });

  final AsyncValue<ChatServiceStatus> serviceStatus;
  final bool hasCsv;
  final String? csvFilename;
  final VoidCallback onClearCsv;
  final VoidCallback onClearConversation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded,
              size: 20, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assistente NOVAML',
                  style:
                      AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
              Text(
                'RAG · API remota · ngrok',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          _StatusChip(serviceStatus: serviceStatus),
          const Spacer(),
          if (hasCsv) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.infoSubtle,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.table_chart_rounded,
                      size: 12, color: AppColors.info),
                  const SizedBox(width: 4),
                  Text(
                    csvFilename ?? 'CSV',
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.info),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onClearCsv,
                    child: const Icon(Icons.close_rounded,
                        size: 12, color: AppColors.info),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          IconButton(
            tooltip: 'Limpar conversa',
            icon: const Icon(Icons.delete_sweep_rounded,
                size: 18, color: AppColors.textSecondary),
            onPressed: onClearConversation,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status chip
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.serviceStatus});

  final AsyncValue<ChatServiceStatus> serviceStatus;

  @override
  Widget build(BuildContext context) {
    final (color, label) = serviceStatus.when(
      data: (s) => switch (s) {
        ChatServiceStatus.online => (AppColors.success, 'Online'),
        ChatServiceStatus.starting => (AppColors.warning, 'Iniciando'),
        ChatServiceStatus.offline => (AppColors.error, 'Offline'),
      },
      loading: () => (AppColors.textDisabled, '...'),
      error: (_, __) => (AppColors.error, 'Erro'),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption.copyWith(color: color)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lista de mensagens
// ─────────────────────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.isLoading,
    required this.scrollController,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: messages.length + (isLoading ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == messages.length) return const _ThinkingBubble();
          return _MessageBubble(message: messages[i]);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bubble de mensagem
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) return _SystemBubble(message: message);
    if (message.isUser) return _UserBubble(message: message);
    return _AssistantBubble(message: message);
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md, left: 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Text(message.content,
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.textPrimary)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.accent.withOpacity(0.2),
            child: const Icon(Icons.person_rounded,
                size: 16, color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md, right: 60),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.surface2,
            child: const Icon(Icons.auto_awesome_rounded,
                size: 16, color: AppColors.accent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: SelectableText(
                message.content,
                style: AppTextStyles.bodyMd
                    .copyWith(color: AppColors.textPrimary, height: 1.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemBubble extends StatelessWidget {
  const _SystemBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final color = message.isError ? AppColors.error : AppColors.textSecondary;
    final bgColor = message.isError
        ? AppColors.errorSubtle
        : AppColors.surface2.withOpacity(0.5);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Text(
          message.content,
          style: AppTextStyles.caption.copyWith(color: color, height: 1.5),
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble();

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md, right: 60),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.surface2,
            child: const Icon(Icons.auto_awesome_rounded,
                size: 16, color: AppColors.accent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: FadeTransition(
              opacity: _anim,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => _Dot(delay: i * 200),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.delay});
  final int delay;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.4 + (_anim.value * 0.6)),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barra de input
// ─────────────────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.hasCsv,
    required this.onSend,
    required this.onPickCsv,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final bool hasCsv;
  final VoidCallback onSend;
  final VoidCallback onPickCsv;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderActive),
      ),
      child: Row(
        children: [
          // Botão de upload CSV
          Tooltip(
            message: hasCsv
                ? 'Trocar CSV da sessão'
                : 'Carregar CSV para análise contextualizada',
            child: IconButton(
              onPressed: isLoading ? null : onPickCsv,
              icon: Icon(
                Icons.upload_file_rounded,
                size: 20,
                color: hasCsv ? AppColors.info : AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.xs),

          // Campo de texto
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !isLoading,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style:
                  AppTextStyles.bodyMd.copyWith(color: AppColors.textPrimary),
              onSubmitted: isLoading ? null : (_) => onSend(),
              decoration: InputDecoration(
                hintText: isLoading
                    ? 'Aguardando resposta...'
                    : hasCsv
                        ? 'Pergunte sobre seu dataset...'
                        : 'Pergunte sobre algoritmos, astronomia ou ML...',
                hintStyle: AppTextStyles.bodyMd
                    .copyWith(color: AppColors.textDisabled),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.xs),

          // Botão enviar
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            child: isLoading
                ? const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  )
                : IconButton(
                    onPressed: onSend,
                    icon: const Icon(Icons.send_rounded,
                        size: 20, color: AppColors.accent),
                    tooltip: 'Enviar (Enter)',
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painel lateral de informações
// ─────────────────────────────────────────────────────────────────────────────

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.conversation,
    required this.serviceStatus,
  });

  final ConversationState conversation;
  final AsyncValue<ChatServiceStatus> serviceStatus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status do serviço
        _InfoCard(
          title: 'Serviço de IA',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                  label: 'Status',
                  value: serviceStatus.when(
                    data: (s) => switch (s) {
                      ChatServiceStatus.online => 'Online',
                      ChatServiceStatus.starting => 'Iniciando',
                      ChatServiceStatus.offline => 'Offline',
                    },
                    loading: () => '...',
                    error: (_, __) => 'Erro',
                  ),
                  valueColor: serviceStatus.when(
                    data: (s) => switch (s) {
                      ChatServiceStatus.online => AppColors.success,
                      ChatServiceStatus.starting => AppColors.warning,
                      ChatServiceStatus.offline => AppColors.error,
                    },
                    loading: () => AppColors.textDisabled,
                    error: (_, __) => AppColors.error,
                  )),
              const _InfoRow(label: 'Endpoint', value: 'ngrok (remoto)'),
              const _InfoRow(label: 'Modelo', value: 'qwen2.5:7b'),
              const _InfoRow(label: 'Embeddings', value: 'fastembed CPU'),
              const _InfoRow(label: 'Vector DB', value: 'ChromaDB'),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // CSV carregado
        if (conversation.hasCsvSession)
          _InfoCard(
            title: 'Dataset Ativo',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.table_chart_rounded,
                        size: 14, color: AppColors.info),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        conversation.csvFilename ?? 'CSV',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.info),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Contexto incluso nas respostas',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

        const SizedBox(height: AppSpacing.md),

        // Dicas
        _InfoCard(
          title: 'Exemplos de Perguntas',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SuggestionChip(
                'Qual algoritmo usar para classificar estrelas, galáxias e quasares?',
              ),
              _SuggestionChip(
                'Explique como funciona uma Árvore de Decisão.',
              ),
              _SuggestionChip(
                'Como interpretar o R² de um modelo de regressão?',
              ),
              if (conversation.hasCsvSession)
                _SuggestionChip(
                  'Com base no meu dataset, quais colunas são mais relevantes?',
                ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Pré-requisitos
        // _InfoCard(
        //   title: 'Pré-requisitos',
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       const _InfoRow(label: 'Runtime', value: 'FastAPI + RAG'),
        //       const _InfoRow(label: 'Host', value: 'ngrok-free.dev'),
        //       const SizedBox(height: 4),
        //       Text(
        //         'API remota ativa.\nNenhuma configuração local necessária.',
        //         style: AppTextStyles.caption
        //             .copyWith(color: AppColors.textSecondary, height: 1.5),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
          Text(value,
              style: AppTextStyles.caption.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SuggestionChip extends ConsumerWidget {
  const _SuggestionChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        await ref.read(chatProvider.notifier).sendMessage(text);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
