import 'package:flutter/material.dart';
import 'package:novaml_app/core/theme/app_theme.dart';
import 'package:novaml_app/shared/widgets/layout/app_shell.dart';

/// Raiz da aplicação NOVAML.
/// O ProviderScope é instanciado em main.dart para garantir
/// que o escopo Riverpod seja único durante todo o ciclo de vida.
class NovaMLApp extends StatelessWidget {
  const NovaMLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOVAML',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AppShell(),
    );
  }
}
