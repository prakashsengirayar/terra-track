import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/entities.dart';
import '../providers.dart';

class DashboardState {
  final bool isLoading;
  final DashboardSummaryEntity? summary;
  final String? error;

  const DashboardState({
    this.isLoading = false,
    this.summary,
    this.error,
  });

  DashboardState copyWith({
    bool? isLoading,
    DashboardSummaryEntity? summary,
    String? error,
  }) =>
      DashboardState(
        isLoading: isLoading ?? this.isLoading,
        summary: summary ?? this.summary,
        error: error,
      );
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final Ref _ref;

  DashboardNotifier(this._ref) : super(const DashboardState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _ref.read(getDashboardUseCaseProvider).call();
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (summary) => state = state.copyWith(isLoading: false, summary: summary),
    );
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>(
  (ref) => DashboardNotifier(ref),
);

// --- Admin Entry Form ---
class AdminEntryFormState {
  final bool isLoading;
  final bool isSaved;
  final String? error;

  const AdminEntryFormState({
    this.isLoading = false,
    this.isSaved = false,
    this.error,
  });
}

class AdminEntryFormNotifier extends StateNotifier<AdminEntryFormState> {
  final Ref _ref;

  AdminEntryFormNotifier(this._ref) : super(const AdminEntryFormState());

  Future<bool> submitEntry({
    required String vehicleId,
    required String vehicleName,
    required AdminEntryType entryType,
    required double amount,
    String? note,
    required DateTime date,
    String? messageText,
  }) async {
    state = const AdminEntryFormState(isLoading: true);

    final entry = AdminEntryEntity(
      id: '',
      vehicleId: vehicleId,
      vehicleName: vehicleName,
      entryType: entryType,
      amount: amount,
      note: note,
      date: date,
      createdBy: 'admin',
      createdAt: DateTime.now(),
    );

    final result =
        await _ref.read(createAdminEntryUseCaseProvider).call(entry);

    bool entryOk = false;
    result.fold(
      (f) => state = AdminEntryFormState(error: f.message),
      (_) => entryOk = true,
    );

    if (!entryOk) return false;

    // Send message if provided
    if (messageText != null && messageText.isNotEmpty) {
      final msg = MessageEntity(
        id: '',
        vehicleId: vehicleId,
        vehicleName: vehicleName,
        messageText: messageText,
        sentAt: DateTime.now(),
        sentBy: 'admin',
        isRead: false,
      );
      await _ref.read(sendMessageUseCaseProvider).call(msg);
    }

    // Refresh dashboard
    _ref.read(dashboardProvider.notifier).load();

    state = const AdminEntryFormState(isSaved: true);
    return true;
  }

  void reset() {
    state = const AdminEntryFormState();
  }
}

final adminEntryFormProvider =
    StateNotifierProvider.autoDispose<AdminEntryFormNotifier, AdminEntryFormState>(
  (ref) => AdminEntryFormNotifier(ref),
);

// --- Vehicles for admin dropdown ---
final allVehiclesProvider = FutureProvider<List<VehicleEntity>>((ref) async {
  final result = await ref.read(getAllVehiclesUseCaseProvider).call();
  return result.fold((_) => [], (list) => list);
});
