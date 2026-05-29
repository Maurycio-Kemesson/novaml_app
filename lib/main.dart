import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuração da janela desktop Windows
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1400, 900),
    minimumSize: Size(1024, 700),
    center: true,
    title: 'NOVAML — No-Code Visual Astronomical Machine Learning',
    backgroundColor: Color(0xFF0A0D14),
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: NovaMLApp()));
}
