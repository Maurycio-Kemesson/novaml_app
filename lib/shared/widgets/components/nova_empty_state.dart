import 'package:flutter/material.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';
import 'nova_button.dart';

/// Estado vazio padrão para listas e seções sem dados.
class NovaEmptyState extends StatelessWidget {
  const NovaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accentSubtle,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Icon(icon, size: 32, color: AppColors.accent),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title,
                style: AppTextStyles.h2,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              NovaButton(
                label: actionLabel!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
