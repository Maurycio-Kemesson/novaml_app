import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novaml_app/core/services/system_info_service.dart';

/// Stream de dados do sistema com atualização a cada 3 segundos.
/// Usa um único processo PowerShell por ciclo para minimizar overhead.
final systemInfoProvider = StreamProvider<SystemInfo>((ref) async* {
  // Fetch imediato ao montar
  yield await SystemInfoService.fetch();

  // Polling a cada 3 segundos
  while (true) {
    await Future<void>.delayed(const Duration(seconds: 3));
    yield await SystemInfoService.fetch();
  }
});
