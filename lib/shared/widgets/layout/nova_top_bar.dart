import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';
import 'package:novaml_app/shared/providers/navigation_provider.dart';

/// Top bar global do NOVAML.
/// Adapta os botões à direita conforme o fluxo ativo:
///   projects  → Search + NEW PROJECT
///   workspace → ← Back to Dashboard
///   training  → (sem ação — treino em andamento)
///   results   → ← BACK TO WORKSPACE
class NovaTopBar extends ConsumerWidget {
  const NovaTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(appFlowProvider);

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          const _BrandSection(),
          const Spacer(),
          switch (flow) {
            AppFlowState.projects => Row(children: [
                const _SearchBar(),
                const SizedBox(width: 16),
                _NewProjectButton(
                  onPressed: () => ref
                      .read(createProjectTriggerProvider.notifier)
                      .state++,
                ),
              ]),
            AppFlowState.workspace => _BackButton(
                label: 'Back to Dashboard',
                onPressed: () => ref
                    .read(appFlowProvider.notifier)
                    .state = AppFlowState.projects,
              ),
            AppFlowState.training => const SizedBox.shrink(),
            AppFlowState.results => _BackButton(
                label: 'BACK TO WORKSPACE',
                onPressed: () => ref
                    .read(appFlowProvider.notifier)
                    .state = AppFlowState.workspace,
              ),
          },
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _BrandSection extends StatelessWidget {
  const _BrandSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo grid icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderActive),
          ),
          child: const Icon(
            Icons.grid_view_rounded,
            size: 20,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NOVAML',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'NO-CODE VISUAL ASTRONOMICAL MACHINE LEARNING',
              style: AppTextStyles.caption.copyWith(
                letterSpacing: 0.6,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: ref.read(searchQueryProvider),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 38,
      child: TextField(
        controller: _ctrl,
        style: AppTextStyles.bodyMd,
        onChanged: (v) =>
            ref.read(searchQueryProvider.notifier).state = v,
        decoration: InputDecoration(
          hintText: 'Search projects...',
          hintStyle: AppTextStyles.bodyMd
              .copyWith(color: AppColors.textDisabled),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 18, color: AppColors.textDisabled),
          suffixIcon: ref.watch(searchQueryProvider).isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 14, color: AppColors.textDisabled),
                  onPressed: () {
                    _ctrl.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface2,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.accent, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NewProjectButton extends StatefulWidget {
  const _NewProjectButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_NewProjectButton> createState() => _NewProjectButtonState();
}

class _NewProjectButtonState extends State<_NewProjectButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.accent.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: AppColors.accent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(
                'NEW PROJECT',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _BackButton extends StatefulWidget {
  const _BackButton({required this.onPressed, this.label = 'Back to Dashboard'});

  final VoidCallback onPressed;
  final String label;

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.surface2
                : AppColors.surface2.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back_rounded,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
