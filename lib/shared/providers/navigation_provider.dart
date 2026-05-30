import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Seções de navegação disponíveis na sidebar.
/// Cada valor corresponde a um índice no IndexedStack do AppShell.
enum NavSection {
  projects,   // 0
  models,     // 1
  dashboard,  // 2
  monitoring, // 3
}

extension NavSectionX on NavSection {
  String get label => switch (this) {
        NavSection.projects   => 'Projetos',
        NavSection.models     => 'Modelos',
        NavSection.dashboard  => 'Dashboard',
        NavSection.monitoring => 'Monitoramento',
      };

  String get iconAsset => switch (this) {
        NavSection.projects   => 'folder',
        NavSection.models     => 'layers',
        NavSection.dashboard  => 'bar_chart_2',
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

/// Trigger para abrir o dialog de criar projeto a partir do header.
/// Qualquer widget pode incrementar para disparar o dialog na ProjectsPage.
final createProjectTriggerProvider = StateProvider<int>((ref) => 0);

/// Query de busca global — compartilhado entre o header e a ProjectsPage.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Fluxo principal da aplicação.
enum AppFlowState {
  projects,   // Tela inicial de projetos
  workspace,  // Configuração do workspace
  training,   // Loading/treino em andamento
  results,    // Dashboard de resultados
}

final appFlowProvider =
    StateProvider<AppFlowState>((ref) => AppFlowState.projects);
