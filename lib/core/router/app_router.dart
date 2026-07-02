import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/bloc/auth/auth_provider.dart';
import '../../presentation/bloc/agri/agri_auth_provider.dart';
import '../../presentation/bloc/admin/admin_auth_provider.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/client/work_logs_page.dart';
import '../../presentation/pages/client/new_entry_page.dart';
import '../../presentation/pages/client/entry_detail_page.dart';
import '../../presentation/pages/admin/admin_login_page.dart';
import '../../presentation/pages/admin/admin_shell_page.dart';
import '../../presentation/pages/admin/dashboard_page.dart';
import '../../presentation/pages/admin/add_entry_page.dart';
import '../../presentation/pages/admin/vehicle_entry_page.dart';
import '../../presentation/pages/settings/settings_page.dart';
import '../../presentation/pages/splash_page.dart';
import '../../presentation/pages/agri/agri_login_page.dart';
import '../../presentation/pages/agri/agri_shell_page.dart';
import '../../presentation/pages/agri/lands_page.dart';
import '../../presentation/pages/agri/workers_page.dart';
import '../../presentation/pages/agri/work_entries_page.dart';
import '../../presentation/pages/agri/expenses_harvests_page.dart';
import '../../presentation/pages/agri/vehicles_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  final agriAuthNotifier = ref.watch(agriAuthProvider.notifier);
  final adminAuthNotifier = ref.watch(adminAuthProvider.notifier);
  final listenable = Listenable.merge([
    _AuthListenable(authNotifier),
    _AgriAuthListenable(agriAuthNotifier),
    _AdminAuthListenable(adminAuthNotifier),
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
      // Gated by its own fixed admin/admin credential (adminAuthProvider),
      // fully independent from the vehicle-session auth below — bypass that
      // check entirely for /admin/*.
      if (loc.startsWith('/admin')) {
        final adminAuth = ref.read(adminAuthProvider);
        if (adminAuth.status == AdminAuthStatus.loading) {
          return null;
        }
        if (!adminAuth.isAuthenticated) {
          return loc == '/admin/login' ? null : '/admin/login';
        }
        // authenticated
        if (loc == '/admin/login') return '/admin';
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
      GoRoute(path: '/admin/login', builder: (_, __) => const AdminLoginPage()),
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
          GoRoute(
            path: '/agri/vehicles',
            builder: (_, __) => const VehiclesPage(),
          ),
        ],
      ),
      // The client area is no longer a tab shell: Work Logs is the home
      // screen (with its own header + action dock), and New Entry / Edit /
      // Settings are pushed on top with a real back stack, matching the
      // Dashboard design's screen-enter animation (fade + slide from the
      // right, 280ms).
      GoRoute(path: '/client', builder: (_, __) => const WorkLogsPage()),
      GoRoute(
        path: '/client/new-entry',
        pageBuilder: (_, state) => _clientPage(state, const NewEntryPage()),
      ),
      GoRoute(
        path: '/client/entry/:id',
        pageBuilder: (_, state) => _clientPage(
            state, EntryDetailPage(entryId: state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/client/entry/:id/edit',
        pageBuilder: (_, state) => _clientPage(
            state, NewEntryPage(entryId: state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/client/settings',
        pageBuilder: (_, state) => _clientPage(state, const SettingsPage()),
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
            path: '/admin/vehicles',
            builder: (_, __) => const VehicleEntryPage(),
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

/// Fade + slide-in-from-the-right page transition (280ms, ease) used for
/// screens pushed from the client Dashboard, per the design's "screen-enter
/// animation: fade + slide-in from +14px X over 280ms ease".
CustomTransitionPage _clientPage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.ease);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    },
  );
}

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

class _AdminAuthListenable extends ChangeNotifier {
  _AdminAuthListenable(AdminAuthNotifier notifier) {
    notifier.addListener((_) => notifyListeners());
  }
}
