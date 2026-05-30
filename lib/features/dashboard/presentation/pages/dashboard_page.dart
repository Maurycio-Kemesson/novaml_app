import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novaml_app/core/models/api_models.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';
import 'package:novaml_app/shared/providers/models_provider.dart';
import 'package:novaml_app/shared/providers/navigation_provider.dart';
import 'package:novaml_app/shared/widgets/components/nova_button.dart';
import 'package:novaml_app/shared/widgets/components/nova_empty_state.dart';
import 'package:novaml_app/shared/widgets/layout/page_container.dart';

/// Dashboard — visão geral dos modelos treinados e métricas.
/// Consome [storedModelsProvider] e [lastTrainedModelProvider] da API real.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelsAsync = ref.watch(storedModelsProvider);
    final lastModel = ref.watch(lastTrainedModelProvider);

    return PageContainer(
      title: 'Dashboard',
      subtitle: 'Visão geral de modelos treinados e métricas de validação.',
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
          child: Text('Erro: $err',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
        ),
        data: (models) {
          if (models.isEmpty) {
            return const NovaEmptyState(
              icon: Icons.bar_chart_outlined,
              title: 'Nenhum modelo treinado',
              subtitle:
                  'Configure um projeto no workspace e inicie o treinamento para ver as métricas aqui.',
              actionLabel: 'Ir para Workspace',
            );
          }
          return _DashboardContent(models: models, lastModel: lastModel);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.models, this.lastModel});

  final List<StoredModel> models;
  final StoredModel? lastModel;

  @override
  Widget build(BuildContext context) {
    // Separar por task
    final classModels =
        models.where((m) => m.task == ApiTask.classification).toList();
    final regModels =
        models.where((m) => m.task == ApiTask.regression).toList();

    // Média dos scores
    double avgScore(List<StoredModel> ms) => ms.isEmpty
        ? 0
        : ms.map((m) => m.validationScore).reduce((a, b) => a + b) /
            ms.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI row ────────────────────────────────────────────────────────
          Row(
            children: [
              _KpiCard(
                icon: Icons.layers_rounded,
                label: 'Total de Modelos',
                value: models.length.toString(),
              ),
              const SizedBox(width: 16),
              _KpiCard(
                icon: Icons.category_outlined,
                label: 'Classificação',
                value: classModels.length.toString(),
                sub: classModels.isNotEmpty
                    ? 'Avg acc: ${(avgScore(classModels) * 100).toStringAsFixed(1)}%'
                    : null,
                color: AppColors.warning,
              ),
              const SizedBox(width: 16),
              _KpiCard(
                icon: Icons.trending_up_rounded,
                label: 'Regressão',
                value: regModels.length.toString(),
                sub: regModels.isNotEmpty
                    ? 'Avg R²: ${(avgScore(regModels) * 100).toStringAsFixed(1)}%'
                    : null,
                color: AppColors.accent,
              ),
              if (lastModel != null) ...[
                const SizedBox(width: 16),
                _KpiCard(
                  icon: Icons.new_releases_outlined,
                  label: 'Último Treinado',
                  value: lastModel!.scoreLabel,
                  sub: lastModel!.modelType.label,
                  color: AppColors.success,
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),

          // ── Tabela de todos os modelos ───────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Text('Todos os Modelos', style: AppTextStyles.h2),
                ),
                const Divider(height: 1, color: AppColors.border),
                // Header
                _TableRow(
                  cells: const ['ID', 'Tipo', 'Task', 'Target', 'Score', 'Amostras'],
                  isHeader: true,
                ),
                const Divider(height: 1, color: AppColors.border),
                ...models.asMap().entries.map((e) {
                  final m = e.value;
                  final isLast = e.key == models.length - 1;
                  return Column(
                    children: [
                      _TableRow(
                        cells: [
                          '#${m.id ?? '—'}',
                          m.modelType.label,
                          m.task.value,
                          m.targetName,
                          m.scoreLabel,
                          m.validationPredictions.length.toString(),
                        ],
                        highlight: m.id == lastModel?.id,
                      ),
                      if (!isLast)
                        const Divider(height: 1, color: AppColors.border),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accent;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: c),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      style: AppTextStyles.labelSm
                          .copyWith(color: AppColors.textDisabled)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(value,
                style: AppTextStyles.displayMd.copyWith(
                    color: c, fontSize: 28)),
            if (sub != null)
              Text(sub!, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  const _TableRow({required this.cells, this.isHeader = false, this.highlight = false});

  final List<String> cells;
  final bool isHeader;
  final bool highlight;

  static const _flex = [1, 3, 2, 3, 2, 2];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: highlight ? AppColors.accentSubtle : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(cells.length, (i) {
          return Expanded(
            flex: i < _flex.length ? _flex[i] : 1,
            child: Text(
              cells[i],
              style: isHeader
                  ? AppTextStyles.labelSm.copyWith(
                      color: AppColors.textDisabled,
                      letterSpacing: 0.6,
                    )
                  : AppTextStyles.bodyMd.copyWith(
                      color: i == 4
                          ? AppColors.accent
                          : AppColors.textPrimary,
                      fontWeight:
                          i == 4 ? FontWeight.w600 : FontWeight.w400,
                    ),
            ),
          );
        }),
      ),
    );
  }
}
