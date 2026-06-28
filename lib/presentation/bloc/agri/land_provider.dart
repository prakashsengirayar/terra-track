// lib/presentation/bloc/agri/land_provider.dart
//
// Riverpod providers for the Land entity: a real-time list stream scoped
// by owner, and a form-submission notifier exposing AsyncValue<void> for
// add/update/delete.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/agri_entities.dart';
import 'agri_repository_providers.dart';

/// Real-time list of an owner's lands. Parameterized by ownerId so callers
/// pass `ref.watch(landsStreamProvider(uid))`, where `uid` is typically
/// read from `currentAgriUidProvider`.
final landsStreamProvider =
    StreamProvider.family<List<LandEntity>, String>((ref, ownerId) {
  return ref.watch(landRepositoryProvider).watchAll(ownerId);
});

class LandFormNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  LandFormNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> addLand(LandEntity land) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(landRepositoryProvider).addLand(land);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateLand(LandEntity land) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(landRepositoryProvider).updateLand(land);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteLand(String id) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(landRepositoryProvider).deleteLand(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final landFormProvider =
    StateNotifierProvider.autoDispose<LandFormNotifier, AsyncValue<void>>(
  (ref) => LandFormNotifier(ref),
);
