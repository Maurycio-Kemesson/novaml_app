import 'package:flutter/material.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';

/// Container padrão para o conteúdo de cada page.
///
/// - [scrollable] = true  → SingleChildScrollView (padrão — conteúdo longo)
/// - [scrollable] = false → Column que expande para preencher o espaço
///   disponível, com o [child] dentro de um [Expanded] para receber
///   constraints tight (necessário quando o filho usa Expanded/Flexible).
class PageContainer extends StatelessWidget {
  const PageContainer({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.headerActions,
    this.scrollable = true,
    this.padding,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final List<Widget>? headerActions;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontalPadding,
          vertical: AppSpacing.pageVerticalPadding,
        );

    final titleSection = title != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title!, style: AppTextStyles.displayMd),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: AppTextStyles.bodyMd
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (headerActions != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    Row(
                      children: headerActions!
                          .expand((w) => [w, const SizedBox(width: 8)])
                          .toList()
                        ..removeLast(),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          )
        : null;

    if (scrollable) {
      return SingleChildScrollView(
        child: Padding(
          padding: effectivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (titleSection != null) titleSection,
              child,
            ],
          ),
        ),
      );
    }

    // scrollable = false: preenche todo o espaço disponível.
    // O child fica em Expanded para receber constraints tight,
    // permitindo que filhos com Expanded/Flexible funcionem corretamente.
    return Padding(
      padding: effectivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titleSection != null) titleSection,
          Expanded(child: child),
        ],
      ),
    );
  }
}
