import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novaml_app/core/models/api_models.dart';
import 'package:novaml_app/core/services/api_client.dart';
import 'package:novaml_app/core/theme/app_colors.dart';
import 'package:novaml_app/core/theme/app_spacing.dart';
import 'package:novaml_app/core/theme/app_text_styles.dart';
import 'package:novaml_app/shared/providers/backend_provider.dart';
import 'package:novaml_app/shared/providers/models_provider.dart';
import 'package:novaml_app/shared/providers/navigation_provider.dart';
import 'package:novaml_app/shared/providers/projects_provider.dart';

/// Tela de treino — chama POST /train no backend real e exibe progresso.
class TrainingLoadingPage extends ConsumerStatefulWidget {
  const TrainingLoadingPage({super.key});

  @override
  ConsumerState<TrainingLoadingPage> createState() =>
      _TrainingLoadingPageState();
}

class _TrainingLoadingPageState extends ConsumerState<TrainingLoadingPage>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  final List<String> _logs = [];
  bool _done = false;
  bool _error = false;
  String _errorMsg = '';
  double _progress = 0.0;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _runTraining());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────

  void _log(String msg) {
    if (!mounted) return;
    setState(() => _logs.add(msg));
  }

  void _setProgress(double v) {
    if (!mounted) return;
    setState(() => _progress = v);
  }

  /// Aguarda o backend ficar online com polling, timeout de 40s.
  Future<bool> _waitForBackend() async {
    _log('Verificando disponibilidade do backend...');
    final client = ref.read(apiClientProvider);
    final deadline = DateTime.now().add(const Duration(seconds: 40));

    while (DateTime.now().isBefore(deadline)) {
      final ok = await client.healthCheck();
      if (ok) {
        _log('Backend online — prosseguindo.');
        return true;
      }
      _log('Backend ainda não disponível, aguardando...');
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    return false;
  }

  Future<void> _runTraining() async {
    final project = ref.read(selectedProjectProvider);
    if (project == null) {
      _failWith('Nenhum projeto selecionado.');
      return;
    }

    // ── Validações ──────────────────────────────────────────────────────────
    if (project.csvPath == null) {
      _failWith('Nenhum arquivo CSV associado ao projeto.');
      return;
    }
    if (project.targetColumn == null) {
      _failWith(
          'Nenhuma coluna TRGT selecionada. Volte ao workspace e selecione a coluna alvo.');
      return;
    }

    _log('Iniciando pipeline de treinamento...');
    _setProgress(0.03);

    // ── Aguarda backend ─────────────────────────────────────────────────────
    final backendReady = await _waitForBackend();
    if (!backendReady) {
      _failWith(
          'Backend Python não respondeu em 40s. Verifique se o venv está '
          'configurado e os requirements instalados.');
      return;
    }
    _setProgress(0.05);

    // ── Monta a requisição ──────────────────────────────────────────────────
    // Mapeia algoritmo Flutter → tipo da API
    final modelType = _mapAlgorithm(project.algorithm.name);
    _log('Algoritmo: ${modelType.label}');
    _setProgress(0.10);

    // Feature names: USE columns sem a target
    List<String>? featureNames;
    if (project.useColumnsJson != null) {
      final allUse = List<String>.from(
          (jsonDecode(project.useColumnsJson!) as List));
      featureNames = allUse
          .where((n) => n != project.targetColumn)
          .toList();
      if (featureNames.isEmpty) featureNames = null;
    }

    final testSize = (1 - project.trainSplit).clamp(0.05, 0.49);
    _log('Target: ${project.targetColumn}');
    _log('Features: ${featureNames?.length ?? "todas"} colunas');
    _log('Test size: ${(testSize * 100).toStringAsFixed(0)}%');
    _setProgress(0.20);

    final request = TrainRequest(
      modelType:        modelType,
      datasetFilePath:  project.csvPath!,
      targetName:       project.targetColumn!,
      featureNames:     featureNames,
      testSize:         testSize,
    );

    // ── Chama o backend ─────────────────────────────────────────────────────
    _log('Enviando requisição para POST /train...');
    _setProgress(0.30);

    try {
      final client = ref.read(apiClientProvider);
      _log('Aguardando resposta do backend (pode levar alguns segundos)...');
      _log('Dica: colunas com texto (ex: gênero, categoria) devem ser '
          'excluídas — scikit-learn só processa valores numéricos.');
      _setProgress(0.50);

      final model = await client.train(request);

      _setProgress(0.85);
      _log('Treinamento concluído!');
      _log('Model ID: ${model.id}');
      _log('Task: ${model.task.value}');
      _log('Score: ${model.scoreLabel}');
      _setProgress(1.0);

      // Salva o modelo treinado no provider
      ref.read(lastTrainedModelProvider.notifier).state = model;
      ref.read(storedModelsProvider.notifier).refresh();

      if (mounted) {
        setState(() => _done = true);
        _pulseCtrl.stop();
        _pulseCtrl.value = 1.0;

        await Future<void>.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          ref.read(appFlowProvider.notifier).state = AppFlowState.results;
        }
      }
    } catch (e) {
      final detail = NovaMLApiClient.extractError(e);
      final isCategorical = detail.toLowerCase().contains('convert') ||
          detail.toLowerCase().contains('float') ||
          detail.toLowerCase().contains('string');
      if (isCategorical) {
        _failWith(
          'O backend não conseguiu processar colunas de texto.\n\n'
          'Detalhe: $detail\n\n'
          'Solução: no workspace, desmarque (USE) as colunas que contêm '
          'texto ou categorias (ex: gênero, espécie, classe).',
        );
      } else {
        _failWith('Erro do backend: $detail');
      }
    }
  }

  void _failWith(String msg) {
    if (!mounted) return;
    setState(() {
      _error = true;
      _errorMsg = msg;
    });
    _log('ERRO: $msg');
  }

  /// Mapeia ProjectAlgorithm → ApiModelType (1:1 com os ModelType da API).
  ApiModelType _mapAlgorithm(String algorithmName) => switch (algorithmName) {
        'linearRegression' => ApiModelType.linearRegression,
        'decisionTree'     => ApiModelType.decisionTree,
        _ => throw StateError(
            'Algoritmo "$algorithmName" não é suportado pela API. '
            'Valores válidos: linearRegression, decisionTree.',
          ),
      };

  // ─────────────────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => Opacity(
                      opacity: (_done || _error) ? 1.0 : _pulse.value,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _error
                                ? [AppColors.error, AppColors.error]
                                : [AppColors.accent, AppColors.galaxy],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: (_error
                                      ? AppColors.error
                                      : AppColors.accent)
                                  .withOpacity(0.4),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Icon(
                          _error
                              ? Icons.error_outline_rounded
                              : _done
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
                        _error
                            ? 'Falha no Treinamento'
                            : _done
                                ? 'Treinamento Concluído'
                                : 'Neural Training',
                        style: AppTextStyles.h1,
                      ),
                      Text(
                        _error
                            ? 'Verifique os logs abaixo'
                            : _done
                                ? 'Modelo pronto para inferência'
                                : 'Comunicando com o backend Python...',
                        style: AppTextStyles.bodySm,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // ── Progress bar ─────────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PROGRESSO',
                          style: AppTextStyles.labelSm.copyWith(
                              letterSpacing: 0.8,
                              color: AppColors.textDisabled)),
                      Text(
                        '${(_progress * 100).round()}%',
                        style: AppTextStyles.labelMd.copyWith(
                          color: _error
                              ? AppColors.error
                              : AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: 6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: AppColors.surface2,
                        valueColor: AlwaysStoppedAnimation(
                          _error
                              ? AppColors.error
                              : _done
                                  ? AppColors.success
                                  : AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Log terminal ─────────────────────────────────────────────
              Container(
                height: 220,
                padding: const EdgeInsets.all(14),
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
                      for (final log in _logs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                log.startsWith('ERRO')
                                    ? Icons.error_outline_rounded
                                    : Icons.arrow_right_rounded,
                                size: 13,
                                color: log.startsWith('ERRO')
                                    ? AppColors.error
                                    : AppColors.accent,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  log,
                                  style: AppTextStyles.code.copyWith(
                                    fontSize: 11,
                                    color: log.startsWith('ERRO')
                                        ? AppColors.error
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Botão retry em caso de erro ───────────────────────────────
              if (_error) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    _TrainingButton(
                      label: 'Voltar ao Workspace',
                      icon: Icons.arrow_back_rounded,
                      primary: false,
                      onTap: () => ref
                          .read(appFlowProvider.notifier)
                          .state = AppFlowState.workspace,
                    ),
                    const SizedBox(width: 12),
                    _TrainingButton(
                      label: 'Tentar Novamente',
                      icon: Icons.refresh_rounded,
                      onTap: () {
                        setState(() {
                          _error = false;
                          _errorMsg = '';
                          _progress = 0;
                          _logs.clear();
                          _done = false;
                        });
                        _pulseCtrl.repeat(reverse: true);
                        _runTraining();
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingButton extends StatefulWidget {
  const _TrainingButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  State<_TrainingButton> createState() => _TrainingButtonState();
}

class _TrainingButtonState extends State<_TrainingButton> {
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
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: widget.primary
                ? (_hovered ? AppColors.accentHover : AppColors.accent)
                : AppColors.surface2,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: widget.primary
                ? null
                : Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon,
                  size: 15,
                  color: widget.primary
                      ? Colors.black
                      : AppColors.textSecondary),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: AppTextStyles.labelMd.copyWith(
                  color: widget.primary
                      ? Colors.black
                      : AppColors.textSecondary,
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
