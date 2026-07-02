import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/entities.dart';
import '../../bloc/auth/auth_provider.dart';
import '../../bloc/work_entry/work_entry_provider.dart';

/// Work Logs — the client app's home/dashboard screen. Matches the
/// "TerraTrack Dashboard" design: a dark card list, an amber "to collect"
/// summary, All/Pending/Paid filter chips, and a bottom action dock
/// (New Entry / Settings / Logout) that replaces the old tab-bar + app-bar
/// chrome. This screen now owns its own Scaffold (no shared shell).
class WorkLogsPage extends ConsumerStatefulWidget {
  const WorkLogsPage({super.key});
  @override
  ConsumerState<WorkLogsPage> createState() => _WorkLogsPageState();
}

enum _Filter { all, pending, paid }

class _WorkLogsPageState extends ConsumerState<WorkLogsPage> {
  _Filter _filter = _Filter.all;
  final _numFmt = NumberFormat.decimalPattern('en_IN');
  final _dateFmt = DateFormat('dd MMM yyyy');

  String _fmt(num n) => _numFmt.format(n.round());

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.entryHeaderTop,
        title: const Text('Logout', style: TextStyle(color: AppColors.entryTextPrimary)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: AppColors.entryTextMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.entryTextSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Logout', style: TextStyle(color: AppColors.entryRed))),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final logsState = ref.watch(workLogsProvider);
    final session = ref.watch(authProvider).session;

    return Scaffold(
      backgroundColor: AppColors.entryBgBottom,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.entryBgTop, AppColors.entryBgBottom],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            _header(session?.vehicleName),
            Expanded(
              child: logsState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.entryAccent))
                  : logsState.error != null && logsState.entries.isEmpty
                      ? _errorState(logsState.error!)
                      : RefreshIndicator(
                          color: AppColors.entryAccent,
                          backgroundColor: AppColors.entryHeaderTop,
                          onRefresh: () => ref.read(workLogsProvider.notifier).refresh(),
                          child: _scrollArea(logsState),
                        ),
            ),
          ]),
        ),
      ),
      bottomNavigationBar: SafeArea(top: false, child: _actionDock()),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────
  Widget _header(String? vehicleName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              color: AppColors.entryAccent, borderRadius: BorderRadius.circular(15)),
          alignment: Alignment.center,
          child: const Text('T',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.entryPillText)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Work Logs',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.entryTextPrimary,
                    letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(
              vehicleName != null && vehicleName.isNotEmpty
                  ? 'TerraTrack · $vehicleName'
                  : 'TerraTrack',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.entryTextMutedDeep),
            ),
          ],
          ),
        ),
      ]),
    );
  }

  // ─── Scroll area (summary + chips + list) ───────────────────────────────
  Widget _scrollArea(WorkLogsState state) {
    final entries = state.entries;
    final avatarColors = [
      for (var i = 0; i < entries.length; i++) AppColors.entryAvatarPalette[i % 5]
    ];
    final sumBalance = entries.fold<double>(0, (a, e) => a + e.balanceAmount);
    final pendingCount = entries.where((e) => e.status == PaymentStatus.pending).length;
    final paidCount = entries.where((e) => e.status == PaymentStatus.paid).length;

    final indices = List<int>.generate(entries.length, (i) => i).where((i) {
      switch (_filter) {
        case _Filter.all:
          return true;
        case _Filter.pending:
          return entries[i].status == PaymentStatus.pending;
        case _Filter.paid:
          return entries[i].status == PaymentStatus.paid;
      }
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
      children: [
        _summaryCard(sumBalance),
        const SizedBox(height: 12),
        _filterChips(entries.length, pendingCount, paidCount),
        const SizedBox(height: 14),
        if (indices.isEmpty)
          _emptyState()
        else
          ...indices.map((i) => _entryCard(entries[i], avatarColors[i])),
      ],
    );
  }

  Widget _summaryCard(double sumBalance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.entryAmber, AppColors.entryAmberDeep],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppColors.entryAmber.withOpacity(0.22),
              blurRadius: 28,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.account_balance_wallet, size: 22, color: AppColors.entryAmberDeepText),
            const SizedBox(width: 8),
            const Text('To collect',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.entryAmberDeepText,
                    letterSpacing: 0.3)),
          ]),
          const SizedBox(height: 6),
          Text('₹ ${_fmt(sumBalance)}',
              style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppColors.entryAmberDarkText,
                  height: 1.1)),
        ],
      ),
    );
  }

  Widget _filterChips(int all, int pending, int paid) {
    return Row(children: [
      Expanded(child: _chip('All', all, _Filter.all)),
      const SizedBox(width: 9),
      Expanded(child: _chip('Pending', pending, _Filter.pending)),
      const SizedBox(width: 9),
      Expanded(child: _chip('Paid', paid, _Filter.paid)),
    ]);
  }

  Widget _chip(String label, int count, _Filter value) {
    final active = _filter == value;
    return Material(
      color: active ? AppColors.entryAccentTintStrong : AppColors.entryWhite04,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _filter = value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$count',
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: active ? AppColors.entryAccent : AppColors.entryTextPrimary)),
              const SizedBox(height: 1),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: active ? AppColors.entryAccent : AppColors.entryTextMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _entryCard(WorkEntryEntity e, Color avatarColor) {
    final isPaid = e.status == PaymentStatus.paid;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: AppColors.entryCardBg,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => context.push('/client/entry/${e.id}/edit'),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.entryCardBorder),
            ),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration:
                    BoxDecoration(color: avatarColor, borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: Text(
                  e.customerName.isNotEmpty ? e.customerName[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.entryPillText),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.entryTextPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      '${e.nativePlace.isEmpty ? 'No place' : e.nativePlace} · ${_dateFmt.format(e.date)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.entryTextMuted),
                    ),
                    const SizedBox(height: 8),
                    isPaid ? _paidPill() : _pendingPill(e.balanceAmount),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${_fmt(e.totalAmount)}',
                      style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: AppColors.entryTextPrimary)),
                  const SizedBox(height: 2),
                  const Icon(Icons.chevron_right, size: 24, color: AppColors.entryTextMutedDeep),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _paidPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: AppColors.entryAccentTintStrong, borderRadius: BorderRadius.circular(999)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle, size: 16, color: AppColors.entryAccent),
        SizedBox(width: 5),
        Text('Paid',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.entryAccent)),
      ]),
    );
  }

  Widget _pendingPill(double balance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: AppColors.entryAmberTintBg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.schedule, size: 16, color: AppColors.entryAmber),
        const SizedBox(width: 5),
        Text('₹ ${_fmt(balance)} due',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.entryAmber)),
      ]),
    );
  }

  // Firestore/network failures used to fail completely silently here — the
  // list would just render empty, indistinguishable from "no entries yet".
  // Surface the real error (with the exact message, e.g. a missing-index or
  // permission error from Firestore) plus a retry button instead.
  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.entryRed, size: 44),
          const SizedBox(height: 14),
          const Text("Couldn't load work logs",
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.entryTextPrimary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.entryRedTintBg,
              border: Border.all(color: AppColors.entryRedTintBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.entryTextSecondary)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.read(workLogsProvider.notifier).refresh(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.entryAccent,
              foregroundColor: AppColors.entryPillText,
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ]),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(children: [
        const Icon(Icons.assignment_outlined, size: 56, color: AppColors.entryTextMutedDeep),
        const SizedBox(height: 14),
        const Text('No entries yet',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.entryTextPrimary)),
        const SizedBox(height: 6),
        const Text('Tap "New Entry" below to log your first job.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.entryTextMuted)),
      ]),
    );
  }

  // ─── Action dock ─────────────────────────────────────────────────────────
  Widget _actionDock() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: const BoxDecoration(
        color: AppColors.entryNavBg,
        border: Border(top: BorderSide(color: AppColors.entryCardBorder)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _newEntryButton(),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: _dockButton(
              icon: Icons.settings,
              label: 'Settings',
              iconColor: const Color(0xFF9FBCAE),
              textColor: AppColors.entryTextSecondary,
              bg: AppColors.entryWhite04,
              border: AppColors.entryWhite12,
              onTap: () => context.push('/client/settings'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _dockButton(
              icon: Icons.logout,
              label: 'Logout',
              iconColor: AppColors.entryRed,
              textColor: AppColors.entryRed,
              bg: AppColors.entryRedTintBg,
              border: AppColors.entryRedTintBorder,
              onTap: _confirmLogout,
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _newEntryButton() {
    return Material(
      color: AppColors.entryAccent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push('/client/new-entry'),
        child: Container(
          width: double.infinity,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                  color: AppColors.entryAccent.withOpacity(0.3),
                  blurRadius: 28,
                  offset: const Offset(0, 12)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: AppColors.entryPillText.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: const Icon(Icons.add, size: 30, color: AppColors.entryPillText),
              ),
              const SizedBox(width: 12),
              const Text('New Entry',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.entryPillText)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dockButton({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color textColor,
    required Color bg,
    required Color border,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 25, color: iconColor),
              const SizedBox(width: 9),
              Text(label,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textColor)),
            ],
          ),
        ),
      ),
    );
  }
}
