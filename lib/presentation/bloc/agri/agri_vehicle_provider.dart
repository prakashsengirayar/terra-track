// lib/presentation/bloc/agri/agri_vehicle_provider.dart
//
// Riverpod providers for the AgriVehicleEntity: a real-time list stream
// scoped by owner, and a form-submission notifier exposing AsyncValue<void>
// for add/update/delete. Mirrors land_provider.dart / worker_provider.dart.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/agri_entities.dart';
import 'agri_repository_providers.dart';

/// Real-time list of an owner's vehicles. Parameterized by ownerId so
/// callers pass `ref.watch(agriVehiclesStreamProvider(uid))`, where `uid`
/// is typically read from `currentAgriUidProvider`.
final agriVehiclesStreamProvider =
    StreamProvider.family<List<AgriVehicleEntity>, String>((ref, ownerId) {
  return ref.watch(agriVehicleRepositoryProvider).watchAll(ownerId);
});

class AgriVehicleFormNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AgriVehicleFormNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> addVehicle(AgriVehicleEntity vehicle) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(agriVehicleRepositoryProvider).addVehicle(vehicle);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateVehicle(AgriVehicleEntity vehicle) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(agriVehicleRepositoryProvider).updateVehicle(vehicle);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteVehicle(String id) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(agriVehicleRepositoryProvider).deleteVehicle(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final agriVehicleFormProvider = StateNotifierProvider.autoDispose<
    AgriVehicleFormNotifier, AsyncValue<void>>(
  (ref) => AgriVehicleFormNotifier(ref),
);
