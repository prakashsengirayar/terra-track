import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/bloc/auth/auth_provider.dart';
import '../../presentation/bloc/agri/agri_auth_provider.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/client/main_tab_page.dart';
import '../../presentation/pages/client/work_logs_page.dart';
import '../../presentation/pages/client/new_entry_page.dart';
import '../../presentation/pages/client/entry_detail_page.dart';
import '../../presentation/pages/admin/admin_shell_page.dart';
import '../../presentation/pages/admin/dashboard_page.dart';
import '../../presentation/pages/admin/add_entry_page.dart';
import '../../presentation/pages/settings/settings_page.dart';
import '../../presentation/pages/splash_page.dart';
import '../../presentation/pages/agri/agri_login_page.dart';
import '../../presentation/pages/agri/agri_shell_page.dart';
import '../../presentation/pages/agri/lands_page.dart';
import '../../presentation/pages/agri/workers_page.dart';
import '../../presentation/pages/agri/work_entries_page.dart';
import '../../presentation/pages/agri/expenses_harvests_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  final agriAuthNotifier = ref.watch(agriAuthProvider.notifier);
  final listenable = Listenable.merge([
    _AuthListenable(authNotifier),
    _AgriAuthListenable(agriAuthNotifier),
  ]);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: listenable,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // --- Agri module branch (separate Firebase-auth identity) ---
      // Kept fully independent from the vehicle-session auth below: any
      // location under /agri is governed solely by agriAuthProvider, and
      // never falls through to the vehicle-session checks.
      if (loc.startsWith('/agri')) {
        final agriAuth = ref.read(agriAuthProvider);
        if (agriAuth.status == AgriAuthStatus.loading) {
          return null;
        }
        if (!agriAuth.isAuthenticated) {
          return loc == '/agri/login' ? null : '/agri/login';
        }
        // authenticated
        if (loc == '/agri/login') return '/agri/lands';
        return null;
      }

      // --- Admin branch ---
      // The admin area has no auth gate of its own (see admin_shell_page.dart /
      // admin_provider.dart — there is no admin-specific login/session). It is
      // reached directly from the "Admin Panel →" link on the unauthenticated
      // login screen, so it must never be subject to the vehicle/driver
      // session check below: bypass that check entirely for /admin/*.
      if (loc.startsWith('/admin')) {
        return null;
      }

      final auth = ref.read(authProvider);

      if (auth.status == AuthStatus.loading) {
        return loc == '/splash' ? null : '/splash';
      }
      if (!auth.isAuthenticated) {
        if (loc == '/login') return null;
        return '/login';
      }
      // authenticated
      if (loc == '/splash' || loc == '/login') return '/client';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/agri/login', builder: (_, __) => const AgriLoginPage()),
      ShellRoute(
        builder: (_, __, child) => AgriShellPage(child: child),
        routes: [
          GoRoute(
            path: '/agri/lands',
            builder: (_, __) => const LandsPage(),
          ),
          GoRoute(
            path: '/agri/workers',
            builder: (_, __) => const WorkersPage(),
          ),
          GoRoute(
            path: '/agri/work-entries',
            builder: (_, __) => const WorkEntriesPage(),
          ),
          GoRoute(
            path: '/agri/expenses-harvests',
            builder: (_, __) => const ExpensesHarvestsPage(),
          ),
        ],
      ),
      ShellRoute(
        builder: (_, __, child) => MainTabPage(child: child),
        routes: [
          GoRoute(
            path: '/client',
            builder: (_, __) => const WorkLogsPage(),
          ),
          GoRoute(
            path: '/client/new-entry',
            builder: (_, __) => const NewEntryPage(),
          ),
          GoRoute(
            path: '/client/entry/:id',
            builder: (_, state) =>
                EntryDetailPage(entryId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/client/settings',
            builder: (_, __) => const SettingsPage(),
          ),
        ],
      ),
      ShellRoute(
        builder: (_, __, child) => AdminShellPage(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (_, __) => const DashboardPage(),
          ),
          GoRoute(
            path: '/admin/add-entry',
            builder: (_, __) => const AddEntryPage(),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (_, __) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(AuthNotifier notifier) {
    notifier.addListener((_) => notifyListeners());
  }
}

class _AgriAuthListenable extends ChangeNotifier {
  _AgriAuthListenable(AgriAuthNotifier notifier) {
    notifier.addListener((_) => notifyListeners());
  }
}
