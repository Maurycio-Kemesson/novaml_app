import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';
import 'package:novaml_app/shared/providers/navigation_provider.dart';

/// Sidebar de navegação lateral do NOVAML.
///
/// Alterna entre modo expandido (label + ícone) e colapsado (só ícone)
/// via [sidebarCollapsedProvider].
///
/// Mapeamento 1:1 com NavSection.values / IndexedStack do AppShell.
class NovaSidebar extends ConsumerWidget {
  const NovaSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapsed = ref.watch(sidebarCollapsedProvider);
    final current = ref.watch(navigationProvider);

    final width = collapsed
        ? AppSpacing.sidebarWidthCollapsed
        : AppSpacing.sidebarWidthExpanded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // ── Itens de navegação ─────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: NavSection.values
                  .map((s) => _SidebarItem(
                        section: s,
                        isActive: s == current,
                        collapsed: collapsed,
                        onTap: () => ref
                            .read(navigationProvider.notifier)
                            .state = s,
                      ))
                  .toList(),
            ),
          ),

          // ── Botão de colapso ───────────────────────────────────────────
          const Divider(color: AppColors.border, height: 1),
          _CollapseButton(
            collapsed: collapsed,
            onTap: () => ref
                .read(sidebarCollapsedProvider.notifier)
                .state = !collapsed,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item individual
// ─────────────────────────────────────────────────────────────────────────────

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.section,
    required this.isActive,
    required this.collapsed,
    required this.onTap,
  });

  final NavSection section;
  final bool isActive;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isActive
        ? AppColors.sidebarItemActive
        : _hovered
            ? AppColors.sidebarItemHover
            : Colors.transparent;

    final iconColor = widget.isActive ? AppColors.accent : AppColors.textSecondary;
    final textStyle = widget.isActive
        ? AppTextStyles.sidebarItemActive
        : AppTextStyles.sidebarItem;

    final icon = _iconFor(widget.section);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.collapsed ? widget.section.label : '',
        preferBelow: false,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs, vertical: 2),
            padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 0 : AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: widget.isActive
                  ? Border(
                      left: BorderSide(
                          color: AppColors.accent, width: 2))
                  : null,
            ),
            child: widget.collapsed
                ? Center(child: Icon(icon, size: 20, color: iconColor))
                : Row(
                    children: [
                      Icon(icon, size: 18, color: iconColor),
                      const SizedBox(width: AppSpacing.sm + 2),
                      Text(widget.section.label, style: textStyle),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(NavSection section) => switch (section) {
        NavSection.projects   => Icons.folder_rounded,
        NavSection.models     => Icons.layers_rounded,
        NavSection.dashboard  => Icons.bar_chart_rounded,
        NavSection.monitoring => Icons.memory_rounded,
        NavSection.assistant  => Icons.auto_awesome_rounded,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Botão de colapso
// ─────────────────────────────────────────────────────────────────────────────

class _CollapseButton extends StatefulWidget {
  const _CollapseButton({required this.collapsed, required this.onTap});
  final bool collapsed;
  final VoidCallback onTap;

  @override
  State<_CollapseButton> createState() => _CollapseButtonState();
}

class _CollapseButtonState extends State<_CollapseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          color: _hovered ? AppColors.sidebarItemHover : Colors.transparent,
          child: Row(
            mainAxisAlignment: widget.collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.end,
            children: [
              Icon(
                widget.collapsed
                    ? Icons.chevron_right_rounded
                    : Icons.chevron_left_rounded,
                size: 18,
                color: AppColors.textDisabled,
              ),
              if (!widget.collapsed) ...[
                const SizedBox(width: AppSpacing.sm),
                Text('Recolher',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textDisabled)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
