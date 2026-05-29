import 'package:flutter/material.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';

enum BackendStatus { online, starting, offline }

extension BackendStatusX on BackendStatus {
  String get label => switch (this) {
        BackendStatus.online => 'Backend online',
        BackendStatus.starting => 'Iniciando...',
        BackendStatus.offline => 'Backend offline',
      };

  Color get color => switch (this) {
        BackendStatus.online => AppColors.success,
        BackendStatus.starting => AppColors.warning,
        BackendStatus.offline => AppColors.error,
      };
}

/// Indicador visual do status de conexão com o backend Python.
class StatusDot extends StatelessWidget {
  const StatusDot({
    super.key,
    required this.status,
    this.showLabel = true,
  });

  final BackendStatus status;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: status.label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AnimatedDot(color: status.color, pulsing: status == BackendStatus.starting),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(status.label, style: AppTextStyles.labelSm),
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
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.pulsing) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_AnimatedDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulsing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulsing && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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
              BoxShadow(color: widget.color.withOpacity(0.5), blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}
