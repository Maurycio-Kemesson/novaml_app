import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novaml_app/core/services/system_info_service.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';
import 'package:novaml_app/shared/providers/system_info_provider.dart';

/// Barra de status com dados reais de RAM, Disco e GPU do Windows.
/// Consumida tanto pelo bottom bar do Workspace quanto pela MonitoringPage.
class SystemStatusBar extends ConsumerWidget {
  const SystemStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInfo = ref.watch(systemInfoProvider);

    return asyncInfo.when(
      loading: () => _buildDots(SystemInfo.loading(), loading: true),
      error: (_, __) => _buildDots(SystemInfo.loading(), error: true),
      data: (info) => _buildDots(info),
    );
  }

  Widget _buildDots(SystemInfo info,
      {bool loading = false, bool error = false}) {
    final ramColor = _thresholdColor(info.ramFraction);
    final diskColor = _thresholdColor(info.diskFraction);
    final gpuColor = info.gpuPercent > 80
        ? AppColors.error
        : info.gpuPercent > 50
            ? AppColors.warning
            : AppColors.textDisabled;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(
          color: loading ? AppColors.textDisabled : ramColor,
          label: loading ? 'RAM: ...' : 'RAM: ${info.ramLabel}',
          pulsing: loading,
        ),
        const SizedBox(width: 20),
        _Dot(
          color: loading ? AppColors.textDisabled : AppColors.accent,
          label: loading ? 'STORAGE: ...' : 'STORAGE: ${info.diskLabel}',
          pulsing: loading,
        ),
        const SizedBox(width: 20),
        _Dot(
          color: loading ? AppColors.textDisabled : gpuColor,
          label: loading ? 'GPU: ...' : info.gpuLabel,
          pulsing: loading,
        ),
      ],
    );
  }

  Color _thresholdColor(double fraction) {
    if (fraction >= 0.9) return AppColors.error;
    if (fraction >= 0.75) return AppColors.warning;
    return AppColors.success;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Dot extends StatefulWidget {
  const _Dot({
    required this.color,
    required this.label,
    this.pulsing = false,
  });

  final Color color;
  final String label;
  final bool pulsing;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.pulsing) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Dot old) {
    super.didUpdateWidget(old);
    if (widget.pulsing && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.pulsing && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _opacity,
          builder: (_, __) => Opacity(
            opacity: widget.pulsing ? _opacity.value : 1.0,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            widget.label,
            key: ValueKey(widget.label),
            style: AppTextStyles.labelSm
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
