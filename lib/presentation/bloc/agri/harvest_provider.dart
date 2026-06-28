// lib/presentation/bloc/agri/harvest_provider.dart
//
// Riverpod providers for the Harvest entity: a real-time list stream
// scoped by owner, and a form-submission notifier exposing AsyncValue<void>
// for add/update/delete.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/agri_entities.dart';
import 'agri_repository_providers.dart';

final harvestsStreamProvider =
    StreamProvider.family<List<HarvestEntity>, String>((ref, ownerId) {
  return ref.watch(harvestRepositoryProvider).watchAll(ownerId);
});

class HarvestFormNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  HarvestFormNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> addHarvest(HarvestEntity harvest) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(harvestRepositoryProvider).addHarvest(harvest);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateHarvest(HarvestEntity harvest) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(harvestRepositoryProvider).updateHarvest(harvest);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteHarvest(String id) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(harvestRepositoryProvider).deleteHarvest(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final harvestFormProvider =
    StateNotifierProvider.autoDispose<HarvestFormNotifier, AsyncValue<void>>(
  (ref) => HarvestFormNotifier(ref),
);
