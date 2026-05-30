import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novaml_app/core/models/api_models.dart';
import 'package:novaml_app/shared/providers/backend_provider.dart';

/// Notifier de modelos treinados — consome GET/DELETE /models.
class StoredModelsNotifier extends AsyncNotifier<List<StoredModel>> {
  @override
  Future<List<StoredModel>> build() => _fetch();

  Future<List<StoredModel>> _fetch() =>
      ref.read(apiClientProvider).getModels();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<StoredModel?> deleteModel(int id) async {
    try {
      final deleted = await ref.read(apiClientProvider).deleteModel(id);
      await refresh();
      return deleted;
    } catch (_) {
      await refresh();
      return null;
    }
  }

  Future<String?> exportModel(int id) async {
    try {
      return await ref.read(apiClientProvider).exportModel(id);
    } catch (_) {
      return null;
    }
  }
}

final storedModelsProvider =
    AsyncNotifierProvider<StoredModelsNotifier, List<StoredModel>>(
  StoredModelsNotifier.new,
);

/// Último modelo treinado — atualizado após cada treino.
final lastTrainedModelProvider = StateProvider<StoredModel?>((ref) => null);
