import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/entities.dart';
import '../providers.dart';

// --- Vehicle List State ---
class VehicleListState {
  final bool isLoading;
  final List<VehicleEntity> vehicles;
  final String? error;

  const VehicleListState({
    this.isLoading = false,
    this.vehicles = const [],
    this.error,
  });

  VehicleListState copyWith({
    bool? isLoading,
    List<VehicleEntity>? vehicles,
    String? error,
  }) =>
      VehicleListState(
        isLoading: isLoading ?? this.isLoading,
        vehicles: vehicles ?? this.vehicles,
        error: error,
      );
}

class VehicleListNotifier extends StateNotifier<VehicleListState> {
  final Ref _ref;

  VehicleListNotifier(this._ref) : super(const VehicleListState()) {
    load();
  }

  Future<void> load({bool includeInactive = true}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = includeInactive
        ? await _ref.read(getAllVehiclesIncludingInactiveUseCaseProvider).call()
        : await _ref.read(getAllVehiclesUseCaseProvider).call();
    
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (list) => state = state.copyWith(isLoading: false, vehicles: list),
    );
  }

  Future<bool> addVehicle({
    required String vehicleNumber,
    required String vehicleName,
    required String driverName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final vehicle = VehicleEntity(
      id: '',
      vehicleNumber: vehicleNumber.trim(),
      vehicleName: vehicleName.trim(),
      driverName: driverName.trim(),
      isActive: true,
      createdAt: DateTime.now(),
    );
    final result = await _ref.read(createVehicleUseCaseProvider).call(vehicle);
    bool success = false;
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (v) {
        success = true;
        state = state.copyWith(
          isLoading: false,
          vehicles: [...state.vehicles, v],
        );
      },
    );
    return success;
  }

  Future<bool> updateVehicle({
    required String id,
    required String vehicleNumber,
    required String vehicleName,
    required String driverName,
    required bool isActive,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final vehicle = VehicleEntity(
      id: id,
      vehicleNumber: vehicleNumber.trim(),
      vehicleName: vehicleName.trim(),
      driverName: driverName.trim(),
      isActive: isActive,
      createdAt: DateTime.now(),
    );
    final result = await _ref.read(updateVehicleUseCaseProvider).call(vehicle);
    bool success = false;
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (v) {
        success = true;
        final updatedList = state.vehicles.map((vehicle) {
          return vehicle.id == id ? v : vehicle;
        }).toList();
        state = state.copyWith(
          isLoading: false,
          vehicles: updatedList,
        );
      },
    );
    return success;
  }

  Future<bool> deleteVehicle(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _ref.read(deleteVehicleUseCaseProvider).call(id);
    bool success = false;
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (ok) {
        success = ok;
        state = state.copyWith(
          isLoading: false,
          vehicles: state.vehicles.where((v) => v.id != id).toList(),
        );
      },
    );
    return success;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final vehicleListProvider =
    StateNotifierProvider<VehicleListNotifier, VehicleListState>(
  (ref) => VehicleListNotifier(ref),
);

// --- Vehicle Form State ---
class VehicleFormState {
  final bool isLoading;
  final bool isSaved;
  final String? error;

  const VehicleFormState({
    this.isLoading = false,
    this.isSaved = false,
    this.error,
  });

  VehicleFormState copyWith({
    bool? isLoading,
    bool? isSaved,
    String? error,
  }) =>
      VehicleFormState(
        isLoading: isLoading ?? this.isLoading,
        isSaved: isSaved ?? this.isSaved,
        error: error,
      );
}

class VehicleFormNotifier extends StateNotifier<VehicleFormState> {
  final Ref _ref;

  VehicleFormNotifier(this._ref) : super(const VehicleFormState());

  Future<bool> submitVehicle({
    String? id,
    required String vehicleNumber,
    required String vehicleName,
    required String driverName,
    bool isActive = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    bool success = false;
    if (id == null || id.isEmpty) {
      // Create new vehicle
      success = await _ref.read(vehicleListProvider.notifier).addVehicle(
            vehicleNumber: vehicleNumber,
            vehicleName: vehicleName,
            driverName: driverName,
          );
    } else {
      // Update existing vehicle
      success = await _ref
          .read(vehicleListProvider.notifier)
          .updateVehicle(
            id: id,
            vehicleNumber: vehicleNumber,
            vehicleName: vehicleName,
            driverName: driverName,
            isActive: isActive,
          );
    }

    if (success) {
      state = const VehicleFormState(isSaved: true);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save vehicle',
      );
    }
    
    return success;
  }

  void reset() {
    state = const VehicleFormState();
  }
}

final vehicleFormProvider =
    StateNotifierProvider.autoDispose<VehicleFormNotifier, VehicleFormState>(
  (ref) => VehicleFormNotifier(ref),
);
