import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novaml_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:novaml_app/features/models/presentation/pages/models_page.dart';
import 'package:novaml_app/features/monitoring/presentation/pages/monitoring_page.dart';
import 'package:novaml_app/features/projects/presentation/pages/projects_page.dart';
import 'package:novaml_app/features/results/presentation/pages/dashboard_results_page.dart';
import 'package:novaml_app/features/results/presentation/pages/training_loading_page.dart';
import 'package:novaml_app/features/workspace/presentation/pages/workspace_page.dart';
import 'package:novaml_app/shared/providers/navigation_provider.dart';
import 'nova_top_bar.dart';

/// Shell principal — IndexedStack alinhado 1:1 com NavSection.values:
///   0 → projects   → ProjectsPage
///   1 → models     → ModelsPage
///   2 → dashboard  → DashboardPage
///   3 → monitoring → MonitoringPage
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(appFlowProvider);
    final section = ref.watch(navigationProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const NovaTopBar(),
          Expanded(
            child: switch (flow) {
              AppFlowState.projects => SizedBox.expand(
                  child: IndexedStack(
                    index: NavSection.values.indexOf(section),
                    sizing: StackFit.expand,
                    children: const [
                      ProjectsPage(),   // 0 — projects
                      ModelsPage(),     // 1 — models
                      DashboardPage(),  // 2 — dashboard
                      MonitoringPage(), // 3 — monitoring
                    ],
                  ),
                ),
              AppFlowState.workspace => const WorkspacePage(),
              AppFlowState.training  => const TrainingLoadingPage(),
              AppFlowState.results   => const DashboardResultsPage(),
            },
          ),
        ],
      ),
    );
  }
}
