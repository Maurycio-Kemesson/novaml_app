import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';
import 'package:novaml_app/features/projects/domain/models/project_model.dart';
import 'package:novaml_app/shared/providers/navigation_provider.dart';
import 'package:novaml_app/shared/providers/projects_provider.dart';
import 'package:novaml_app/shared/widgets/indicators/system_status_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class WorkspacePage extends ConsumerStatefulWidget {
  const WorkspacePage({super.key});

  @override
  ConsumerState<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends ConsumerState<WorkspacePage> {
  // ── Config state ─────────────────────────────────────────────────────────
  double _trainSplit = 0.80;
  int _selectedAlgorithm = 0;

  /// Apenas algoritmos suportados pelo backend (ModelType da API).
  static const _algorithmEnums = ProjectAlgorithm.values; // linearRegression, decisionTree

  // ── CSV state ─────────────────────────────────────────────────────────────
  List<String>? _csvHeaders;
  List<List<String>>? _csvRows;
  Set<int> _useColumns = {};
  Set<int> _nonNumericColumns = {};   // colunas que não são numéricas
  int? _targetColumn;
  bool _csvLoading = false;
  String? _csvFileName;
  String? _csvPath;

  static const int _maxDisplayRows = 10;

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromProject());
  }

  /// Carrega o estado persistido do projeto selecionado.
  Future<void> _loadFromProject() async {
    final project = ref.read(selectedProjectProvider);
    if (project == null) return;

    // Algoritmo
    final algIdx = _algorithmEnums.indexOf(project.algorithm);
    setState(() {
      _trainSplit = project.trainSplit;
      _selectedAlgorithm = algIdx >= 0 ? algIdx : 0;
    });

    // CSV — recarrega o arquivo se o caminho ainda é válido
    final csvPath = project.csvPath;
    if (csvPath != null && File(csvPath).existsSync()) {
      await _loadCsvFromPath(csvPath, project: project);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Auto-save
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _persist() async {
    final project = ref.read(selectedProjectProvider);
    if (project?.id == null) return;
    final repo = ref.read(projectRepositoryProvider);

    // Serializa use_columns como JSON de nomes de coluna
    String? useColumnsJson;
    if (_csvHeaders != null && _useColumns.isNotEmpty) {
      final names = _useColumns
          .where((i) => i < _csvHeaders!.length)
          .map((i) => _csvHeaders![i])
          .toList();
      useColumnsJson = jsonEncode(names);
    }

    final targetName = (_targetColumn != null &&
            _csvHeaders != null &&
            _targetColumn! < _csvHeaders!.length)
        ? _csvHeaders![_targetColumn!]
        : null;

    await repo.saveWorkspaceConfig(
      id:             project!.id!,
      trainSplit:     _trainSplit,
      algorithm:      _algorithmEnums[_selectedAlgorithm],
      targetColumn:   targetName,
      useColumnsJson: useColumnsJson,
      csvPath:        _csvPath,
      storageMb: _csvPath != null
          ? (File(_csvPath!).lengthSync() / (1024 * 1024))
          : null,
    );

    // Atualiza o selectedProject em memória
    final updated = await repo.getById(project.id!);
    if (updated != null && mounted) {
      ref.read(selectedProjectProvider.notifier).state = updated;
      ref.read(projectsProvider.notifier).refresh();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CSV parsing
  // ─────────────────────────────────────────────────────────────────────────

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var inQuotes = false;
    final current = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current.clear();
      } else {
        current.write(ch);
      }
    }
    result.add(current.toString().trim());
    return result;
  }

  /// Carrega CSV de um caminho já conhecido (restauração ao abrir projeto).
  Future<void> _loadCsvFromPath(String path, {Project? project}) async {
    setState(() => _csvLoading = true);
    try {
      final content = await File(path).readAsString();
      final lines = content
          .split('\n')
          .map((l) => l.trimRight())
          .where((l) => l.isNotEmpty)
          .toList();
      if (lines.isEmpty) { setState(() => _csvLoading = false); return; }

      final headers = _parseCsvLine(lines.first);
      final allRows = lines.skip(1).map(_parseCsvLine).toList();

      // Restaurar USE/TRGT a partir dos nomes salvos
      Set<int> useColumns;
      int? targetColumn;

      if (project?.useColumnsJson != null) {
        final savedNames =
            List<String>.from(jsonDecode(project!.useColumnsJson!));
        useColumns = headers
            .asMap()
            .entries
            .where((e) => savedNames.contains(e.value))
            .map((e) => e.key)
            .toSet();
      } else {
        useColumns = Set.from(List.generate(headers.length, (i) => i));
      }

      if (project?.targetColumn != null) {
        final idx = headers.indexOf(project!.targetColumn!);
        targetColumn = idx >= 0 ? idx : null;
      }

      // Detecta colunas não-numéricas — scikit-learn não aceita strings.
      final nonNumeric = <int>{};
      for (int col = 0; col < headers.length; col++) {
        final sample = allRows
            .take(20)
            .map((r) => col < r.length ? r[col].trim() : '')
            .where((v) => v.isNotEmpty);
        final hasNonNumeric =
            sample.any((v) => double.tryParse(v) == null);
        if (hasNonNumeric) nonNumeric.add(col);
      }

      setState(() {
        _csvPath            = path;
        _csvFileName        = path.split(Platform.pathSeparator).last;
        _csvHeaders         = headers;
        _csvRows            = allRows;
        _useColumns         = useColumns;
        _nonNumericColumns  = nonNumeric;
        _targetColumn       = targetColumn;
        _csvLoading         = false;
      });
    } catch (_) {
      setState(() => _csvLoading = false);
    }
  }

  Future<void> _pickCsvFile() async {
    setState(() => _csvLoading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
        dialogTitle: 'Selecione um arquivo CSV',
      );
      if (result == null || result.files.isEmpty || result.files.single.path == null) {
        setState(() => _csvLoading = false);
        return;
      }
      final path = result.files.single.path!;
      await _loadCsvFromPath(path);
      _csvPath = path;
      await _persist();
    } catch (e) {
      setState(() => _csvLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao ler o arquivo: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasData = _csvHeaders != null && _csvRows != null;
    final totalRows = _csvRows?.length ?? 0;
    final displayRows = _csvRows?.take(_maxDisplayRows).toList() ?? [];

    return Stack(
      fit: StackFit.expand,
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero ──────────────────────────────────────────────────────
              const _HeroSection(),
              const SizedBox(height: 28),

              // ── Grid 3 colunas ────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _IngestCard(
                      fileName: _csvFileName,
                      loading: _csvLoading,
                      onPick: _pickCsvFile,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _PartitioningCard(
                      trainSplit: _trainSplit,
                      onChanged: (v) {
                        setState(() => _trainSplit = v);
                        _persist();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _AlgorithmCard(
                      algorithms: _algorithmEnums
                          .map((a) => a.label)
                          .toList(),
                      descriptions: _algorithmEnums
                          .map((a) => a.description)
                          .toList(),
                      selectedIndex: _selectedAlgorithm,
                      onSelect: (i) {
                        setState(() => _selectedAlgorithm = i);
                        _persist();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Spectral Data Preview ─────────────────────────────────────
              if (!hasData)
                _SpectralEmpty(loading: _csvLoading, onPick: _pickCsvFile)
              else
                _SpectralPreview(
                  headers: _csvHeaders!,
                  rows: displayRows,
                  totalRows: totalRows,
                  useColumns: _useColumns,
                  nonNumericColumns: _nonNumericColumns,
                  targetColumn: _targetColumn,
                  onUseToggle: (col, value) {
                    setState(() {
                      if (value) {
                        _useColumns.add(col);
                      } else {
                        _useColumns.remove(col);
                        if (_targetColumn == col) _targetColumn = null;
                      }
                    });
                    _persist();
                  },
                  onTargetSelect: (col) {
                    setState(() => _targetColumn = col);
                    _persist();
                  },
                ),
            ],
          ),
        ),

        // ── Bottom bar fixo ───────────────────────────────────────────────
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BottomBar(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NOVAML Workspace', style: AppTextStyles.displayMd),
        const SizedBox(height: 8),
        Text(
          'Configure your stellar dataset and select a predictive model for spectral '
          'analysis. Ensure all astronomical features are correctly mapped before '
          'initiating neural training.',
          style:
              AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card 1 — Ingest
// ─────────────────────────────────────────────────────────────────────────────

class _IngestCard extends StatefulWidget {
  const _IngestCard({
    required this.onPick,
    this.fileName,
    this.loading = false,
  });

  final VoidCallback onPick;
  final String? fileName;
  final bool loading;

  @override
  State<_IngestCard> createState() => _IngestCardState();
}

class _IngestCardState extends State<_IngestCard> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final hasFile = widget.fileName != null;

    return GestureDetector(
      onTap: widget.loading ? null : widget.onPick,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _dragging
                ? AppColors.accentSubtle
                : AppColors.surface1,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: _dragging
                  ? AppColors.accent
                  : hasFile
                      ? AppColors.success.withOpacity(0.5)
                      : AppColors.border,
              width: _dragging ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              if (widget.loading)
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                )
              else
                Icon(
                  hasFile
                      ? Icons.check_circle_outline_rounded
                      : Icons.cloud_upload_outlined,
                  size: 40,
                  color: hasFile ? AppColors.success : AppColors.accent.withOpacity(0.8),
                ),
              const SizedBox(height: 16),
              Text(
                hasFile ? 'Dataset carregado' : 'Ingest Stellar Dataset',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 8),
              if (hasFile)
                Text(
                  widget.fileName!,
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.accent),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                )
              else ...[
                Text(
                  'Clique para selecionar ou arraste um .CSV',
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Max size: 50GB / Supported: CSV, FITS',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card 2 — Data Partitioning
// ─────────────────────────────────────────────────────────────────────────────

class _PartitioningCard extends StatelessWidget {
  const _PartitioningCard({
    required this.trainSplit,
    required this.onChanged,
  });

  final double trainSplit;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final trainPct = (trainSplit * 100).round();
    final testPct = 100 - trainPct;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_outline_rounded,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('Data Partitioning', style: AppTextStyles.h3),
              const Spacer(),
              const _SmallBadge(label: 'OPTIMAL COVERAGE'),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'TRAIN / TEST SPLIT',
            style: AppTextStyles.labelSm.copyWith(
              letterSpacing: 0.8,
              color: AppColors.textDisabled,
            ),
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.surface2,
              thumbColor: AppColors.accent,
              overlayColor: AppColors.accent.withOpacity(0.15),
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: trainSplit,
              min: 0.5,
              max: 0.95,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$trainPct% TRAIN',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text('NEURAL LEARNING',
                      style: AppTextStyles.caption),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$testPct% TEST',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text('VALIDATION SET',
                      style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card 3 — Algorithm Selection
// ─────────────────────────────────────────────────────────────────────────────

class _AlgorithmCard extends StatelessWidget {
  const _AlgorithmCard({
    required this.algorithms,
    required this.descriptions,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<String> algorithms;
  final List<String> descriptions;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('Algorithm Selection', style: AppTextStyles.h3),
              const Spacer(),
              const _SmallBadge(label: 'API SUPPORTED'),
            ],
          ),
          const SizedBox(height: 16),
          ...algorithms.asMap().entries.map((e) => _AlgorithmItem(
                label: e.value,
                description: e.key < descriptions.length
                    ? descriptions[e.key]
                    : null,
                selected: e.key == selectedIndex,
                onTap: () => onSelect(e.key),
              )),
        ],
      ),
    );
  }
}

class _AlgorithmItem extends StatefulWidget {
  const _AlgorithmItem({
    required this.label,
    required this.selected,
    required this.onTap,
    this.description,
  });

  final String label;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_AlgorithmItem> createState() => _AlgorithmItemState();
}

class _AlgorithmItemState extends State<_AlgorithmItem> {
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
          margin: const EdgeInsets.only(bottom: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.surface2
                : _hovered
                    ? AppColors.surface2.withOpacity(0.5)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border(
              left: BorderSide(
                color: widget.selected
                    ? AppColors.accent
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: AppTextStyles.bodyMd.copyWith(
                  color: widget.selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: widget.selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
              if (widget.description != null && widget.selected) ...[
                const SizedBox(height: 4),
                Text(
                  widget.description!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spectral — Empty state (sem CSV carregado)
// ─────────────────────────────────────────────────────────────────────────────

class _SpectralEmpty extends StatelessWidget {
  const _SpectralEmpty({required this.loading, required this.onPick});

  final bool loading;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.table_chart_outlined,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('Spectral Data Preview', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 24),
          if (loading)
            const CircularProgressIndicator(color: AppColors.accent)
          else ...[
            Icon(Icons.upload_file_outlined,
                size: 36, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            Text(
              'Nenhum dataset carregado',
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              'Selecione um arquivo CSV para visualizar os dados aqui.',
              style: AppTextStyles.bodySm,
            ),
            const SizedBox(height: 20),
            _OutlinedActionButton(
              label: 'Carregar CSV',
              icon: Icons.upload_file_outlined,
              onTap: onPick,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spectral — Tabela com dados reais
// ─────────────────────────────────────────────────────────────────────────────

class _SpectralPreview extends StatefulWidget {
  const _SpectralPreview({
    required this.headers,
    required this.rows,
    required this.totalRows,
    required this.useColumns,
    required this.nonNumericColumns,
    required this.targetColumn,
    required this.onUseToggle,
    required this.onTargetSelect,
  });

  final List<String> headers;
  final List<List<String>> rows;
  final int totalRows;
  final Set<int> useColumns;
  final Set<int> nonNumericColumns;
  final int? targetColumn;
  final void Function(int col, bool value) onUseToggle;
  final void Function(int col) onTargetSelect;

  @override
  State<_SpectralPreview> createState() => _SpectralPreviewState();
}

class _SpectralPreviewState extends State<_SpectralPreview> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showingCount = widget.rows.length;
    final colCount = widget.headers.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.table_chart_outlined,
                    size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Text('Spectral Data Preview', style: AppTextStyles.h3),
                const Spacer(),
                _SmallBadge(
                    label: 'ROWS: ${_formatCount(widget.totalRows)}',
                    muted: true),
                const SizedBox(width: 8),
                _SmallBadge(label: 'COLS: $colCount', muted: true),
                const SizedBox(width: 8),
                _SmallBadge(
                    label: 'SHOWING: $showingCount', muted: true),
              ],
            ),
          ),
          // ── Banner de aviso: colunas não-numéricas selecionadas ─────────
          Builder(builder: (context) {
            final badCols = widget.useColumns
                .intersection(widget.nonNumericColumns)
                .map((i) => i < widget.headers.length ? widget.headers[i] : '')
                .where((n) => n.isNotEmpty)
                .toList()
              ..sort();
            if (badCols.isEmpty) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppColors.warning.withOpacity(0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Colunas de texto selecionadas — scikit-learn não processa strings. '
                      'Desmarque USE em: ${badCols.join(', ')}.',
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.border),

          // ── Tabela com scroll horizontal + scrollbar visível ─────────────
          Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CsvHeaderRow(
                    headers: widget.headers,
                    useColumns: widget.useColumns,
                    nonNumericColumns: widget.nonNumericColumns,
                    targetColumn: widget.targetColumn,
                    onUseToggle: widget.onUseToggle,
                    onTargetSelect: widget.onTargetSelect,
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  ...widget.rows.asMap().entries.map((e) {
                    final isLast = e.key == widget.rows.length - 1;
                    return Column(
                      children: [
                        _CsvDataRow(
                          values: e.value,
                          headers: widget.headers,
                          targetColumn: widget.targetColumn,
                          useColumns: widget.useColumns,
                        ),
                        if (!isLast)
                          const Divider(
                              height: 1, color: AppColors.border),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CSV Header Row — USE (Checkbox) + TRGT (Radio)
// ─────────────────────────────────────────────────────────────────────────────

class _CsvHeaderRow extends StatelessWidget {
  const _CsvHeaderRow({
    required this.headers,
    required this.useColumns,
    required this.nonNumericColumns,
    required this.targetColumn,
    required this.onUseToggle,
    required this.onTargetSelect,
  });

  final List<String> headers;
  final Set<int> useColumns;
  final Set<int> nonNumericColumns;
  final int? targetColumn;
  final void Function(int, bool) onUseToggle;
  final void Function(int) onTargetSelect;

  static const double _colWidth = 160.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        children: headers.asMap().entries.map((e) {
          final i = e.key;
          final header = e.value;
          final isUsed = useColumns.contains(i);
          final isTarget = targetColumn == i;
          final isNonNumeric = nonNumericColumns.contains(i);

          return SizedBox(
            width: _colWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome da coluna + badge de aviso se for texto
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        header,
                        style: AppTextStyles.labelSm.copyWith(
                          color: isTarget
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          fontWeight: isTarget
                              ? FontWeight.w700
                              : FontWeight.w500,
                          letterSpacing: 0.4,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isNonNumeric) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: 'Coluna de texto — incompatível com scikit-learn',
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 12,
                          color: isUsed
                              ? AppColors.warning
                              : AppColors.textDisabled,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // ── USE: Checkbox ─────────────────────────────────────
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: Checkbox(
                        value: isUsed,
                        onChanged: (v) =>
                            onUseToggle(i, v ?? false),
                        activeColor: AppColors.accent,
                        checkColor: Colors.black,
                        side: const BorderSide(
                            color: AppColors.accent, width: 1.5),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('USE', style: AppTextStyles.caption),
                    const SizedBox(width: 10),

                    // ── TRGT: Radio ───────────────────────────────────────
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: Radio<int>(
                        value: i,
                        groupValue: targetColumn,
                        onChanged: isUsed
                            ? (_) => onTargetSelect(i)
                            : null,
                        activeColor: AppColors.warning,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('TRGT', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CSV Data Row
// ─────────────────────────────────────────────────────────────────────────────

class _CsvDataRow extends StatefulWidget {
  const _CsvDataRow({
    required this.values,
    required this.headers,
    required this.targetColumn,
    required this.useColumns,
  });

  final List<String> values;
  final List<String> headers;
  final int? targetColumn;
  final Set<int> useColumns;

  @override
  State<_CsvDataRow> createState() => _CsvDataRowState();
}

class _CsvDataRowState extends State<_CsvDataRow> {
  bool _hovered = false;

  static const double _colWidth = 160.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _hovered
            ? AppColors.surface2.withOpacity(0.5)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 12),
        child: Row(
          children: List.generate(widget.headers.length, (i) {
            final value =
                i < widget.values.length ? widget.values[i] : '';
            final isTarget = widget.targetColumn == i;
            final isUsed = widget.useColumns.contains(i);

            return SizedBox(
              width: _colWidth,
              child: Text(
                value,
                style: AppTextStyles.bodyMd.copyWith(
                  color: isTarget
                      ? AppColors.warning
                      : isUsed
                          ? AppColors.textPrimary
                          : AppColors.textDisabled,
                  fontWeight:
                      isTarget ? FontWeight.w600 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends ConsumerStatefulWidget {
  const _BottomBar();

  @override
  ConsumerState<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends ConsumerState<_BottomBar> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          const SystemStatusBar(),
          const Spacer(),
          MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => ref
                  .read(appFlowProvider.notifier)
                  .state = AppFlowState.training,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 10),
                decoration: BoxDecoration(
                  color: _hovered ? AppColors.accentHover : AppColors.accent,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.rocket_launch_rounded,
                        size: 16, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(
                      'Initiate Neural Training',
                      style: AppTextStyles.labelMd.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? AppColors.textDisabled : AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
        color: color.withOpacity(0.06),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OutlinedActionButton extends StatefulWidget {
  const _OutlinedActionButton(
      {required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_OutlinedActionButton> createState() =>
      _OutlinedActionButtonState();
}

class _OutlinedActionButtonState extends State<_OutlinedActionButton> {
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
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.accent.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: AppColors.accent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 15, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.accent,
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
