import 'package:flutter/material.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';
import 'package:novaml_app/shared/widgets/components/nova_button.dart';
import 'package:novaml_app/shared/widgets/layout/page_container.dart';

/// Interface de chat com o assistente IA (Ollama/qwen2.5).
class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      role: 'assistant',
      content:
          'Olá! Sou o NOVA, seu assistente de Machine Learning para Astrofísica. '
          'Posso ajudar com seleção de algoritmos, configuração de hiperparâmetros e '
          'interpretação de resultados. Como posso ajudar?',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // scrollable: false → PageContainer envolve o child em Expanded,
    // garantindo constraints tight para o Column interno.
    return PageContainer(
      title: 'Assistente IA',
      subtitle: 'Powered by Ollama · qwen2.5:7b',
      scrollable: false,
      child: Column(
        children: [
          // Área de mensagens
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: _messages.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, i) =>
                    _MessageBubble(message: _messages[i]),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Input de mensagem
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 1,
                  style: AppTextStyles.bodyMd,
                  decoration: const InputDecoration(
                    hintText:
                        'Pergunte sobre algoritmos, dados ou astrofísica...',
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              NovaButton(
                label: 'Enviar',
                onPressed: _send,
                leading: const Icon(Icons.send_rounded),
                dense: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: text));
      _controller.clear();
    });
    // TODO: integração com backend Ollama
  }
}

class _ChatMessage {
  final String role;
  final String content;
  const _ChatMessage({required this.role, required this.content});
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  bool get _isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isUser) ...[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.galaxy],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome,
                size: 14, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _isUser
                  ? AppColors.accentSubtle
                  : AppColors.surface2,
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: _isUser
                    ? AppColors.accent.withOpacity(0.2)
                    : AppColors.border,
              ),
            ),
            child: Text(
              message.content,
              style: AppTextStyles.bodyMd.copyWith(
                color: _isUser
                    ? AppColors.accent
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
