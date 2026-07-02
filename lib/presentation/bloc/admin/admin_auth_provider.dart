// lib/presentation/bloc/admin/admin_auth_provider.dart
//
// A small, self-contained auth gate for the admin portal. The brief asks
// for a fixed "admin" / "admin" username+password — there's no backend
// identity behind it, so this intentionally does not reuse authProvider
// (vehicle/driver session) or agriAuthProvider (Firebase email/password).
// The logged-in flag is persisted in its own Hive box (adminSessionBox,
// opened in main.dart) so an admin stays signed in across page reloads,
// mirroring how the vehicle session in auth_provider.dart persists.

import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';

enum AdminAuthStatus { loading, authenticated, unauthenticated }

class AdminAuthState {
  final AdminAuthStatus status;
  final String? errorMessage;

  const AdminAuthState({
    this.status = AdminAuthStatus.loading,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AdminAuthStatus.authenticated;

  AdminAuthState copyWith({AdminAuthStatus? status, String? errorMessage}) =>
      AdminAuthState(
        status: status ?? this.status,
        errorMessage: errorMessage,
      );
}

class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  static const _kLoggedIn = 'loggedIn';
  static const String username = 'admin';
  static const String password = 'admin';

  final Box _box = Hive.box(AppConstants.adminSessionBox);

  AdminAuthNotifier() : super(const AdminAuthState()) {
    _checkSession();
  }

  void _checkSession() {
    final loggedIn = _box.get(_kLoggedIn, defaultValue: false) as bool;
    state = AdminAuthState(
      status: loggedIn ? AdminAuthStatus.authenticated : AdminAuthStatus.unauthenticated,
    );
  }

  Future<bool> login(String enteredUsername, String enteredPassword) async {
    state = state.copyWith(status: AdminAuthStatus.loading, errorMessage: null);

    if (enteredUsername.trim() == username && enteredPassword == password) {
      await _box.put(_kLoggedIn, true);
      state = const AdminAuthState(status: AdminAuthStatus.authenticated);
      return true;
    }

    state = const AdminAuthState(
      status: AdminAuthStatus.unauthenticated,
      errorMessage: 'Invalid username or password',
    );
    return false;
  }

  Future<void> logout() async {
    await _box.delete(_kLoggedIn);
    state = const AdminAuthState(status: AdminAuthStatus.unauthenticated);
  }
}

final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, AdminAuthState>(
  (ref) => AdminAuthNotifier(),
);
