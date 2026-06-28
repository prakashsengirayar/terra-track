// lib/presentation/bloc/agri/agri_work_entry_provider.dart
//
// Riverpod providers for the AgriWorkEntry entity (distinct from the
// existing vehicle/customer WorkEntryEntity): a real-time list stream
// scoped by owner, and a form-submission notifier exposing AsyncValue<void>
// for add/update/delete.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/agri_entities.dart';
import 'agri_repository_providers.dart';

final agriWorkEntriesStreamProvider =
    StreamProvider.family<List<AgriWorkEntryEntity>, String>((ref, ownerId) {
  return ref.watch(agriWorkEntryRepositoryProvider).watchAll(ownerId);
});

class AgriWorkEntryFormNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AgriWorkEntryFormNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> addWorkEntry(AgriWorkEntryEntity entry) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(agriWorkEntryRepositoryProvider).addWorkEntry(entry);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateWorkEntry(AgriWorkEntryEntity entry) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(agriWorkEntryRepositoryProvider).updateWorkEntry(entry);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteWorkEntry(String id) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(agriWorkEntryRepositoryProvider).deleteWorkEntry(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final agriWorkEntryFormProvider = StateNotifierProvider.autoDispose<
    AgriWorkEntryFormNotifier, AsyncValue<void>>(
  (ref) => AgriWorkEntryFormNotifier(ref),
);
