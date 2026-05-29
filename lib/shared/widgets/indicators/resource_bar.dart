import 'package:flutter/material.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';

/// Barra de progresso para monitoramento de recursos (RAM, Disco).
/// Muda de cor automaticamente conforme o threshold de alerta.
class ResourceBar extends StatelessWidget {
  const ResourceBar({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.unit,
    this.warningThreshold = 0.75,
    this.criticalThreshold = 0.90,
  });

  final String label;
  final double value;
  final double maxValue;
  final String unit;
  final double warningThreshold;
  final double criticalThreshold;

  double get _percentage => (value / maxValue).clamp(0.0, 1.0);

  Color get _barColor {
    if (_percentage >= criticalThreshold) return AppColors.error;
    if (_percentage >= warningThreshold) return AppColors.warning;
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    final valueStr =
        '${value.toStringAsFixed(1)} / ${maxValue.toStringAsFixed(0)} $unit';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.labelSm),
            Text(valueStr, style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _percentage,
            backgroundColor: AppColors.surface2,
            valueColor: AlwaysStoppedAnimation(_barColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
