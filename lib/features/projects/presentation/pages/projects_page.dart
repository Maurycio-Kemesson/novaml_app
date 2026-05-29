import 'package:flutter/material.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

enum ProjectStatus { active, queued, training, completed, error }

extension ProjectStatusX on ProjectStatus {
  String get label => switch (this) {
        ProjectStatus.active => 'ACTIVE',
        ProjectStatus.queued => 'QUEUED',
        ProjectStatus.training => 'TRAINING...',
        ProjectStatus.completed => 'COMPLETED',
        ProjectStatus.error => 'ERROR',
      };
}

class ProjectItem {
  final String name;
  final String configuration;
  final String storage;
  final ProjectStatus status;

  const ProjectItem({
    required this.name,
    required this.configuration,
    required this.storage,
    required this.status,
  });
}

// ─── Mock data ────────────────────────────────────────────────────────────────

const _mockProjects = [
  ProjectItem(
    name: 'Nebula Seg-X Alpha',
    configuration: 'Model: CNN-3D, Lr: 0.001',
    storage: '4.5 GB',
    status: ProjectStatus.active,
  ),
  ProjectItem(
    name: 'Quasar Spectral Net',
    configuration: 'Model: Transformer, Batch: 64',
    storage: '1.2 GB',
    status: ProjectStatus.queued,
  ),
  ProjectItem(
    name: 'Deep Field Classifier',
    configuration: 'Model: ResNet-50, Lr: 0.005',
    storage: '8.4 GB',
    status: ProjectStatus.training,
  ),
];

// ─── Page ─────────────────────────────────────────────────────────────────────

/// Tela inicial — Project Directory fiel ao protótipo Stitch.
class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final List<ProjectItem> _projects = List.of(_mockProjects);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho ──────────────────────────────────────────────────────
          Row(
            children: [
              Text('Project Directory', style: AppTextStyles.h1),
              const SizedBox(width: 20),
              const _VerticalDivider(),
              const SizedBox(width: 20),
              _FilterButton(onTap: () {}),
            ],
          ),

          const SizedBox(height: 24),

          // ── Tabela ─────────────────────────────────────────────────────────
          _ProjectTable(
            projects: _projects,
            onDelete: (p) => setState(() => _projects.remove(p)),
          ),
        ],
      ),
    );
  }
}

// ─── Table ────────────────────────────────────────────────────────────────────

class _ProjectTable extends StatelessWidget {
  const _ProjectTable({
    required this.projects,
    required this.onDelete,
  });

  final List<ProjectItem> projects;
  final void Function(ProjectItem) onDelete;

  static const _colName = 0.28;
  static const _colConfig = 0.32;
  static const _colStorage = 0.14;
  static const _colStatus = 0.14;
  static const _colActions = 0.12;

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
          // Header row
          _TableHeader(
            colName: _colName,
            colConfig: _colConfig,
            colStorage: _colStorage,
            colStatus: _colStatus,
            colActions: _colActions,
          ),
          const Divider(height: 1, color: AppColors.border),

          // Data rows
          if (projects.isEmpty)
            _EmptyRow()
          else
            ...projects.asMap().entries.map((e) {
              final isLast = e.key == projects.length - 1;
              return Column(
                children: [
                  _ProjectRow(
                    project: e.value,
                    colName: _colName,
                    colConfig: _colConfig,
                    colStorage: _colStorage,
                    colStatus: _colStatus,
                    colActions: _colActions,
                    onDelete: () => onDelete(e.value),
                    onOpen: () {},
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1,
                        color: AppColors.border,
                        indent: 56),
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
  const _TableHeader({
    required this.colName,
    required this.colConfig,
    required this.colStorage,
    required this.colStatus,
    required this.colActions,
  });

  final double colName, colConfig, colStorage, colStatus, colActions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Ícone placeholder width
            const SizedBox(width: 36),
            SizedBox(
              width: w * colName - 36,
              child: _HeaderCell('PROJECT NAME'),
            ),
            SizedBox(
                width: w * colConfig,
                child: _HeaderCell('CONFIGURATIONS')),
            SizedBox(
                width: w * colStorage, child: _HeaderCell('STORAGE')),
            SizedBox(
                width: w * colStatus, child: _HeaderCell('STATUS')),
            Expanded(child: _HeaderCell('ACTIONS', align: TextAlign.right)),
          ],
        ),
      );
    });
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {this.align = TextAlign.left});

  final String label;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: align,
      style: AppTextStyles.labelSm.copyWith(
        letterSpacing: 0.8,
        color: AppColors.textDisabled,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ─── Project Row ──────────────────────────────────────────────────────────────

class _ProjectRow extends StatefulWidget {
  const _ProjectRow({
    required this.project,
    required this.colName,
    required this.colConfig,
    required this.colStorage,
    required this.colStatus,
    required this.colActions,
    required this.onDelete,
    required this.onOpen,
  });

  final ProjectItem project;
  final double colName, colConfig, colStorage, colStatus, colActions;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  @override
  State<_ProjectRow> createState() => _ProjectRowState();
}

class _ProjectRowState extends State<_ProjectRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hovered
            ? AppColors.surface2.withOpacity(0.6)
            : Colors.transparent,
        child: LayoutBuilder(builder: (_, c) {
          final w = c.maxWidth;
          return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Folder icon
                const Icon(Icons.folder_outlined,
                    size: 20, color: AppColors.accent),
                const SizedBox(width: 16),
                // Project name
                SizedBox(
                  width: w * widget.colName - 36,
                  child: Text(
                    widget.project.name,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Configuration
                SizedBox(
                  width: w * widget.colConfig,
                  child: Text(
                    widget.project.configuration,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Storage
                SizedBox(
                  width: w * widget.colStorage,
                  child: Text(
                    widget.project.storage,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                // Status badge
                SizedBox(
                  width: w * widget.colStatus,
                  child: _StatusBadge(status: widget.project.status),
                ),
                // Actions
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_hovered) ...[
                        _ActionIcon(
                          icon: Icons.open_in_new_rounded,
                          tooltip: 'Abrir projeto',
                          onTap: widget.onOpen,
                        ),
                        const SizedBox(width: 4),
                        _ActionIcon(
                          icon: Icons.edit_outlined,
                          tooltip: 'Editar',
                          onTap: () {},
                        ),
                        const SizedBox(width: 4),
                        _ActionIcon(
                          icon: Icons.delete_outline_rounded,
                          tooltip: 'Excluir',
                          onTap: widget.onDelete,
                          danger: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      ProjectStatus.active => _OutlinedBadge(
          label: status.label,
          color: AppColors.success,
        ),
      ProjectStatus.queued => _OutlinedBadge(
          label: status.label,
          color: AppColors.textDisabled,
        ),
      ProjectStatus.training => _TrainingBadge(label: status.label),
      ProjectStatus.completed => _OutlinedBadge(
          label: status.label,
          color: AppColors.accent,
        ),
      ProjectStatus.error => _OutlinedBadge(
          label: status.label,
          color: AppColors.error,
        ),
    };
  }
}

class _OutlinedBadge extends StatelessWidget {
  const _OutlinedBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TrainingBadge extends StatefulWidget {
  const _TrainingBadge({required this.label});

  final String label;

  @override
  State<_TrainingBadge> createState() => _TrainingBadgeState();
}

class _TrainingBadgeState extends State<_TrainingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _opacity = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _opacity,
          builder: (_, __) => Opacity(
            opacity: _opacity.value,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          widget.label,
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.accent,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

// ─── Action icon button ───────────────────────────────────────────────────────

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.textSecondary;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ─── Empty row ────────────────────────────────────────────────────────────────

class _EmptyRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.folder_open_outlined,
                size: 36, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            Text(
              'Nenhum projeto encontrado',
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Misc helpers ─────────────────────────────────────────────────────────────

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 18,
      color: AppColors.border,
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded,
                size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              'Filter',
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
