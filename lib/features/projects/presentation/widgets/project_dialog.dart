import 'package:flutter/material.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';
import 'package:novaml_app/features/projects/domain/models/project_model.dart';

/// Dialog reutilizável para criar ou editar um projeto.
/// Retorna o resultado via `Navigator.pop(context, result)`.
class ProjectDialog extends StatefulWidget {
  const ProjectDialog({super.key, this.project});

  /// Se fornecido, dialog fica em modo edição.
  final Project? project;

  static Future<ProjectFormResult?> show(
    BuildContext context, {
    Project? project,
  }) =>
      showDialog<ProjectFormResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ProjectDialog(project: project),
      );

  @override
  State<ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<ProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late ProjectAlgorithm _algorithm;
  bool _saving = false;

  bool get _isEdit => widget.project != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.project?.name ?? '');
    _descCtrl =
        TextEditingController(text: widget.project?.description ?? '');
    _algorithm = widget.project?.algorithm ?? ProjectAlgorithm.linearRegression;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ProjectFormResult(
        name:        _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        algorithm: _algorithm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: SizedBox(
        width: 520,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.accentSubtle,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(Icons.folder_outlined,
                          size: 18, color: AppColors.accent),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isEdit ? 'Editar Projeto' : 'Novo Projeto',
                      style: AppTextStyles.h2,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 16,
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(color: AppColors.border),
                const SizedBox(height: 24),

                // ── Nome ──────────────────────────────────────────────────
                _FieldLabel('Nome do Projeto *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  autofocus: true,
                  style: AppTextStyles.bodyMd,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Nebula Seg-X Alpha',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nome é obrigatório'
                      : null,
                ),

                const SizedBox(height: 16),

                // ── Descrição ─────────────────────────────────────────────
                _FieldLabel('Descrição (opcional)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  style: AppTextStyles.bodyMd,
                  decoration: const InputDecoration(
                    hintText: 'Descreva o objetivo do projeto...',
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Algoritmo ─────────────────────────────────────────────
                _FieldLabel('Algoritmo'),
                const SizedBox(height: 6),
                _AlgorithmSelector(
                  value: _algorithm,
                  onChanged: (v) => setState(() => _algorithm = v),
                ),

                const SizedBox(height: 28),

                // ── Ações ─────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _DialogButton(
                      label: 'Cancelar',
                      outlined: true,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    _DialogButton(
                      label: _isEdit ? 'Salvar' : 'Criar Projeto',
                      loading: _saving,
                      onTap: _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Algorithm selector ───────────────────────────────────────────────────────

class _AlgorithmSelector extends StatelessWidget {
  const _AlgorithmSelector({
    required this.value,
    required this.onChanged,
  });

  final ProjectAlgorithm value;
  final ValueChanged<ProjectAlgorithm> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProjectAlgorithm>(
          value: value,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          dropdownColor: AppColors.surface2,
          style: AppTextStyles.bodyMd,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: AppColors.textSecondary),
          items: ProjectAlgorithm.values
              .map((a) => DropdownMenuItem(
                    value: a,
                    child: Text(a.label,
                        style: AppTextStyles.bodyMd),
                  ))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyles.labelMd
            .copyWith(color: AppColors.textSecondary),
      );
}

class _DialogButton extends StatefulWidget {
  const _DialogButton({
    required this.label,
    required this.onTap,
    this.outlined = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool outlined;
  final bool loading;

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.outlined
        ? Colors.transparent
        : _hovered
            ? AppColors.accentHover
            : AppColors.accent;
    final fg = widget.outlined ? AppColors.textSecondary : Colors.black;
    final border = widget.outlined ? AppColors.border : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.loading ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: border),
          ),
          child: widget.loading
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: fg,
                  ),
                )
              : Text(
                  widget.label,
                  style: AppTextStyles.labelMd.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Result type ─────────────────────────────────────────────────────────────

class ProjectFormResult {
  final String name;
  final String? description;
  final ProjectAlgorithm algorithm;

  const ProjectFormResult({
    required this.name,
    this.description,
    required this.algorithm,
  });
}
