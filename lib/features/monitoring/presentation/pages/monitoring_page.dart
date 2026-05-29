import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novaml_app/core/services/system_info_service.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';
import 'package:novaml_app/shared/providers/system_info_provider.dart';
import 'package:novaml_app/shared/widgets/components/nova_card.dart';
import 'package:novaml_app/shared/widgets/indicators/resource_bar.dart';
import 'package:novaml_app/shared/widgets/indicators/status_dot.dart';
import 'package:novaml_app/shared/widgets/layout/page_container.dart';

/// Tela de monitoramento de recursos do sistema — dados reais via WMI/PowerShell.
class MonitoringPage extends ConsumerWidget {
  const MonitoringPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInfo = ref.watch(systemInfoProvider);

    return asyncInfo.when(
      loading: () => _buildContent(context, SystemInfo.loading(),
          isLoading: true),
      error: (e, _) =>
          _buildContent(context, SystemInfo.loading(), isLoading: true),
      data: (info) => _buildContent(context, info),
    );
  }

  Widget _buildContent(BuildContext context, SystemInfo info,
      {bool isLoading = false}) {
    return PageContainer(
      title: 'Monitoramento',
      subtitle:
          'Recursos do sistema em tempo real · atualiza a cada 3 segundos.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status cards ─────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatusCard(
                  label: 'Backend Python',
                  status: const StatusDot(
                      status: BackendStatus.online, showLabel: false),
                  value: 'Online',
                  valueColor: AppColors.success,
                  icon: Icons.terminal_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.cardGap),
              Expanded(
                child: _StatusCard(
                  label: 'Modelo Ollama',
                  status: const StatusDot(
                      status: BackendStatus.offline, showLabel: false),
                  value: 'Offline',
                  valueColor: AppColors.error,
                  icon: Icons.smart_toy_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.cardGap),
              Expanded(
                child: _StatusCard(
                  label: 'Processos ativos',
                  status: null,
                  value: '0',
                  icon: Icons.bolt_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recursos de Hardware', style: AppTextStyles.h2),
              if (isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.accent,
                  ),
                )
              else
                Text(
                  'Atualizado agora',
                  style: AppTextStyles.caption,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Resource cards ────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // RAM
              Expanded(
                child: NovaCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.memory_rounded,
                              size: 16, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Text('Memória RAM', style: AppTextStyles.h3),
                          const Spacer(),
                          Text(
                            info.ramLabel,
                            style: AppTextStyles.labelMd.copyWith(
                              color: _ramColor(info.ramFraction),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ResourceBar(
                        label: 'Uso atual',
                        value: info.ramUsedGb,
                        maxValue: info.ramTotalGb,
                        unit: 'GB',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _PercentBadge(fraction: info.ramFraction),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.cardGap),

              // Disco
              Expanded(
                child: NovaCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storage_rounded,
                              size: 16, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Text('Armazenamento (C:)',
                              style: AppTextStyles.h3),
                          const Spacer(),
                          Text(
                            info.diskLabel,
                            style: AppTextStyles.labelMd.copyWith(
                              color: _diskColor(info.diskFraction),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ResourceBar(
                        label: 'Uso atual',
                        value: info.diskUsedGb,
                        maxValue: info.diskTotalGb,
                        unit: 'GB',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _PercentBadge(fraction: info.diskFraction),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.cardGap),

              // GPU
              Expanded(
                child: NovaCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.developer_board_rounded,
                              size: 16, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Text('GPU', style: AppTextStyles.h3),
                          const Spacer(),
                          if (!info.gpuAvailable)
                            Text('N/A',
                                style: AppTextStyles.labelMd
                                    .copyWith(color: AppColors.textDisabled)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (info.gpuAvailable)
                        ResourceBar(
                          label: 'Utilização',
                          value: info.gpuPercent.toDouble(),
                          maxValue: 100,
                          unit: '%',
                        )
                      else
                        Text(
                          'GPU não detectada ou sem suporte nvidia-smi.',
                          style: AppTextStyles.bodySm,
                        ),
                      const SizedBox(height: AppSpacing.md),
                      if (info.gpuAvailable)
                        _PercentBadge(
                            fraction: info.gpuPercent / 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _ramColor(double f) {
    if (f >= 0.9) return AppColors.error;
    if (f >= 0.75) return AppColors.warning;
    return AppColors.success;
  }

  static Color _diskColor(double f) {
    if (f >= 0.9) return AppColors.error;
    if (f >= 0.75) return AppColors.warning;
    return AppColors.accent;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PercentBadge extends StatelessWidget {
  const _PercentBadge({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final pct = (fraction * 100).round();
    final color = fraction >= 0.9
        ? AppColors.error
        : fraction >= 0.75
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$pct% em uso',
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.status,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final Widget? status;
  final String value;
  final Color? valueColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentSubtle,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 20, color: AppColors.accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelMd),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      value,
                      style: AppTextStyles.h3.copyWith(
                          color: valueColor ?? AppColors.textPrimary),
                    ),
                    if (status != null) ...[
                      const SizedBox(width: 6),
                      status!,
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
