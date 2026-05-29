import 'package:flutter/material.dart';
import 'package:novaml_app/shared/widgets/components/nova_empty_state.dart';
import 'package:novaml_app/shared/widgets/layout/page_container.dart';

/// Dashboard de resultados — métricas, gráficos e classificações.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      title: 'Dashboard',
      subtitle: 'Métricas, gráficos e classificações de objetos celestes.',
      child: const NovaEmptyState(
        icon: Icons.bar_chart_outlined,
        title: 'Nenhum resultado ainda',
        subtitle:
            'Execute um modelo para visualizar métricas e classificações de estrelas, galáxias e quasares.',
        actionLabel: 'Ir para Modelos',
      ),
    );
  }
}
