import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';
import 'package:novaml_app/shared/providers/navigation_provider.dart';

/// Tela de loading durante o treino do modelo.
/// Simula estágios de treinamento com progresso animado.
/// Ao concluir, navega automaticamente para o DashboardResultsPage.
class TrainingLoadingPage extends ConsumerStatefulWidget {
  const TrainingLoadingPage({super.key});

  @override
  ConsumerState<TrainingLoadingPage> createState() =>
      _TrainingLoadingPageState();
}

class _TrainingLoadingPageState extends ConsumerState<TrainingLoadingPage>
    with TickerProviderStateMixin {
  // ── Estágios de treinamento ───────────────────────────────────────────────
  static const _stages = [
    (label: 'Initializing model architecture...', duration: 800),
    (label: 'Loading and validating dataset...', duration: 900),
    (label: 'Preprocessing spectral features...', duration: 700),
    (label: 'Splitting train / test sets...', duration: 500),
    (label: 'Training epoch 1 / 10...', duration: 600),
    (label: 'Training epoch 3 / 10...', duration: 600),
    (label: 'Training epoch 6 / 10...', duration: 700),
    (label: 'Training epoch 10 / 10...', duration: 800),
    (label: 'Evaluating on validation set...', duration: 600),
    (label: 'Computing confusion matrix...', duration: 500),
    (label: 'Generating classification report...', duration: 500),
    (label: 'Training complete ✓', duration: 600),
  ];

  int _currentStage = 0;
  double _progress = 0.0;
  final List<String> _completedLogs = [];
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulse = Tween(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _runNextStage();
  }

  void _runNextStage() {
    if (_currentStage >= _stages.length) {
      // Concluído → navega para resultados após breve pausa
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          ref.read(appFlowProvider.notifier).state = AppFlowState.results;
        }
      });
      return;
    }

    final stage = _stages[_currentStage];
    final targetProgress =
        (_currentStage + 1) / _stages.length;

    _timer = Timer(Duration(milliseconds: stage.duration), () {
      if (!mounted) return;
      setState(() {
        _completedLogs.add(stage.label);
        _progress = targetProgress;
        _currentStage++;
      });
      _runNextStage();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _currentStage >= _stages.length;
    final currentLabel = isDone
        ? 'Training complete ✓'
        : _stages[_currentStage < _stages.length
                ? _currentStage
                : _stages.length - 1]
            .label;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Logo / título ─────────────────────────────────────────────
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => Opacity(
                      opacity: isDone ? 1.0 : _pulse.value,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.accent, AppColors.galaxy],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.4),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Icon(
                          isDone
                              ? Icons.check_rounded
                              : Icons.memory_rounded,
                          color: Colors.black,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDone
                            ? 'Training Complete'
                            : 'Neural Training',
                        style: AppTextStyles.h1,
                      ),
                      Text(
                        isDone
                            ? 'Model ready for classification'
                            : 'XGBoost Regressor · Spectral Dataset',
                        style: AppTextStyles.bodySm,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // ── Barra de progresso principal ──────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PROGRESS',
                          style: AppTextStyles.labelSm.copyWith(
                              letterSpacing: 0.8,
                              color: AppColors.textDisabled)),
                      Text(
                        '${(_progress * 100).round()}%',
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 6,
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: AppColors.surface2,
                        valueColor: AlwaysStoppedAnimation(
                          isDone ? AppColors.success : AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      currentLabel,
                      key: ValueKey(currentLabel),
                      style: AppTextStyles.bodyMd.copyWith(
                        color: isDone
                            ? AppColors.success
                            : AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Log de estágios ───────────────────────────────────────────
              Container(
                height: 240,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final log in _completedLogs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 13,
                                color: AppColors.success.withOpacity(0.7),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                log,
                                style: AppTextStyles.code.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!isDone)
                        AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, __) => Opacity(
                            opacity: _pulse.value,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.arrow_right_rounded,
                                  size: 13,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  currentLabel,
                                  style: AppTextStyles.code.copyWith(
                                    color: AppColors.accent,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
