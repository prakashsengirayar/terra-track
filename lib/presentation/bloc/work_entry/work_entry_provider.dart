import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/entities/entities.dart';
import '../providers.dart';
import '../auth/auth_provider.dart';

// --- Timer State ---
enum TimerStatus { idle, running, paused, stopped }

class TimerState {
  final TimerStatus status;
  final int elapsedSeconds;
  final String? liveCustomerName;

  const TimerState({
    this.status = TimerStatus.idle,
    this.elapsedSeconds = 0,
    this.liveCustomerName,
  });

  int get hours => elapsedSeconds ~/ 3600;
  int get minutes => (elapsedSeconds % 3600) ~/ 60;
  int get seconds => elapsedSeconds % 60;

  String get display =>
      '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

  double get totalHours => elapsedSeconds / 3600;

  TimerState copyWith({
    TimerStatus? status,
    int? elapsedSeconds,
    String? liveCustomerName,
  }) =>
      TimerState(
        status: status ?? this.status,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        liveCustomerName: liveCustomerName ?? this.liveCustomerName,
      );
}

class TimerNotifier extends StateNotifier<TimerState> {
  Timer? _timer;

  TimerNotifier() : super(const TimerState());

  void start(String customerName) {
    if (state.status == TimerStatus.running) return;
    _timer?.cancel();
    state = state.copyWith(
      status: TimerStatus.running,
      liveCustomerName: customerName,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      if (state.elapsedSeconds % 60 == 0) {
        NotificationService.instance.showTimerNotification(
          customerName: customerName,
          elapsed: state.display,
        );
      }
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(status: TimerStatus.paused);
  }

  void resume(String customerName) {
    if (state.status != TimerStatus.paused) return;
    start(customerName);
  }

  void stop() {
    _timer?.cancel();
    state = state.copyWith(status: TimerStatus.stopped);
    NotificationService.instance.cancelTimerNotification();
  }

  void reset() {
    _timer?.cancel();
    state = const TimerState();
    NotificationService.instance.cancelTimerNotification();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>(
  (_) => TimerNotifier(),
);

// --- Work Entry Form State ---
class EntryFormState {
  final bool isLoading;
  final bool isSaved;
  final String? error;
  final String? customerPhotoUrl;
  final String? billPhotoUrl;
  final Uint8List? customerPhotoBytes;
  final Uint8List? billPhotoBytes;
  final List<String> nativeSuggestions;
  final bool isNameUnique;
  final bool isCheckingName;

  const EntryFormState({
    this.isLoading = false,
    this.isSaved = false,
    this.error,
    this.customerPhotoUrl,
    this.billPhotoUrl,
    this.customerPhotoBytes,
    this.billPhotoBytes,
    this.nativeSuggestions = const [],
    this.isNameUnique = true,
    this.isCheckingName = false,
  });

  EntryFormState copyWith({
    bool? isLoading,
    bool? isSaved,
    String? error,
    String? customerPhotoUrl,
    String? billPhotoUrl,
    Uint8List? customerPhotoBytes,
    Uint8List? billPhotoBytes,
    List<String>? nativeSuggestions,
    bool? isNameUnique,
    bool? isCheckingName,
  }) =>
      EntryFormState(
        isLoading: isLoading ?? this.isLoading,
        isSaved: isSaved ?? this.isSaved,
        error: error,
        customerPhotoUrl: customerPhotoUrl ?? this.customerPhotoUrl,
        billPhotoUrl: billPhotoUrl ?? this.billPhotoUrl,
        customerPhotoBytes: customerPhotoBytes ?? this.customerPhotoBytes,
        billPhotoBytes: billPhotoBytes ?? this.billPhotoBytes,
        nativeSuggestions: nativeSuggestions ?? this.nativeSuggestions,
        isNameUnique: isNameUnique ?? this.isNameUnique,
        isCheckingName: isCheckingName ?? this.isCheckingName,
      );
}

class EntryFormNotifier extends StateNotifier<EntryFormState> {
  final Ref _ref;
  Timer? _nameDebounce;

  EntryFormNotifier(this._ref) : super(const EntryFormState());

  void setCustomerPhotoBytes(Uint8List bytes) {
    state = state.copyWith(customerPhotoBytes: bytes);
  }

  void setBillPhotoBytes(Uint8List bytes) {
    state = state.copyWith(billPhotoBytes: bytes);
  }

  void checkCustomerName(String name, String vehicleName,
      {String? excludeId}) {
    _nameDebounce?.cancel();
    if (name.trim().length < 2) return;
    state = state.copyWith(isCheckingName: true);
    _nameDebounce = Timer(const Duration(milliseconds: 600), () async {
      final result = await _ref
          .read(checkNameUniqueUseCaseProvider)
          .call(name, vehicleName, excludeId: excludeId);
      result.fold(
        (_) => state = state.copyWith(isCheckingName: false),
        (isUnique) =>
            state = state.copyWith(isNameUnique: isUnique, isCheckingName: false),
      );
    });
  }

  Future<void> fetchNativeSuggestions(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(nativeSuggestions: []);
      return;
    }
    final result =
        await _ref.read(getNativeSuggestionsUseCaseProvider).call(query);
    result.fold(
      (_) {},
      (list) => state = state.copyWith(nativeSuggestions: list),
    );
  }

  Future<bool> saveEntry({
    required String customerName,
    required String nativePlace,
    required String vehicleName,
    required String driverName,
    required double ratePerHour,
    required int timerSeconds,
    required double paidAmount,
    required DateTime date,
    required String customerPhone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final tempId = const Uuid().v4();

    // Upload photos first if selected
    String? customerPhotoUrl;
    String? billPhotoUrl;

    if (state.customerPhotoBytes != null) {
      final r = await _ref
          .read(uploadCustomerPhotoUseCaseProvider)
          .call(state.customerPhotoBytes!, tempId);
      r.fold((_) {}, (url) => customerPhotoUrl = url);
    }
    if (state.billPhotoBytes != null) {
      final r = await _ref
          .read(uploadBillPhotoUseCaseProvider)
          .call(state.billPhotoBytes!, tempId);
      r.fold((_) {}, (url) => billPhotoUrl = url);
    }

    final totalAmount =
        ((timerSeconds * 1.0) / 3600) * ratePerHour;
    final balance = totalAmount - paidAmount;
    final entry = WorkEntryEntity(
      id: '',
      customerName: customerName.trim(),
      nativePlace: nativePlace.trim(),
      vehicleName: vehicleName,
      driverName: driverName,
      ratePerHour: ratePerHour,
      timerDurationSeconds: timerSeconds,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      balanceAmount: balance < 0 ? 0 : balance,
      status: balance <= 0 ? PaymentStatus.paid : PaymentStatus.pending,
      date: date,
      customerPhone: customerPhone.trim(),
      billPhotoUrl: billPhotoUrl,
      customerPhotoUrl: customerPhotoUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result =
        await _ref.read(createWorkEntryUseCaseProvider).call(entry);

    return result.fold(
      (f) {
        state = state.copyWith(isLoading: false, error: f.message);
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false, isSaved: true);
        NotificationService.instance.showEntrySavedNotification(customerName);
        _ref.read(timerProvider.notifier).reset();
        return true;
      },
    );
  }

  void reset() {
    _nameDebounce?.cancel();
    state = const EntryFormState();
  }

  @override
  void dispose() {
    _nameDebounce?.cancel();
    super.dispose();
  }
}

final entryFormProvider =
    StateNotifierProvider.autoDispose<EntryFormNotifier, EntryFormState>(
  (ref) => EntryFormNotifier(ref),
);

// --- Work Logs Provider ---
class WorkLogsState {
  final bool isLoading;
  final List<WorkEntryEntity> entries;
  final String? error;
  final String searchQuery;
  final bool latestFirst;

  const WorkLogsState({
    this.isLoading = false,
    this.entries = const [],
    this.error,
    this.searchQuery = '',
    this.latestFirst = true,
  });

  List<WorkEntryEntity> get filtered {
    if (searchQuery.isEmpty) return entries;
    final q = searchQuery.toLowerCase();
    return entries.where((e) => e.customerName.toLowerCase().contains(q)).toList();
  }

  Map<String, List<WorkEntryEntity>> get groupedByDate {
    final result = <String, List<WorkEntryEntity>>{};
    for (final e in filtered) {
      final key =
          '${e.date.day.toString().padLeft(2, '0')} ${_monthName(e.date.month)} ${e.date.year}';
      result[key] ??= [];
      result[key]!.add(e);
    }
    return result;
  }

  String _monthName(int m) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return months[m - 1];
  }

  WorkLogsState copyWith({
    bool? isLoading,
    List<WorkEntryEntity>? entries,
    String? error,
    String? searchQuery,
    bool? latestFirst,
  }) =>
      WorkLogsState(
        isLoading: isLoading ?? this.isLoading,
        entries: entries ?? this.entries,
        error: error,
        searchQuery: searchQuery ?? this.searchQuery,
        latestFirst: latestFirst ?? this.latestFirst,
      );
}

class WorkLogsNotifier extends StateNotifier<WorkLogsState> {
  final Ref _ref;

  WorkLogsNotifier(this._ref) : super(const WorkLogsState()) {
    _load();
  }

  Future<void> _load() async {
    final session = _ref.read(authProvider).session;
    if (session == null) return;
    state = state.copyWith(isLoading: true);
    final result = await _ref
        .read(getEntriesByVehicleUseCaseProvider)
        .call(session.vehicleName, latestFirst: state.latestFirst);
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (entries) => state = state.copyWith(isLoading: false, entries: entries),
    );
  }

  Future<void> refresh() => _load();

  void setSearch(String q) {
    state = state.copyWith(searchQuery: q);
  }

  void toggleSort() {
    state = state.copyWith(latestFirst: !state.latestFirst);
    _load();
  }
}

final workLogsProvider =
    StateNotifierProvider.autoDispose<WorkLogsNotifier, WorkLogsState>(
  (ref) => WorkLogsNotifier(ref),
);

// --- Stream provider for live logs ---
final liveWorkLogsProvider = StreamProvider.autoDispose<List<WorkEntryEntity>>(
  (ref) {
    final session = ref.watch(authProvider).session;
    if (session == null) return const Stream.empty();
    return ref
        .read(watchEntriesUseCaseProvider)
        .call(session.vehicleName);
  },
);
