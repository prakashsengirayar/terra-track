// lib/presentation/bloc/agri/agri_auth_provider.dart
//
// Firebase Authentication state + sign-in/sign-up form handling for the
// agri module. This is a NEW auth flow, separate from the existing
// vehicle-name/driver-name session auth in
// lib/presentation/bloc/auth/auth_provider.dart, which has no concept of a
// Firebase user and is left completely untouched. The agri module needs
// real per-user identity because every Land/Worker/WorkEntry/Expense/
// Harvest document is scoped by `ownerId == FirebaseAuth.instance
// .currentUser!.uid`.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AgriAuthStatus { loading, authenticated, unauthenticated }

class AgriAuthState {
  final AgriAuthStatus status;
  final User? user;

  const AgriAuthState({
    this.status = AgriAuthStatus.loading,
    this.user,
  });

  bool get isAuthenticated =>
      status == AgriAuthStatus.authenticated && user != null;

  AgriAuthState copyWith({AgriAuthStatus? status, User? user}) {
    return AgriAuthState(
      status: status ?? this.status,
      user: user ?? this.user,
    );
  }
}

class AgriAuthNotifier extends StateNotifier<AgriAuthState> {
  AgriAuthNotifier() : super(const AgriAuthState()) {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  void _onAuthChanged(User? user) {
    state = AgriAuthState(
      status: user != null
          ? AgriAuthStatus.authenticated
          : AgriAuthStatus.unauthenticated,
      user: user,
    );
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}

/// Tracks the current Firebase auth user for the agri module
/// (loading/authenticated/unauthenticated), independent of the existing
/// vehicle-session `authProvider`.
final agriAuthProvider = StateNotifierProvider<AgriAuthNotifier, AgriAuthState>(
  (ref) => AgriAuthNotifier(),
);

/// Convenience accessor for the current user's uid, used to parameterize
/// the StreamProvider.family providers (landsStreamProvider, etc.) so
/// screens don't need to reach into FirebaseAuth directly.
final currentAgriUidProvider = Provider<String?>((ref) {
  return ref.watch(agriAuthProvider).user?.uid;
});

/// Handles the sign-in / sign-up form submission lifecycle as
/// AsyncValue<void>: AsyncLoading while the request is in flight,
/// AsyncData(null) on success, AsyncError(message) on failure.
class AgriAuthFormNotifier extends StateNotifier<AsyncValue<void>> {
  AgriAuthFormNotifier() : super(const AsyncValue.data(null));

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      state = const AsyncValue.data(null);
      return true;
    } on FirebaseAuthException catch (e, st) {
      state = AsyncValue.error(_mapAuthError(e), st);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (displayName != null && displayName.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(displayName.trim());
      }
      state = const AsyncValue.data(null);
      return true;
    } on FirebaseAuthException catch (e, st) {
      state = AsyncValue.error(_mapAuthError(e), st);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      state = const AsyncValue.data(null);
      return true;
    } on FirebaseAuthException catch (e, st) {
      state = AsyncValue.error(_mapAuthError(e), st);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}

final agriAuthFormProvider =
    StateNotifierProvider.autoDispose<AgriAuthFormNotifier, AsyncValue<void>>(
  (ref) => AgriAuthFormNotifier(),
);
