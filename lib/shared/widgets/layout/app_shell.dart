import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novaml_app/features/assistant/presentation/pages/assistant_page.dart';
import 'package:novaml_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:novaml_app/features/models/presentation/pages/models_page.dart';
import 'package:novaml_app/features/monitoring/presentation/pages/monitoring_page.dart';
import 'package:novaml_app/features/projects/presentation/pages/projects_page.dart';
import 'package:novaml_app/features/results/presentation/pages/dashboard_results_page.dart';
import 'package:novaml_app/features/results/presentation/pages/training_loading_page.dart';
import 'package:novaml_app/features/training/presentation/pages/training_page.dart';
import 'package:novaml_app/features/upload/presentation/pages/upload_page.dart';
import 'package:novaml_app/features/workspace/presentation/pages/workspace_page.dart';
import 'package:novaml_app/shared/providers/navigation_provider.dart';
import 'nova_top_bar.dart';

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
                      ProjectsPage(),
                      UploadPage(),
                      TrainingPage(),
                      ModelsPage(),
                      DashboardPage(),
                      AssistantPage(),
                      MonitoringPage(),
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
