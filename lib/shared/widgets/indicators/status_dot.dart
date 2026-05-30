import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';
import 'package:novaml_app/shared/providers/backend_provider.dart';

// Mantido para compatibilidade com MonitoringPage
enum BackendStatus { online, starting, offline }

/// StatusDot que consome o [backendStatusProvider] real.
class StatusDot extends ConsumerWidget {
  const StatusDot({
    super.key,
    this.showLabel = true,
    // Ignorado — usa o provider automaticamente
    this.status,
  });

  final bool showLabel;
  // Permite override manual (ex: MonitoringPage mostra Ollama como offline)
  final BackendStatus? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (status != null) {
      return _DotView(status: status!, showLabel: showLabel);
    }
    final async = ref.watch(backendStatusProvider);
    final mapped = async.when(
      loading: () => BackendStatus.starting,
      error: (_, __) => BackendStatus.offline,
      data: (s) => switch (s) {
        BackendOnlineStatus.online   => BackendStatus.online,
        BackendOnlineStatus.starting => BackendStatus.starting,
        BackendOnlineStatus.offline  => BackendStatus.offline,
      },
    );
    return _DotView(status: mapped, showLabel: showLabel);
  }
}

class _DotView extends StatelessWidget {
  const _DotView({required this.status, required this.showLabel});

  final BackendStatus status;
  final bool showLabel;

  String get _label => switch (status) {
        BackendStatus.online   => 'Backend online',
        BackendStatus.starting => 'Iniciando...',
        BackendStatus.offline  => 'Backend offline',
      };

  Color get _color => switch (status) {
        BackendStatus.online   => AppColors.success,
        BackendStatus.starting => AppColors.warning,
        BackendStatus.offline  => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AnimatedDot(
            color: _color,
            pulsing: status == BackendStatus.starting,
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(_label, style: AppTextStyles.labelSm),
          ],
        ],
      ),
    );
  }
}

class _AnimatedDot extends StatefulWidget {
  const _AnimatedDot({required this.color, required this.pulsing});

  final Color color;
  final bool pulsing;

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.pulsing) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_AnimatedDot old) {
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
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(
        opacity: widget.pulsing ? _opacity.value : 1.0,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: widget.color.withOpacity(0.5), blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}
