import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';

/// Dashboard de resultados — Classification Analysis.
/// Fiel ao protótipo Stitch: métricas, confusion matrix, scatter plot PCA.
class DashboardResultsPage extends StatelessWidget {
  const DashboardResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero ───────────────────────────────────────────────────────────
          const _HeroSection(),
          const SizedBox(height: 28),

          // ── Metric cards ───────────────────────────────────────────────────
          const Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'OVERALL ACCURACY',
                  value: '98.42',
                  unit: '%',
                  icon: Icons.adjust_rounded,
                  barColor: AppColors.accent,
                  barValue: 0.9842,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _MetricCard(
                  label: 'WEIGHTED PRECISION',
                  value: '0.976',
                  icon: Icons.track_changes_rounded,
                  barColor: Color(0xFF8A95A8),
                  barValue: 0.976,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _MetricCard(
                  label: 'F1-SCORE (MACRO)',
                  value: '0.981',
                  icon: Icons.analytics_outlined,
                  barColor: AppColors.success,
                  barValue: 0.981,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Charts row ─────────────────────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Clustered Light Curves (PCA scatter)
                const Expanded(flex: 5, child: _LightCurvesCard()),
                const SizedBox(width: 16),
                // Confusion Matrix
                const Expanded(flex: 4, child: _ConfusionMatrixCard()),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── AI Interpretability ────────────────────────────────────────────
          const _AIInterpretabilityCard(),
        ],
      ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEURAL NET CLASSIFICATION',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('Classification Analysis ',
                      style: AppTextStyles.displayMd),
                  Text(
                    'v4.0.2',
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
              'LAST BATCH',
              style: AppTextStyles.caption.copyWith(
                letterSpacing: 0.8,
                color: AppColors.textDisabled,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '2023-11-24 // 04:12 UTC',
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
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color barColor;
  final double barValue;

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
              Text(
                label,
                style: AppTextStyles.labelSm.copyWith(
                  letterSpacing: 0.6,
                  color: AppColors.textDisabled,
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
              Text(
                value,
                style: AppTextStyles.displayLg.copyWith(
                  color: label.contains('ACCURACY')
                      ? AppColors.accent
                      : AppColors.textPrimary,
                  fontSize: 32,
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
// Clustered Light Curves — PCA Scatter Plot
// ─────────────────────────────────────────────────────────────────────────────

class _LightCurvesCard extends StatefulWidget {
  const _LightCurvesCard();

  @override
  State<_LightCurvesCard> createState() => _LightCurvesCardState();
}

class _LightCurvesCardState extends State<_LightCurvesCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_ScatterPoint> _points;
  _ScatterPoint? _hoveredPoint;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _points = _generatePoints();
  }

  static List<_ScatterPoint> _generatePoints() {
    final rng = math.Random(42);
    final points = <_ScatterPoint>[];

    // Stars cluster — top-left
    for (int i = 0; i < 80; i++) {
      points.add(_ScatterPoint(
        x: 0.15 + rng.nextDouble() * 0.25,
        y: 0.15 + rng.nextDouble() * 0.25,
        type: _ObjectType.star,
      ));
    }
    // Galaxies cluster — center
    for (int i = 0; i < 100; i++) {
      points.add(_ScatterPoint(
        x: 0.35 + rng.nextDouble() * 0.30,
        y: 0.35 + rng.nextDouble() * 0.30,
        type: _ObjectType.galaxy,
      ));
    }
    // Quasars cluster — bottom-right
    for (int i = 0; i < 60; i++) {
      points.add(_ScatterPoint(
        x: 0.55 + rng.nextDouble() * 0.30,
        y: 0.55 + rng.nextDouble() * 0.30,
        type: _ObjectType.quasar,
      ));
    }
    return points;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onHover(Offset local, Size size) {
    _ScatterPoint? closest;
    double minDist = 12;
    for (final p in _points) {
      final px = p.x * size.width;
      final py = p.y * size.height;
      final d = (local - Offset(px, py)).distance;
      if (d < minDist) {
        minDist = d;
        closest = p;
      }
    }
    if (closest != _hoveredPoint) setState(() => _hoveredPoint = closest);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Clustered Light Curves',
                        style: AppTextStyles.h2),
                    Text(
                      'PCA Dimensionality Reduction on Spectral Data',
                      style: AppTextStyles.bodySm,
                    ),
                  ],
                ),
                const Spacer(),
                _Legend(color: AppColors.accent, label: 'STARS'),
                const SizedBox(width: 14),
                _Legend(color: AppColors.warning, label: 'GALAXIES'),
                const SizedBox(width: 14),
                _Legend(color: AppColors.success, label: 'QUASARS'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Scatter plot
          Expanded(
            child: LayoutBuilder(builder: (_, c) {
              return MouseRegion(
                onHover: (e) => _onHover(e.localPosition, c.biggest),
                onExit: (_) => setState(() => _hoveredPoint = null),
                child: CustomPaint(
                  size: c.biggest,
                  painter: _ScatterPainter(
                    points: _points,
                    hovered: _hoveredPoint,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

enum _ObjectType { star, galaxy, quasar }

extension _ObjectTypeX on _ObjectType {
  Color get color => switch (this) {
        _ObjectType.star => AppColors.accent,
        _ObjectType.galaxy => AppColors.warning,
        _ObjectType.quasar => AppColors.success,
      };

  String get label => switch (this) {
        _ObjectType.star => 'STAR',
        _ObjectType.galaxy => 'GALAXY',
        _ObjectType.quasar => 'QUASAR',
      };
}

class _ScatterPoint {
  final double x;
  final double y;
  final _ObjectType type;

  const _ScatterPoint({required this.x, required this.y, required this.type});
}

class _ScatterPainter extends CustomPainter {
  const _ScatterPainter({required this.points, this.hovered});

  final List<_ScatterPoint> points;
  final _ScatterPoint? hovered;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in points) {
      final px = p.x * size.width;
      final py = p.y * size.height;
      final isHov = p == hovered;

      final paint = Paint()
        ..color = p.type.color.withOpacity(isHov ? 1.0 : 0.55)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(px, py), isHov ? 5 : 3, paint);
    }

    // Tooltip para hovered
    if (hovered != null) {
      final p = hovered!;
      final px = p.x * size.width;
      final py = p.y * size.height;

      final rng = math.Random(p.x.hashCode ^ p.y.hashCode);
      final objId =
          'J${(1200 + rng.nextInt(99)).toString().padLeft(4, '0')}+${(3211 + rng.nextInt(99))}';
      final conf = 95 + rng.nextInt(5);
      final z = (0.1 + rng.nextDouble() * 0.5).toStringAsFixed(3);

      _drawTooltip(
        canvas,
        size,
        Offset(px, py),
        objId: objId,
        confidence: conf,
        type: p.type.label,
        z: z,
        color: p.type.color,
      );
    }
  }

  void _drawTooltip(
    Canvas canvas,
    Size size,
    Offset anchor, {
    required String objId,
    required int confidence,
    required String type,
    required String z,
    required Color color,
  }) {
    const w = 160.0;
    const h = 64.0;
    const pad = 10.0;

    double dx = anchor.dx + 10;
    double dy = anchor.dy - h - 10;
    if (dx + w > size.width) dx = anchor.dx - w - 10;
    if (dy < 0) dy = anchor.dy + 10;

    final rect =
        RRect.fromRectAndRadius(Rect.fromLTWH(dx, dy, w, h), const Radius.circular(6));

    canvas.drawRRect(
      rect,
      Paint()..color = const Color(0xE6111827),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = color.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    _drawText(canvas, 'OBJECT ID: $objId',
        Offset(dx + pad, dy + pad), 10, const Color(0xFFE8EDF5));
    _drawText(canvas, 'Confidence: $confidence%',
        Offset(dx + pad, dy + pad + 14), 10, const Color(0xFF8A95A8));
    _drawText(canvas, type,
        Offset(dx + pad, dy + pad + 28), 10, color);
    _drawText(canvas, 'z = $z',
        Offset(dx + pad + 68, dy + pad + 28), 10, const Color(0xFF8A95A8));
  }

  void _drawText(Canvas canvas, String text, Offset offset, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_ScatterPainter old) => old.hovered != hovered;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            letterSpacing: 0.4,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confusion Matrix
// ─────────────────────────────────────────────────────────────────────────────

class _ConfusionMatrixCard extends StatelessWidget {
  const _ConfusionMatrixCard();

  static const _predictedLabels = [
    'PREDICTED\nSTAR',
    'PREDICTED\nGALAXY',
    'PREDICTED\nQUASAR',
  ];
  static const _actualLabels = [
    'ACTUAL\nSTAR',
    'ACTUAL\nGALAXY',
    'ACTUAL\nQUASAR',
  ];

  // [row][col]
  static const _matrix = [
    [1242, 12, 3],
    [8, 3104, 14],
    [2, 6, 842],
  ];

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
          Text(
            'CONFUSION MATRIX',
            style: AppTextStyles.labelSm.copyWith(
              letterSpacing: 1.0,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _MatrixGrid(
              predictedLabels: _predictedLabels,
              actualLabels: _actualLabels,
              matrix: _matrix,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatrixGrid extends StatelessWidget {
  const _MatrixGrid({
    required this.predictedLabels,
    required this.actualLabels,
    required this.matrix,
  });

  final List<String> predictedLabels;
  final List<String> actualLabels;
  final List<List<int>> matrix;

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w600,
      color: AppColors.accent,
      letterSpacing: 0.4,
    );
    const actualStyle = TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      letterSpacing: 0.3,
    );

    return Column(
      children: [
        // Header row (predicted labels)
        Row(
          children: [
            const SizedBox(width: 60), // espaço para actual labels
            ...predictedLabels.map(
              (l) => Expanded(
                child: Text(l,
                    style: headerStyle, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Data rows
        ...List.generate(matrix.length, (row) {
          return Expanded(
            child: Row(
              children: [
                // Actual label
                SizedBox(
                  width: 60,
                  child: Text(actualLabels[row],
                      style: actualStyle, textAlign: TextAlign.right),
                ),
                const SizedBox(width: 6),
                // Cells
                ...List.generate(matrix[row].length, (col) {
                  final value = matrix[row][col];
                  final isDiag = row == col;
                  return Expanded(
                    child: _MatrixCell(value: value, isDiagonal: isDiag),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _MatrixCell extends StatefulWidget {
  const _MatrixCell({required this.value, required this.isDiagonal});

  final int value;
  final bool isDiagonal;

  @override
  State<_MatrixCell> createState() => _MatrixCellState();
}

class _MatrixCellState extends State<_MatrixCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDiagonal
        ? AppColors.accent.withOpacity(_hovered ? 0.25 : 0.15)
        : AppColors.surface2.withOpacity(_hovered ? 0.8 : 0.5);
    final textColor = widget.isDiagonal
        ? AppColors.accent
        : AppColors.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: widget.isDiagonal
                ? AppColors.accent.withOpacity(0.3)
                : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            widget.value.toString(),
            style: TextStyle(
              fontSize: widget.isDiagonal ? 15 : 12,
              fontWeight: widget.isDiagonal
                  ? FontWeight.w700
                  : FontWeight.w400,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Interpretability
// ─────────────────────────────────────────────────────────────────────────────

class _AIInterpretabilityCard extends StatefulWidget {
  const _AIInterpretabilityCard();

  @override
  State<_AIInterpretabilityCard> createState() =>
      _AIInterpretabilityCardState();
}

class _AIInterpretabilityCardState extends State<_AIInterpretabilityCard> {
  bool _expanded = false;

  static const _features = [
    ('U-BAND', 0.82),
    ('G-BAND', 0.74),
    ('R-BAND', 0.61),
    ('I-BAND', 0.48),
    ('Z-BAND', 0.33),
    ('RA (DEG)', 0.12),
    ('DEC (DEG)', 0.08),
  ];

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
          // Header — clicável para expandir
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.build_outlined,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Text(
                    'AI INTERPRETABILITY',
                    style: AppTextStyles.labelMd.copyWith(
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          // Conteúdo expandível — feature importance
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(color: AppColors.border),
                        const SizedBox(height: 12),
                        Text(
                          'Feature Importance (SHAP values)',
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: 16),
                        ..._features.map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _FeatureBar(
                                  label: f.$1, value: f.$2),
                            )),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _FeatureBar extends StatelessWidget {
  const _FeatureBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: AppTextStyles.labelSm),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: AppColors.surface2,
              valueColor:
                  AlwaysStoppedAnimation(AppColors.accent.withOpacity(0.7)),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value.toStringAsFixed(2),
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
