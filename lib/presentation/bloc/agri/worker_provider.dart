// lib/presentation/bloc/agri/worker_provider.dart
//
// Riverpod providers for the Worker entity: a real-time list stream scoped
// by owner, and a form-submission notifier exposing AsyncValue<void> for
// add/update/delete.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/agri_entities.dart';
import 'agri_repository_providers.dart';

final workersStreamProvider =
    StreamProvider.family<List<WorkerEntity>, String>((ref, ownerId) {
  return ref.watch(workerRepositoryProvider).watchAll(ownerId);
});

class WorkerFormNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  WorkerFormNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> addWorker(WorkerEntity worker) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(workerRepositoryProvider).addWorker(worker);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateWorker(WorkerEntity worker) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(workerRepositoryProvider).updateWorker(worker);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteWorker(String id) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(workerRepositoryProvider).deleteWorker(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final workerFormProvider =
    StateNotifierProvider.autoDispose<WorkerFormNotifier, AsyncValue<void>>(
  (ref) => WorkerFormNotifier(ref),
);
