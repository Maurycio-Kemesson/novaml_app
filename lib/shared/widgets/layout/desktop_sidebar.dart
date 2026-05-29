import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';
import 'package:novaml_app/shared/providers/navigation_provider.dart';
import 'package:novaml_app/shared/widgets/indicators/resource_bar.dart';

/// Sidebar de navegação principal — colapsável, com dois grupos de itens.
class DesktopSidebar extends ConsumerWidget {
  const DesktopSidebar({super.key});

  static const _workspaceSections = [
    NavSection.projects,
    NavSection.upload,
    NavSection.training,
    NavSection.models,
    NavSection.dashboard,
  ];

  static const _systemSections = [
    NavSection.assistant,
    NavSection.monitoring,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(navigationProvider);
    final collapsed = ref.watch(sidebarCollapsedProvider);
    final width = collapsed
        ? AppSpacing.sidebarWidthCollapsed
        : AppSpacing.sidebarWidthExpanded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo / branding
          _SidebarHeader(collapsed: collapsed),

          const Divider(height: 1, color: AppColors.border),

          // Workspace items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!collapsed)
                    _GroupLabel(label: 'Workspace'),
                  ..._workspaceSections.map(
                    (s) => _SidebarItem(
                      section: s,
                      isActive: current == s,
                      collapsed: collapsed,
                      onTap: () =>
                          ref.read(navigationProvider.notifier).state = s,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (!collapsed)
                    _GroupLabel(label: 'Sistema'),
                  ..._systemSections.map(
                    (s) => _SidebarItem(
                      section: s,
                      isActive: current == s,
                      collapsed: collapsed,
                      onTap: () =>
                          ref.read(navigationProvider.notifier).state = s,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Resource mini-view (só quando expandida)
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: const [
                  ResourceBar(
                      label: 'RAM',
                      value: 3.2,
                      maxValue: 16,
                      unit: 'GB'),
                  SizedBox(height: AppSpacing.sm),
                  ResourceBar(
                      label: 'Disco',
                      value: 45,
                      maxValue: 256,
                      unit: 'GB'),
                ],
              ),
            ),

          // Collapse toggle
          _CollapseButton(collapsed: collapsed, onToggle: () {
            ref.read(sidebarCollapsedProvider.notifier).state = !collapsed;
          }),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.topBarHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: collapsed ? 0 : AppSpacing.md,
        ),
        child: Row(
          mainAxisAlignment:
              collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            // Logo placeholder
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.galaxy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.auto_awesome,
                  size: 16, color: Colors.white),
            ),
            if (!collapsed) ...[
              const SizedBox(width: AppSpacing.sm),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NOVAML',
                      style: AppTextStyles.h3
                          .copyWith(color: AppColors.textPrimary)),
                  Text('v1.0.0',
                      style: AppTextStyles.caption),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelSm.copyWith(
          letterSpacing: 0.8,
          color: AppColors.textDisabled,
        ),
      ),
    );
  }
}

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

  // Mapa de ícones por seção
  static const _icons = <NavSection, IconData>{
    NavSection.projects: Icons.folder_outlined,
    NavSection.upload: Icons.upload_file_outlined,
    NavSection.training: Icons.memory_outlined,
    NavSection.models: Icons.layers_outlined,
    NavSection.dashboard: Icons.bar_chart_outlined,
    NavSection.assistant: Icons.smart_toy_outlined,
    NavSection.monitoring: Icons.monitor_heart_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _icons[widget.section] ?? Icons.circle_outlined;
    final bg = widget.isActive
        ? AppColors.sidebarItemActive
        : _hovered
            ? AppColors.sidebarItemHover
            : Colors.transparent;

    final labelStyle = widget.isActive
        ? AppTextStyles.sidebarItemActive
        : AppTextStyles.sidebarItem;

    final iconColor = widget.isActive ? AppColors.accent : AppColors.textSecondary;

    return Tooltip(
      message: widget.collapsed ? widget.section.label : '',
      preferBelow: false,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 1),
            padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 0 : AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              mainAxisAlignment: widget.collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                // Active indicator
                if (widget.isActive && !widget.collapsed)
                  Container(
                    width: 2,
                    height: 14,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                Icon(icon, size: 18, color: iconColor),
                if (!widget.collapsed) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(widget.section.label, style: labelStyle),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CollapseButton extends StatelessWidget {
  const _CollapseButton(
      {required this.collapsed, required this.onToggle});

  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Container(
        height: 44,
        padding: EdgeInsets.symmetric(
          horizontal:
              collapsed ? 0 : AppSpacing.md,
        ),
        alignment:
            collapsed ? Alignment.center : Alignment.centerRight,
        child: Icon(
          collapsed
              ? Icons.chevron_right_rounded
              : Icons.chevron_left_rounded,
          size: 20,
          color: AppColors.textDisabled,
        ),
      ),
    );
  }
}
