import 'package:flutter/material.dart';
import 'package:novaml_app/shared/widgets/components/nova_button.dart';
import 'package:novaml_app/shared/widgets/components/nova_empty_state.dart';
import 'package:novaml_app/shared/widgets/layout/page_container.dart';

/// Tela de listagem e gerenciamento de modelos treinados.
class ModelsPage extends StatelessWidget {
  const ModelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      title: 'Modelos',
      subtitle: 'Modelos treinados salvos localmente (.pkl).',
      headerActions: [
        NovaButton(
          label: 'Importar .pkl',
          variant: NovaButtonVariant.secondary,
          onPressed: () {},
          leading: const Icon(Icons.upload_outlined),
        ),
      ],
      child: const NovaEmptyState(
        icon: Icons.layers_outlined,
        title: 'Nenhum modelo treinado',
        subtitle: 'Treine um modelo para vê-lo listado aqui.',
        actionLabel: 'Ir para Treinamento',
      ),
    );
  }
}
