import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/entities.dart';
import '../providers.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final SessionEntity? session;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.loading,
    this.session,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    SessionEntity? session,
    String? errorMessage,
  }) =>
      AuthState(
        status: status ?? this.status,
        session: session ?? this.session,
        errorMessage: errorMessage,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState()) {
    _checkSession();
  }

  void _checkSession() {
    final result = _ref.read(getSessionUseCaseProvider).call();
    result.fold(
      (f) => state = const AuthState(status: AuthStatus.unauthenticated),
      (session) {
        if (session != null) {
          state = AuthState(
            status: AuthStatus.authenticated,
            session: session,
          );
        } else {
          state = const AuthState(status: AuthStatus.unauthenticated);
        }
      },
    );
  }

  Future<void> login(String vehicleName, String driverName) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final verifyResult =
        await _ref.read(verifyVehicleUseCaseProvider).call(vehicleName);

    await verifyResult.fold(
      (failure) async {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: failure.message,
        );
      },
      (vehicle) async {
        final session = SessionEntity(
          vehicleId: vehicle.id,
          vehicleName: vehicle.vehicleName,
          driverName: driverName,
          loginTime: DateTime.now(),
        );
        final saveResult =
            await _ref.read(saveSessionUseCaseProvider).call(session);
        saveResult.fold(
          (f) => state = AuthState(
            status: AuthStatus.unauthenticated,
            errorMessage: f.message,
          ),
          (_) => state = AuthState(
            status: AuthStatus.authenticated,
            session: session,
          ),
        );
      },
    );
  }

  Future<void> logout() async {
    await _ref.read(clearSessionUseCaseProvider).call();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);
