import 'package:flutter/material.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';
import 'package:novaml_app/shared/widgets/components/nova_button.dart';
import 'package:novaml_app/shared/widgets/layout/page_container.dart';

/// Tela de upload de CSV com drag-and-drop.
/// Lógica de upload implementada na próxima iteração.
class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      title: 'Upload de Dataset',
      subtitle: 'Envie um arquivo CSV com dados astronômicos para análise.',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              // Drop zone
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 280,
                decoration: BoxDecoration(
                  color: _dragging
                      ? AppColors.accentSubtle
                      : AppColors.surface1,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color:
                        _dragging ? AppColors.accent : AppColors.border,
                    width: _dragging ? 1.5 : 1,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.upload_file_outlined,
                      size: 48,
                      color: _dragging
                          ? AppColors.accent
                          : AppColors.textDisabled,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _dragging
                          ? 'Solte o arquivo aqui'
                          : 'Arraste um arquivo CSV aqui',
                      style: AppTextStyles.h3.copyWith(
                        color: _dragging
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Apenas arquivos .csv são aceitos',
                      style: AppTextStyles.bodySm,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    NovaButton(
                      label: 'Selecionar Arquivo',
                      variant: NovaButtonVariant.secondary,
                      onPressed: () {/* TODO: file picker */},
                      leading: const Icon(Icons.folder_open_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Informações de formato
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.infoSubtle,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                      color: AppColors.accent.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: AppColors.accent),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'O dataset deve conter colunas compatíveis com o SDSS. '
                        'A primeira linha deve ser o cabeçalho.',
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.accent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
