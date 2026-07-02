import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novaml_app/core/models/api_models.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';
import 'package:novaml_app/shared/providers/models_provider.dart';
import 'package:novaml_app/shared/providers/navigation_provider.dart';
import 'package:novaml_app/shared/widgets/components/nova_button.dart';

/// Dashboard de resultados — exibe dados reais do último modelo treinado.
class DashboardResultsPage extends ConsumerWidget {
  const DashboardResultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(lastTrainedModelProvider);

    if (model == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.analytics_outlined,
                size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text('Nenhum modelo treinado', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text(
              'Treine um modelo no workspace para ver os resultados aqui.',
              style: AppTextStyles.bodySm,
            ),
            const SizedBox(height: 24),
            NovaButton(
              label: 'Ir para Workspace',
              onPressed: () => ref.read(appFlowProvider.notifier).state =
                  AppFlowState.workspace,
              leading: const Icon(Icons.science_outlined, size: 16),
            ),
          ],
        ),
      );
    }

    return _ResultsDashboard(model: model);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard com dados reais
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsDashboard extends StatelessWidget {
  const _ResultsDashboard({required this.model});

  final StoredModel model;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroSection(model: model),
          const SizedBox(height: 28),

          // ── Metric cards ─────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: model.scoreMetricLabel.toUpperCase(),
                  value: (model.validationScore * 100).toStringAsFixed(2),
                  unit: '%',
                  icon: Icons.adjust_rounded,
                  barColor: AppColors.accent,
                  barValue: model.validationScore.clamp(0.0, 1.0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MetricCard(
                  label: 'AMOSTRAS VALIDAÇÃO',
                  value: model.validationPredictions.length.toString(),
                  icon: Icons.dataset_outlined,
                  barColor: const Color(0xFF8A95A8),
                  barValue: 1.0,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MetricCard(
                  label: 'TIPO DE MODELO',
                  value: model.modelType.label,
                  icon: Icons.memory_outlined,
                  barColor: AppColors.galaxy,
                  barValue: 1.0,
                  small: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Charts row ──────────────────────────────────────────────────────
          SizedBox(
            height: 400,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: model.task == ApiTask.classification
                      ? _ConfusionMatrixCard(model: model)
                      : _PredictionsScatterCard(model: model),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: _ResidualHistogramCard(model: model),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _FeatureListCard(model: model),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.model});

  final StoredModel model;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${model.task.value.toUpperCase()} ANALYSIS',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(model.modelType.label, style: AppTextStyles.displayMd),
                  const SizedBox(width: 10),
                  Text(
                    'Model #${model.id ?? '—'}',
                    style: AppTextStyles.displayMd.copyWith(
                      color: AppColors.textDisabled,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'TARGET COLUMN',
              style: AppTextStyles.caption.copyWith(
                letterSpacing: 0.8,
                color: AppColors.textDisabled,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              model.targetName,
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metric Card
// ─────────────────────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.barColor,
    required this.barValue,
    this.unit = '',
    this.small = false,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color barColor;
  final double barValue;
  final bool small;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelSm.copyWith(
                    letterSpacing: 0.6,
                    color: AppColors.textDisabled,
                  ),
                ),
              ),
              Icon(icon, size: 16, color: AppColors.textDisabled),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: AppTextStyles.displayLg.copyWith(
                    color: AppColors.accent,
                    fontSize: small ? 20 : 32,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: barValue,
              backgroundColor: AppColors.surface2,
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scatter — Predições vs Ground Truth (regressão)
// ─────────────────────────────────────────────────────────────────────────────

class _PredictionsScatterCard extends StatefulWidget {
  const _PredictionsScatterCard({required this.model});

  final StoredModel model;

  @override
  State<_PredictionsScatterCard> createState() =>
      _PredictionsScatterCardState();
}

class _PredictionsScatterCardState extends State<_PredictionsScatterCard> {
  int? _hoveredIdx;

  @override
  Widget build(BuildContext context) {
    final preds = widget.model.validationPredictions;
    final truth = widget.model.validationGroundTruth;

    // Limita a 200 pontos para performance
    final count = math.min(preds.length, 200);
    final pts = List.generate(
        count, (i) => _Pt(x: truth[i].toDouble(), y: preds[i].toDouble()));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Predições vs. Real', style: AppTextStyles.h2),
                Text(
                  'Valores de validação — ${preds.length} amostras',
                  style: AppTextStyles.bodySm,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(builder: (_, c) {
              return MouseRegion(
                onHover: (e) => _onHover(e.localPosition, c.biggest, pts),
                onExit: (_) => setState(() => _hoveredIdx = null),
                child: CustomPaint(
                  size: c.biggest,
                  painter: _ScatterPainter(
                    points: pts,
                    hoveredIdx: _hoveredIdx,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _onHover(Offset local, Size size, List<_Pt> pts) {
    if (pts.isEmpty) return;

    final minX = pts.map((p) => p.x).reduce(math.min);
    final maxX = pts.map((p) => p.x).reduce(math.max);
    final minY = pts.map((p) => p.y).reduce(math.min);
    final maxY = pts.map((p) => p.y).reduce(math.max);
    final rawRangeX = (maxX - minX).abs().clamp(1e-9, double.infinity);
    final rawRangeY = (maxY - minY).abs().clamp(1e-9, double.infinity);
    final axMinX = minX - rawRangeX * 0.1;
    final axMinY = minY - rawRangeY * 0.1;
    final rangeX = rawRangeX * 1.2;
    final rangeY = rawRangeY * 1.2;

    const pad = 24.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;

    int? closest;
    double minDist = 14;
    for (int i = 0; i < pts.length; i++) {
      final px = pad + (pts[i].x - axMinX) / rangeX * w;
      final py = pad + h - (pts[i].y - axMinY) / rangeY * h;
      final d = (local - Offset(px, py)).distance;
      if (d < minDist) {
        minDist = d;
        closest = i;
      }
    }
    if (closest != _hoveredIdx) setState(() => _hoveredIdx = closest);
  }
}

class _Pt {
  final double x;
  final double y;
  const _Pt({required this.x, required this.y});
}

class _ScatterPainter extends CustomPainter {
  const _ScatterPainter({required this.points, this.hoveredIdx});

  final List<_Pt> points;
  final int? hoveredIdx;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const pad = 24.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;

    final minX = points.map((p) => p.x).reduce(math.min);
    final maxX = points.map((p) => p.x).reduce(math.max);
    final minY = points.map((p) => p.y).reduce(math.min);
    final maxY = points.map((p) => p.y).reduce(math.max);
    final rawRangeX = (maxX - minX).abs().clamp(1e-9, double.infinity);
    final rawRangeY = (maxY - minY).abs().clamp(1e-9, double.infinity);

    // 10% de margem para pontos não ficarem colados na borda
    final marginX = rawRangeX * 0.1;
    final marginY = rawRangeY * 0.1;
    final axMinX = minX - marginX;
    final axMaxX = maxX + marginX;
    final axMinY = minY - marginY;
    final axMaxY = maxY + marginY;
    final rangeX = axMaxX - axMinX;
    final rangeY = axMaxY - axMinY;

    double toX(double v) => pad + (v - axMinX) / rangeX * w;
    double toY(double v) => pad + h - (v - axMinY) / rangeY * h;

    // Área útil do gráfico
    final plotRect = Rect.fromLTWH(pad, pad, w, h);

    canvas.save();
    canvas.clipRect(plotRect);

    // Linha diagonal ideal (y == x)
    final diagPaint = Paint()
      ..color = AppColors.accent.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final diagStart = math.max(axMinX, axMinY);
    final diagEnd = math.min(axMaxX, axMaxY);
    if (diagStart < diagEnd) {
      canvas.drawLine(
        Offset(toX(diagStart), toY(diagStart)),
        Offset(toX(diagEnd), toY(diagEnd)),
        diagPaint,
      );
    }

    // Pontos
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final isHov = i == hoveredIdx;
      final paint = Paint()
        ..color = AppColors.accent.withOpacity(isHov ? 1.0 : 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(toX(p.x), toY(p.y)), isHov ? 5 : 3, paint);
    }

    canvas.restore();

    // Tooltip (fora do clip)
    if (hoveredIdx != null) {
      final p = points[hoveredIdx!];
      _drawTooltip(canvas, size, Offset(toX(p.x), toY(p.y)),
          real: p.x, pred: p.y);
    }
  }

  void _drawTooltip(Canvas canvas, Size size, Offset anchor,
      {required double real, required double pred}) {
    const w = 150.0;
    const h = 48.0;
    const pad = 10.0;

    double dx = anchor.dx + 10;
    double dy = anchor.dy - h - 10;
    if (dx + w > size.width) dx = anchor.dx - w - 10;
    if (dy < 0) dy = anchor.dy + 10;

    final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(dx, dy, w, h), const Radius.circular(6));

    canvas.drawRRect(rect, Paint()..color = const Color(0xE6111827));
    canvas.drawRRect(
        rect,
        Paint()
          ..color = AppColors.accent.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    _txt(canvas, 'Real: ${real.toStringAsFixed(4)}',
        Offset(dx + pad, dy + pad), 10, const Color(0xFFE8EDF5));
    _txt(canvas, 'Pred: ${pred.toStringAsFixed(4)}',
        Offset(dx + pad, dy + pad + 16), 10, AppColors.accent);
  }

  void _txt(
      Canvas canvas, String text, Offset offset, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            fontSize: size,
            color: color,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_ScatterPainter old) => old.hoveredIdx != hoveredIdx;
}

// ─────────────────────────────────────────────────────────────────────────────
// Histograma de resíduos
// ─────────────────────────────────────────────────────────────────────────────

class _ResidualHistogramCard extends StatelessWidget {
  const _ResidualHistogramCard({required this.model});

  final StoredModel model;

  @override
  Widget build(BuildContext context) {
    final preds = model.validationPredictions;
    final truth = model.validationGroundTruth;

    final residuals = List.generate(math.min(preds.length, truth.length),
        (i) => preds[i].toDouble() - truth[i].toDouble());

    if (residuals.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
            child: Text('Sem dados',
                style: TextStyle(color: AppColors.textDisabled))),
      );
    }

    // Histograma de 10 bins
    final minR = residuals.reduce(math.min);
    final maxR = residuals.reduce(math.max);
    const bins = 10;
    final range = (maxR - minR).abs().clamp(1e-9, double.infinity);
    final counts = List<int>.filled(bins, 0);
    for (final r in residuals) {
      final idx = ((r - minR) / range * (bins - 1)).round().clamp(0, bins - 1);
      counts[idx]++;
    }
    final maxCount = counts.reduce(math.max).clamp(1, double.infinity).toInt();

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
          Text('Distribuição de Resíduos', style: AppTextStyles.h2),
          Text(
            'Predição − Real (${residuals.length} amostras)',
            style: AppTextStyles.bodySm,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(bins, (i) {
                final h = counts[i] / maxCount;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Tooltip(
                      message: 'n=${counts[i]}',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            height: h * 200,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.7),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(minR.toStringAsFixed(2), style: AppTextStyles.caption),
              Text('0', style: AppTextStyles.caption),
              Text(maxR.toStringAsFixed(2), style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature List
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureListCard extends StatelessWidget {
  const _FeatureListCard({required this.model});

  final StoredModel model;

  @override
  Widget build(BuildContext context) {
    final features = model.featureNames ?? [];

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
              const Icon(Icons.list_alt_rounded,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('Features Utilizadas', style: AppTextStyles.h2),
              const Spacer(),
              if (features.isNotEmpty)
                Text(
                  '${features.length} colunas',
                  style: AppTextStyles.caption,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (features.isEmpty)
            Text('Todas as colunas disponíveis foram utilizadas.',
                style: AppTextStyles.bodySm)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: features
                  .map((f) =>
                      _FeatureChip(label: f, isTarget: f == model.targetName))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label, required this.isTarget});

  final String label;
  final bool isTarget;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:
            isTarget ? AppColors.warning.withOpacity(0.1) : AppColors.surface2,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color:
              isTarget ? AppColors.warning.withOpacity(0.5) : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: isTarget ? AppColors.warning : AppColors.textSecondary,
          fontWeight: isTarget ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confusion Matrix — exibida para modelos de classificação
// ─────────────────────────────────────────────────────────────────────────────

class _ConfusionMatrixCard extends StatelessWidget {
  const _ConfusionMatrixCard({required this.model});

  final StoredModel model;

  /// Retorna o nome legível do label usando classLabels do modelo se disponível.
  String _label(double v) {
    final cl = model.classLabels;
    if (cl != null) {
      final name = cl[v.round()];
      if (name != null) return name;
    }
    return 'C${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final preds = model.validationPredictions;
    final truth = model.validationGroundTruth;
    final n = math.min(preds.length, truth.length);

    // Labels únicos ordenados
    final labels = <double>{
      ...preds.map((e) => e.toDouble()),
      ...truth.map((e) => e.toDouble()),
    }.toList()
      ..sort();
    final k = labels.length;
    final idx = {for (var i = 0; i < k; i++) labels[i]: i};

    // matrix[real][predito]
    final matrix = List.generate(k, (_) => List<int>.filled(k, 0));
    for (int i = 0; i < n; i++) {
      final ti = idx[truth[i].toDouble()];
      final pi = idx[preds[i].toDouble()];
      if (ti != null && pi != null) matrix[ti][pi]++;
    }

    final maxVal = matrix
        .expand((r) => r)
        .reduce(math.max)
        .clamp(1, double.maxFinite)
        .toInt();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Matriz de Confusão', style: AppTextStyles.h2),
          Text(
            'Real × Predito — $n amostras',
            style: AppTextStyles.bodySm,
          ),
          const SizedBox(height: 12),
          // Header: labels das colunas (Predito)
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Row(
              children: labels
                  .map((l) => Expanded(
                        child: Center(
                          child: Text(
                            _label(l),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textDisabled,
                              fontSize: 10,
                              letterSpacing: 0.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                // Eixo Y: labels das linhas (Real)
                SizedBox(
                  width: 52,
                  child: Column(
                    children: labels
                        .map((l) => Expanded(
                              child: Center(
                                child: Text(
                                  _label(l),
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textDisabled,
                                    fontSize: 10,
                                    letterSpacing: 0.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                // Células da matriz
                Expanded(
                  child: Column(
                    children: List.generate(
                      k,
                      (row) => Expanded(
                        child: Row(
                          children: List.generate(k, (col) {
                            final count = matrix[row][col];
                            final ratio = count / maxVal;
                            final isDiag = row == col;

                            final bgColor = isDiag
                                ? AppColors.accent
                                    .withOpacity(0.1 + ratio * 0.7)
                                : AppColors.error
                                    .withOpacity(ratio.clamp(0.0, 1.0) * 0.55);

                            final fgColor = isDiag && ratio > 0.35
                                ? AppColors.accent
                                : ratio > 0.4
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary;

                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(4),
                                  border: isDiag
                                      ? Border.all(
                                          color:
                                              AppColors.accent.withOpacity(0.35),
                                          width: 1,
                                        )
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    _formatCount(count),
                                    style: AppTextStyles.bodySm.copyWith(
                                      color: fgColor,
                                      fontWeight: isDiag
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _LegendDot(color: AppColors.accent, label: 'Correto (diagonal)'),
              const SizedBox(width: 16),
              _LegendDot(
                  color: AppColors.error, label: 'Erro de classificação'),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textDisabled),
        ),
      ],
    );
  }
}
