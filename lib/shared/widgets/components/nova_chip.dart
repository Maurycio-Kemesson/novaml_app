import 'package:flutter/material.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';

enum NovaChipType { star, galaxy, quasar, info, success, warning, error, neutral }

/// Chip semântico para classificações astronômicas e status.
class NovaChip extends StatelessWidget {
  const NovaChip({
    super.key,
    required this.label,
    required this.type,
    this.small = false,
  });

  final String label;
  final NovaChipType type;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(type);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: (small ? AppTextStyles.caption : AppTextStyles.labelSm)
            .copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }

  (Color bg, Color fg) _colors(NovaChipType t) => switch (t) {
        NovaChipType.star => (AppColors.starSubtle, AppColors.star),
        NovaChipType.galaxy => (AppColors.galaxySubtle, AppColors.galaxy),
        NovaChipType.quasar => (AppColors.quasarSubtle, AppColors.quasar),
        NovaChipType.info => (AppColors.infoSubtle, AppColors.info),
        NovaChipType.success => (AppColors.successSubtle, AppColors.success),
        NovaChipType.warning => (AppColors.warningSubtle, AppColors.warning),
        NovaChipType.error => (AppColors.errorSubtle, AppColors.error),
        NovaChipType.neutral => (AppColors.surface2, AppColors.textSecondary),
      };
}
