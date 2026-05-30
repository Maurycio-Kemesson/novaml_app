import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novaml_app/core/services/system_info_service.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';
import 'package:novaml_app/core/services/backend_launcher.dart';
import 'package:novaml_app/shared/providers/backend_provider.dart';
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
                child: _BackendStatusCard(),
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

          // ── Backend logs ─────────────────────────────────────────────────
          const _BackendLogsPanel(),
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
                          Text(
                            info.gpuAvailable ? '${info.gpuPercent}%' : 'N/D',
                            style: AppTextStyles.labelMd.copyWith(
                              color: info.gpuAvailable
                                  ? _gpuColor(info.gpuPercent / 100)
                                  : AppColors.textDisabled,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (info.gpuAvailable) ...[
                        ResourceBar(
                          label: 'Utilizacao 3D',
                          value: info.gpuPercent.toDouble(),
                          maxValue: 100,
                          unit: '%',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _PercentBadge(fraction: info.gpuPercent / 100),
                      ] else
                        Text(
                          'GPU nao detectada.\n'
                          'Requer NVIDIA (nvidia-smi) ou\n'
                          'Windows 10/11 com GPU Engine counters.',
                          style: AppTextStyles.bodySm,
                        ),
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

  static Color _gpuColor(double f) {
    if (f >= 0.9) return AppColors.error;
    if (f >= 0.6) return AppColors.warning;
    return AppColors.success;
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

/// Card de status do backend Python com botão de restart.
class _BackendStatusCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BackendStatusCard> createState() => _BackendStatusCardState();
}

class _BackendStatusCardState extends ConsumerState<_BackendStatusCard> {
  bool _restarting = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(backendStatusProvider);
    final status = async.when(
      loading: () => BackendOnlineStatus.starting,
      error: (_, __) => BackendOnlineStatus.offline,
      data: (s) => s,
    );

    final (label, color) = switch (status) {
      BackendOnlineStatus.online   => ('Online',    AppColors.success),
      BackendOnlineStatus.starting => ('Iniciando', AppColors.warning),
      BackendOnlineStatus.offline  => ('Offline',   AppColors.error),
    };

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
            child: const Icon(Icons.terminal_rounded,
                size: 20, color: AppColors.accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Backend Python', style: AppTextStyles.labelMd),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(label,
                        style: AppTextStyles.h3.copyWith(color: color)),
                    const SizedBox(width: 6),
                    StatusDot(showLabel: false),
                  ],
                ),
              ],
            ),
          ),
          // Botão restart
          IconButton(
            tooltip: _restarting ? 'Reiniciando...' : 'Reiniciar backend',
            icon: _restarting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.accent),
                  )
                : const Icon(Icons.restart_alt_rounded,
                    size: 18, color: AppColors.accent),
            onPressed: _restarting
                ? null
                : () async {
                    setState(() => _restarting = true);
                    await BackendLauncher.instance.restart();
                    if (mounted) setState(() => _restarting = false);
                  },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Backend Logs Panel
// ─────────────────────────────────────────────────────────────────────────────

class _BackendLogsPanel extends ConsumerStatefulWidget {
  const _BackendLogsPanel();

  @override
  ConsumerState<_BackendLogsPanel> createState() => _BackendLogsPanelState();
}

class _BackendLogsPanelState extends ConsumerState<_BackendLogsPanel> {
  bool _expanded = false;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(backendLogsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text('Logs do Backend Python', style: AppTextStyles.h3),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentSubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${logs.length}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.accent)),
                  ),
                  const Spacer(),
                  if (_expanded)
                    TextButton.icon(
                      onPressed: () =>
                          ref.read(backendLogsProvider.notifier).clear(),
                      icon: const Icon(Icons.clear_all_rounded, size: 14),
                      label: const Text('Limpar'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textDisabled,
                        textStyle: AppTextStyles.caption,
                      ),
                    ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          // Log terminal expansível
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expanded
                ? Container(
                    height: 240,
                    decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(color: AppColors.border)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: logs.isEmpty
                        ? Center(
                            child: Text('Nenhum log ainda.',
                                style: AppTextStyles.caption))
                        : Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: logs.length,
                              reverse: true,
                              itemBuilder: (_, i) {
                                final log =
                                    logs[logs.length - 1 - i];
                                final isErr = log.contains('ERRO') ||
                                    log.contains('[ERR]');
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Text(
                                    log,
                                    style: AppTextStyles.code.copyWith(
                                      fontSize: 11,
                                      color: isErr
                                          ? AppColors.error
                                          : log.contains('✓')
                                              ? AppColors.success
                                              : AppColors.textSecondary,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

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
