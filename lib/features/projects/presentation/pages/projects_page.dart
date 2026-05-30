import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';
import 'package:novaml_app/features/projects/domain/models/project_model.dart';
import 'package:novaml_app/features/projects/presentation/widgets/project_dialog.dart';
import 'package:novaml_app/shared/providers/navigation_provider.dart';
import 'package:novaml_app/shared/providers/projects_provider.dart';

// ─── Page ─────────────────────────────────────────────────────────────────────

class ProjectsPage extends ConsumerStatefulWidget {
  const ProjectsPage({super.key});

  @override
  ConsumerState<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends ConsumerState<ProjectsPage> {
  @override
  void initState() {
    super.initState();
    // Escuta o trigger do botão "NEW PROJECT" no header global
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(createProjectTriggerProvider, (prev, next) {
        if (prev != null && next > prev && mounted) _createProject();
      });
    });
  }

  // ── Ações ──────────────────────────────────────────────────────────────

  Future<void> _createProject() async {
    final result = await ProjectDialog.show(context);
    if (result == null) return;
    final project = await ref.read(projectsProvider.notifier).create(
          name:        result.name,
          description: result.description,
          algorithm:   result.algorithm,
        );
    if (mounted) {
      _showSnack('Projeto "${result.name}" criado.');
      // Abre automaticamente o workspace com o projeto recém-criado
      _openProject(project);
    }
  }

  Future<void> _editProject(Project project) async {
    final result = await ProjectDialog.show(context, project: project);
    if (result == null) return;
    await ref.read(projectsProvider.notifier).save(
          project.copyWith(
            name:        result.name,
            description: result.description,
            algorithm:   result.algorithm,
          ),
        );
    if (mounted) _showSnack('Projeto atualizado.');
  }

  Future<void> _deleteProject(Project project) async {
    final confirmed = await _confirmDelete(project.name);
    if (!confirmed) return;
    await ref.read(projectsProvider.notifier).delete(project.id!);
    if (mounted) _showSnack('Projeto excluído.');
  }

  void _openProject(Project project) {
    ref.read(selectedProjectProvider.notifier).state = project;
    ref.read(appFlowProvider.notifier).state = AppFlowState.workspace;
  }

  Future<bool> _confirmDelete(String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => _DeleteConfirmDialog(projectName: name),
        ) ??
        false;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final asyncProjects = ref.watch(projectsProvider);

    return asyncProjects.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (e, _) => Center(
        child: Text('Erro ao carregar projetos: $e',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.error)),
      ),
      data: (all) {
        final query   = ref.watch(searchQueryProvider);
        final projects = query.isEmpty
            ? all
            : ref.read(projectsProvider.notifier).filter(query);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stats ────────────────────────────────────────────────────
              _StatsRow(projects: all),
              const SizedBox(height: 24),

              // ── Título ───────────────────────────────────────────────────
              Row(
                children: [
                  Text('Project Directory', style: AppTextStyles.h1),
                  if (query.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Text(
                      '${projects.length} resultado${projects.length != 1 ? "s" : ""}',
                      style: AppTextStyles.bodySm,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // ── Tabela ───────────────────────────────────────────────────
              if (projects.isEmpty)
                _EmptyState(
                  isFiltered: query.isNotEmpty,
                  onCreate: _createProject,
                )
              else
                _ProjectTable(
                  projects: projects,
                  onOpen:   _openProject,
                  onEdit:   _editProject,
                  onDelete: _deleteProject,
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.projects});

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    final total     = projects.length;
    final active    = projects.where((p) => p.status == ProjectStatus.active).length;
    final training  = projects.where((p) => p.status == ProjectStatus.training).length;
    final completed = projects.where((p) => p.status == ProjectStatus.completed).length;

    return Row(
      children: [
        _StatChip(label: 'Total',      value: total,     color: AppColors.textSecondary),
        const SizedBox(width: 10),
        _StatChip(label: 'Active',     value: active,    color: AppColors.success),
        const SizedBox(width: 10),
        _StatChip(label: 'Training',   value: training,  color: AppColors.accent),
        const SizedBox(width: 10),
        _StatChip(label: 'Completed',  value: completed, color: AppColors.galaxy),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            '$label: $value',
            style: AppTextStyles.labelSm
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Project Table ────────────────────────────────────────────────────────────

class _ProjectTable extends StatelessWidget {
  const _ProjectTable({
    required this.projects,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Project> projects;
  final void Function(Project) onOpen;
  final void Function(Project) onEdit;
  final void Function(Project) onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _TableHeader(),
          const Divider(height: 1, color: AppColors.border),
          ...projects.asMap().entries.map((e) {
            final isLast = e.key == projects.length - 1;
            return Column(
              children: [
                _ProjectRow(
                  project:  e.value,
                  onOpen:   () => onOpen(e.value),
                  onEdit:   () => onEdit(e.value),
                  onDelete: () => onDelete(e.value),
                ),
                if (!isLast)
                  const Divider(height: 1, color: AppColors.border, indent: 56),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─── Table Header ─────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Row(
        children: const [
          SizedBox(width: 36),
          Expanded(flex: 3, child: _HeaderCell('PROJECT NAME')),
          Expanded(flex: 3, child: _HeaderCell('ALGORITHM')),
          Expanded(flex: 2, child: _HeaderCell('STORAGE')),
          Expanded(flex: 2, child: _HeaderCell('CREATED')),
          Expanded(flex: 2, child: _HeaderCell('STATUS')),
          SizedBox(width: 108, child: _HeaderCell('ACTIONS', right: true)),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {this.right = false});

  final String label;
  final bool right;

  @override
  Widget build(BuildContext context) => Text(
        label,
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: AppTextStyles.labelSm.copyWith(
          letterSpacing: 0.8,
          color: AppColors.textDisabled,
          fontWeight: FontWeight.w600,
        ),
      );
}

// ─── Project Row ──────────────────────────────────────────────────────────────

class _ProjectRow extends StatefulWidget {
  const _ProjectRow({
    required this.project,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final Project project;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_ProjectRow> createState() => _ProjectRowState();
}

class _ProjectRowState extends State<_ProjectRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final dateStr = DateFormat('dd/MM/yyyy').format(p.createdAt);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onDoubleTap: widget.onOpen,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _hovered
              ? AppColors.surface2.withOpacity(0.6)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            children: [
              // Folder icon
              Icon(Icons.folder_outlined, size: 20, color: AppColors.accent),
              const SizedBox(width: 16),

              // Name + description
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (p.description != null && p.description!.isNotEmpty)
                      Text(
                        p.description!,
                        style: AppTextStyles.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Algorithm
              Expanded(
                flex: 3,
                child: Text(
                  p.algorithm.label,
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Storage
              Expanded(
                flex: 2,
                child: Text(
                  p.storageMb > 0 ? p.storageLabel : '—',
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),

              // Created at
              Expanded(
                flex: 2,
                child: Text(
                  dateStr,
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),

              // Status
              Expanded(flex: 2, child: _StatusBadge(p.status)),

              // Actions — sempre visíveis, destaque no hover
              SizedBox(
                width: 108,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _RowAction(
                      icon: Icons.open_in_new_rounded,
                      tooltip: 'Abrir projeto',
                      onTap: widget.onOpen,
                      hovered: _hovered,
                    ),
                    _RowAction(
                      icon: Icons.edit_outlined,
                      tooltip: 'Editar',
                      onTap: widget.onEdit,
                      hovered: _hovered,
                    ),
                    _RowAction(
                      icon: Icons.delete_outline_rounded,
                      tooltip: 'Excluir',
                      onTap: widget.onDelete,
                      danger: true,
                      hovered: _hovered,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatefulWidget {
  const _StatusBadge(this.status);
  final ProjectStatus status;

  @override
  State<_StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<_StatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _opacity = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.status == ProjectStatus.training) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.status.color;
    final isTraining = widget.status == ProjectStatus.training;

    if (isTraining) {
      return AnimatedBuilder(
        animation: _opacity,
        builder: (_, __) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: _opacity.value,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.5), blurRadius: 4)
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              widget.status.label,
              style: AppTextStyles.labelSm
                  .copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        widget.status.label,
        style: AppTextStyles.labelSm
            .copyWith(color: color, letterSpacing: 0.4),
      ),
    );
  }
}

// ─── Row Action ───────────────────────────────────────────────────────────────

class _RowAction extends StatefulWidget {
  const _RowAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.danger = false,
    this.hovered = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool danger;
  final bool hovered; // passa o hover da linha pai

  @override
  State<_RowAction> createState() => _RowActionState();
}

class _RowActionState extends State<_RowAction> {
  bool _selfHovered = false;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.danger ? AppColors.error : AppColors.textSecondary;
    // Dim quando a linha não está hovered, bright quando hovered ou self-hovered
    final opacity = widget.hovered || _selfHovered ? 1.0 : 0.25;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _selfHovered = true),
        onExit: (_) => setState(() => _selfHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _selfHovered
                  ? (widget.danger
                      ? AppColors.errorSubtle
                      : AppColors.surface2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: AnimatedOpacity(
              opacity: opacity,
              duration: const Duration(milliseconds: 150),
              child: Icon(widget.icon, size: 16, color: baseColor),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isFiltered,
    required this.onCreate,
  });

  final bool isFiltered;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.accentSubtle,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              isFiltered
                  ? Icons.search_off_rounded
                  : Icons.folder_open_outlined,
              size: 28,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isFiltered ? 'Nenhum projeto encontrado' : 'Nenhum projeto ainda',
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Tente um termo diferente na busca.'
                : 'Crie seu primeiro projeto para começar a analisar dados astronômicos.',
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (!isFiltered) ...[
            const SizedBox(height: 24),
            _PrimaryButton(
              label: 'NEW PROJECT',
              icon: Icons.add_rounded,
              onTap: onCreate,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Delete Confirm Dialog ────────────────────────────────────────────────────

class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog({required this.projectName});

  final String projectName;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.errorSubtle,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.error),
                  ),
                  const SizedBox(width: 12),
                  Text('Excluir Projeto', style: AppTextStyles.h2),
                ],
              ),
              const SizedBox(height: 20),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.textSecondary),
                  children: [
                    const TextSpan(text: 'Tem certeza que deseja excluir '),
                    TextSpan(
                      text: '"$projectName"',
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(
                        text: '? Esta ação não pode ser desfeita.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Excluir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Primary Button ───────────────────────────────────────────────────────────

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
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
              Icon(widget.icon, size: 16, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(
                widget.label,
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
