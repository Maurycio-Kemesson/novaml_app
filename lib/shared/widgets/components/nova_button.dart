import 'package:flutter/material.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';

enum NovaButtonVariant { primary, secondary, ghost, danger, success }

/// Botão unificado do NOVAML com variantes semânticas.
class NovaButton extends StatelessWidget {
  const NovaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = NovaButtonVariant.primary,
    this.leading,
    this.trailing,
    this.loading = false,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final NovaButtonVariant variant;
  final Widget? leading;
  final Widget? trailing;
  final bool loading;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(variant);

    final child = loading
        ? SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: style.foreground,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                IconTheme(
                  data: IconThemeData(color: style.foreground, size: 16),
                  child: leading!,
                ),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: AppTextStyles.bodyMd.copyWith(
                      color: style.foreground,
                      fontWeight: FontWeight.w600)),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                IconTheme(
                  data: IconThemeData(color: style.foreground, size: 16),
                  child: trailing!,
                ),
              ],
            ],
          );

    return AnimatedOpacity(
      opacity: onPressed == null && !loading ? 0.4 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Material(
        color: style.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: style.border != null
                  ? Border.all(color: style.border!)
                  : null,
            ),
            padding: dense
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 7)
                : const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            child: child,
          ),
        ),
      ),
    );
  }

  _ButtonStyle _styleFor(NovaButtonVariant v) => switch (v) {
        NovaButtonVariant.primary => _ButtonStyle(
            background: AppColors.accent,
            foreground: AppColors.textOnAccent,
          ),
        NovaButtonVariant.secondary => _ButtonStyle(
            background: AppColors.surface2,
            foreground: AppColors.textPrimary,
            border: AppColors.border,
          ),
        NovaButtonVariant.ghost => _ButtonStyle(
            background: Colors.transparent,
            foreground: AppColors.textSecondary,
          ),
        NovaButtonVariant.danger => _ButtonStyle(
            background: AppColors.errorSubtle,
            foreground: AppColors.error,
            border: AppColors.error.withOpacity(0.3),
          ),
        NovaButtonVariant.success => _ButtonStyle(
            background: AppColors.successSubtle,
            foreground: AppColors.success,
            border: AppColors.success.withOpacity(0.3),
          ),
      };
}

class _ButtonStyle {
  final Color background;
  final Color foreground;
  final Color? border;

  const _ButtonStyle({
    required this.background,
    required this.foreground,
    this.border,
  });
}
