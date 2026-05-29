import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Seções de navegação disponíveis na sidebar.
enum NavSection {
  projects,
  upload,
  training,
  models,
  dashboard,
  assistant,
  monitoring,
}

extension NavSectionX on NavSection {
  String get label => switch (this) {
        NavSection.projects => 'Projetos',
        NavSection.upload => 'Upload CSV',
        NavSection.training => 'Treinamento',
        NavSection.models => 'Modelos',
        NavSection.dashboard => 'Dashboard',
        NavSection.assistant => 'Assistente IA',
        NavSection.monitoring => 'Monitoramento',
      };

  String get iconAsset => switch (this) {
        NavSection.projects => 'folder',
        NavSection.upload => 'upload_cloud',
        NavSection.training => 'cpu',
        NavSection.models => 'layers',
        NavSection.dashboard => 'bar_chart_2',
        NavSection.assistant => 'bot',
        NavSection.monitoring => 'activity',
      };
}

/// Provider de navegação global — controla qual seção está ativa.
final navigationProvider =
    StateProvider<NavSection>((ref) => NavSection.projects);

/// Provider para colapso da sidebar.
final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

/// Controla se a WorkspacePage está aberta (criando/editando um projeto).
final workspaceOpenProvider = StateProvider<bool>((ref) => false);

/// Fluxo principal da aplicação.
enum AppFlowState {
  projects,   // Tela inicial de projetos
  workspace,  // Configuração do workspace
  training,   // Loading/treino em andamento
  results,    // Dashboard de resultados
}

final appFlowProvider =
    StateProvider<AppFlowState>((ref) => AppFlowState.projects);
