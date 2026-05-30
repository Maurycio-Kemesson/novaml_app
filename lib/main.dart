import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'app/app.dart';
import 'core/database/app_database.dart';
import 'core/services/backend_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── SQLite FFI para Windows/Linux ────────────────────────────────────────
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // ── Banco de dados local ─────────────────────────────────────────────────
  await AppDatabase.instance.database;

  // ── Inicia o backend Python em background ───────────────────────────────
  // Não bloqueia a UI — o StatusDot mostra "iniciando" até ficar pronto
  BackendLauncher.instance.start();

  // ── Janela desktop ───────────────────────────────────────────────────────
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
    await windowManager.maximize(); // ocupa a tela toda, barra do Windows visivel
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: NovaMLApp()));
}
