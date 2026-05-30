import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novaml_app/features/projects/data/repositories/project_repository.dart';
import 'package:novaml_app/features/projects/domain/models/project_model.dart';

// ─── Repository provider ──────────────────────────────────────────────────────

final projectRepositoryProvider = Provider<ProjectRepository>(
  (_) => ProjectRepository(),
);

// ─── Projects notifier ───────────────────────────────────────────────────────

class ProjectsNotifier extends AsyncNotifier<List<Project>> {
  ProjectRepository get _repo => ref.read(projectRepositoryProvider);

  @override
  Future<List<Project>> build() => _repo.getAll();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.getAll);
  }

  Future<Project> create({
    required String name,
    String? description,
    required ProjectAlgorithm algorithm,
  }) async {
    final project = await _repo.create(Project(
      name:        name,
      description: description,
      algorithm:   algorithm,
      createdAt:   DateTime.now(),
      updatedAt:   DateTime.now(),
    ));
    await refresh();
    return project;
  }

  Future<void> save(Project project) async {
    await _repo.update(project);
    await refresh();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await refresh();
  }

  Future<void> updateStatus(int id, ProjectStatus status) async {
    await _repo.updateStatus(id, status);
    await refresh();
  }

  // Busca local em memória (sem refetch ao BD)
  List<Project> filter(String query) {
    final all = state.valueOrNull ?? [];
    if (query.trim().isEmpty) return all;
    final q = query.toLowerCase();
    return all.where((p) =>
        p.name.toLowerCase().contains(q) ||
        (p.description?.toLowerCase().contains(q) ?? false)).toList();
  }
}

final projectsProvider =
    AsyncNotifierProvider<ProjectsNotifier, List<Project>>(
  ProjectsNotifier.new,
);

// Provider de projeto selecionado (para abrir no workspace)
final selectedProjectProvider = StateProvider<Project?>((ref) => null);
