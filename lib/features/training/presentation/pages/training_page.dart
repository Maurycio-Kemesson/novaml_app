import 'package:flutter/material.dart';
import 'package:novaml_app/shared/widgets/components/nova_empty_state.dart';
import 'package:novaml_app/shared/widgets/layout/page_container.dart';

/// Tela de configuração e execução de treinamento de modelos.
class TrainingPage extends StatelessWidget {
  const TrainingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      title: 'Treinamento',
      subtitle: 'Configure e treine modelos de Machine Learning.',
      child: const NovaEmptyState(
        icon: Icons.memory_outlined,
        title: 'Nenhum dataset carregado',
        subtitle:
            'Faça o upload de um arquivo CSV antes de configurar o treinamento.',
        actionLabel: 'Ir para Upload',
      ),
    );
  }
}
