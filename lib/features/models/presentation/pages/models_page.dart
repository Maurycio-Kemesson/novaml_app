import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novaml_app/core/models/api_models.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';
import 'package:novaml_app/shared/providers/models_provider.dart';
import 'package:novaml_app/shared/widgets/components/nova_button.dart';
import 'package:novaml_app/shared/widgets/components/nova_empty_state.dart';
import 'package:novaml_app/shared/widgets/layout/page_container.dart';

/// Tela de listagem e gerenciamento de modelos treinados — dados reais da API.
class ModelsPage extends ConsumerWidget {
  const ModelsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelsAsync = ref.watch(storedModelsProvider);

    return PageContainer(
      title: 'Modelos',
      subtitle: 'Modelos treinados salvos localmente via backend FastAPI.',
      headerActions: [
        NovaButton(
          label: 'Atualizar',
          variant: NovaButtonVariant.secondary,
          onPressed: () => ref.read(storedModelsProvider.notifier).refresh(),
          leading: const Icon(Icons.refresh_rounded, size: 16),
        ),
      ],
      child: modelsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 40, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Erro ao carregar modelos', style: AppTextStyles.h3),
              const SizedBox(height: 6),
              Text(
                err.toString(),
                style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              NovaButton(
                label: 'Tentar Novamente',
                onPressed: () =>
                    ref.read(storedModelsProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
        data: (models) => models.isEmpty
            ? const NovaEmptyState(
                icon: Icons.layers_outlined,
                title: 'Nenhum modelo treinado',
                subtitle: 'Treine um modelo para vê-lo listado aqui.',
                actionLabel: 'Ir para Treinamento',
              )
            : _ModelsList(models: models),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lista de modelos
// ─────────────────────────────────────────────────────────────────────────────

class _ModelsList extends ConsumerWidget {
  const _ModelsList({required this.models});

  final List<StoredModel> models;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '${models.length} modelo${models.length != 1 ? 's' : ''} encontrado${models.length != 1 ? 's' : ''}',
              style: AppTextStyles.bodySm,
            ),
          ),
          ...models.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ModelCard(model: m),
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card individual
// ─────────────────────────────────────────────────────────────────────────────

class _ModelCard extends ConsumerStatefulWidget {
  const _ModelCard({required this.model});

  final StoredModel model;

  @override
  ConsumerState<_ModelCard> createState() => _ModelCardState();
}

class _ModelCardState extends ConsumerState<_ModelCard> {
  bool _deleting = false;
  bool _exporting = false;

  StoredModel get m => widget.model;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Row(
            children: [
              // Ícone de tarefa
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accentSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  m.task == ApiTask.classification
                      ? Icons.category_outlined
                      : Icons.trending_up_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(m.modelType.label, style: AppTextStyles.h3),
                        const SizedBox(width: 8),
                        _TaskChip(task: m.task),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${m.id}  ·  Target: ${m.targetName}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              // Score badge
              _ScoreBadge(
                score: m.validationScore,
                label: m.scoreMetricLabel,
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),

          // ── Features ────────────────────────────────────────────────────────
          if (m.featureNames != null && m.featureNames!.isNotEmpty) ...[
            Text(
              'FEATURES (${m.featureNames!.length})',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textDisabled,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: m.featureNames!
                  .take(10)
                  .map((f) => _FeatureTag(label: f))
                  .toList()
                ..addAll(
                  m.featureNames!.length > 10
                      ? [
                          _FeatureTag(
                            label:
                                '+${m.featureNames!.length - 10} mais',
                            muted: true,
                          )
                        ]
                      : [],
                ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Stats ────────────────────────────────────────────────────────────
          Row(
            children: [
              _StatItem(
                label: 'PREDIÇÕES VALIDAÇÃO',
                value: m.validationPredictions.length.toString(),
              ),
              const SizedBox(width: 24),
              _StatItem(
                label: m.scoreMetricLabel.toUpperCase(),
                value: m.scoreLabel,
                accent: true,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Ações ────────────────────────────────────────────────────────────
          Row(
            children: [
              NovaButton(
                label: _exporting ? 'Exportando...' : 'Exportar .pkl',
                variant: NovaButtonVariant.secondary,
                onPressed: (_exporting || _deleting)
                    ? null
                    : () => _export(context),
                leading: const Icon(Icons.download_outlined, size: 15),
              ),
              const SizedBox(width: 8),
              NovaButton(
                label: _deleting ? 'Excluindo...' : 'Excluir',
                variant: NovaButtonVariant.secondary,
                onPressed: (_deleting || _exporting)
                    ? null
                    : () => _confirmDelete(context),
                leading: Icon(Icons.delete_outline_rounded,
                    size: 15, color: AppColors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    if (m.id == null) return;
    setState(() => _exporting = true);
    final path =
        await ref.read(storedModelsProvider.notifier).exportModel(m.id!);
    if (!mounted) return;
    setState(() => _exporting = false);

    if (path != null) {
      // Copia o path para o clipboard e mostra snackbar
      await Clipboard.setData(ClipboardData(text: path));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Exportado: $path (caminho copiado)'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 4),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Falha ao exportar o modelo.'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Excluir modelo?', style: AppTextStyles.h3),
        content: Text(
          'O modelo ${m.modelType.label} (ID ${m.id}) será removido permanentemente.',
          style: AppTextStyles.bodySm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Excluir',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (ok != true || m.id == null) return;
    setState(() => _deleting = true);
    await ref.read(storedModelsProvider.notifier).deleteModel(m.id!);
    if (mounted) setState(() => _deleting = false);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers visuais
// ─────────────────────────────────────────────────────────────────────────────

class _TaskChip extends StatelessWidget {
  const _TaskChip({required this.task});

  final ApiTask task;

  @override
  Widget build(BuildContext context) {
    final isClass = task == ApiTask.classification;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isClass ? AppColors.warning : AppColors.accent)
            .withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: (isClass ? AppColors.warning : AppColors.accent)
              .withOpacity(0.4),
        ),
      ),
      child: Text(
        isClass ? 'CLASSIFICAÇÃO' : 'REGRESSÃO',
        style: AppTextStyles.caption.copyWith(
          color: isClass ? AppColors.warning : AppColors.accent,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score, required this.label});

  final double score;
  final String label;

  @override
  Widget build(BuildContext context) {
    final pct = score * 100;
    final color = pct >= 85
        ? AppColors.success
        : pct >= 60
            ? AppColors.warning
            : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${pct.toStringAsFixed(2)}%',
          style: AppTextStyles.displayMd.copyWith(
            color: color,
            fontSize: 24,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textDisabled),
        ),
      ],
    );
  }
}

class _FeatureTag extends StatelessWidget {
  const _FeatureTag({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: muted ? AppColors.textDisabled : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textDisabled,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.labelMd.copyWith(
            color: accent ? AppColors.accent : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
