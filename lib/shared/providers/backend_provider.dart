import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novaml_app/core/models/api_models.dart';
import 'package:novaml_app/core/services/api_client.dart';
import 'package:novaml_app/core/services/backend_launcher.dart';

// ── API client singleton ─────────────────────────────────────────────────────

final apiClientProvider = Provider<NovaMLApiClient>(
  (_) => NovaMLApiClient(),
);

// ── Backend status (poll a cada 3s) ─────────────────────────────────────────

/// Estado do backend: online | starting | offline
/// Mapeado de BackendState + health check HTTP.
enum BackendOnlineStatus { online, starting, offline }

final backendStatusProvider =
    StreamProvider<BackendOnlineStatus>((ref) async* {
  final client = ref.read(apiClientProvider);

  // Emite o estado do processo imediatamente
  BackendOnlineStatus _fromState(BackendState s) => switch (s) {
        BackendState.running  => BackendOnlineStatus.online,
        BackendState.starting => BackendOnlineStatus.starting,
        BackendState.stopped  => BackendOnlineStatus.offline,
        BackendState.error    => BackendOnlineStatus.offline,
      };

  while (true) {
    final launcher = BackendLauncher.instance;
    if (launcher.state == BackendState.running) {
      final ok = await client.healthCheck();
      yield ok ? BackendOnlineStatus.online : BackendOnlineStatus.starting;
    } else {
      yield _fromState(launcher.state);
    }
    await Future<void>.delayed(const Duration(seconds: 3));
  }
});

// ── Logs do processo Python em tempo real ────────────────────────────────────

/// Accumula os logs do BackendLauncher e os expõe como lista imutável.
class BackendLogsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    // Seed com logs já existentes no momento da criação
    final initial = List<String>.from(BackendLauncher.instance.logs);

    // Assina o stream para novos logs
    BackendLauncher.instance.logStream.listen((line) {
      state = [...state, line];
      if (state.length > 500) state = state.sublist(state.length - 500);
    });

    return initial;
  }

  void clear() => state = [];
}

final backendLogsProvider =
    NotifierProvider<BackendLogsNotifier, List<String>>(
  BackendLogsNotifier.new,
);

// ── Model types disponíveis no backend ──────────────────────────────────────

final modelTypesProvider = FutureProvider<List<ApiModelType>>((ref) async {
  final status = await ref.watch(backendStatusProvider.future);
  if (status != BackendOnlineStatus.online) return ApiModelType.values;
  return ref.read(apiClientProvider).getModelTypes();
});
