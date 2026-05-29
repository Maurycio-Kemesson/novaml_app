import 'package:flutter/material.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';

/// Card base reutilizável do NOVAML.
/// Suporta hover state, border accent e padding customizável.
class NovaCard extends StatefulWidget {
  const NovaCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.selected = false,
    this.accentColor,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool selected;

  /// Se fornecido, mostra uma borda colorida à esquerda (indicador de tipo).
  final Color? accentColor;
  final double? width;
  final double? height;

  @override
  State<NovaCard> createState() => _NovaCardState();
}

class _NovaCardState extends State<NovaCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.selected
        ? AppColors.accent
        : _hovered
            ? AppColors.borderActive
            : AppColors.border;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _hovered && widget.onTap != null
                ? AppColors.surface2
                : AppColors.surface1,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: borderColor),
          ),
          // IntrinsicHeight resolve o caso em que o NovaCard está dentro
          // de um SingleChildScrollView (height = infinity): ele mede a
          // altura real do conteúdo antes de aplicar CrossAxisAlignment.stretch,
          // evitando "BoxConstraints forces an infinite height".
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: widget.accentColor != null
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(width: 3, color: widget.accentColor),
                        Expanded(
                          child: Padding(
                            padding: widget.padding ??
                                const EdgeInsets.all(AppSpacing.cardPadding),
                            child: widget.child,
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: widget.padding ??
                        const EdgeInsets.all(AppSpacing.cardPadding),
                    child: widget.child,
                  ),
          ),
        ),
      ),
    );
  }
}
