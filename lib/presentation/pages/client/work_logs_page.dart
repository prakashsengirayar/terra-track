import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/entities.dart';
import '../../bloc/work_entry/work_entry_provider.dart';
import '../../widgets/common/common_widgets.dart';

class WorkLogsPage extends ConsumerStatefulWidget {
  const WorkLogsPage({super.key});
  @override
  ConsumerState<WorkLogsPage> createState() => _WorkLogsPageState();
}

class _WorkLogsPageState extends ConsumerState<WorkLogsPage> {
  final _searchCtrl = TextEditingController();
  final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final logsState = ref.watch(workLogsProvider);
    final timer = ref.watch(timerProvider);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => ref.read(workLogsProvider.notifier).refresh(),
      child: Column(children: [
        // Search + Sort bar
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: l.searchCustomer,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  isDense: true,
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref.read(workLogsProvider.notifier).setSearch('');
                          })
                      : null,
                ),
                onChanged: (v) => ref.read(workLogsProvider.notifier).setSearch(v),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => ref.read(workLogsProvider.notifier).toggleSort(),
              icon: Icon(
                logsState.latestFirst ? Icons.arrow_downward : Icons.arrow_upward,
                color: AppColors.primary,
              ),
              tooltip: logsState.latestFirst ? l.latestFirst : l.oldestFirst,
            ),
          ]),
        ),

        // Live timer tile
        if (timer.status == TimerStatus.running && timer.liveCustomerName != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryLight.withOpacity(0.4)),
            ),
            child: Row(children: [
              Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(
                    color: AppColors.primaryLight, shape: BoxShape.circle),
              ).animate(onPlay: (c) => c.repeat()).fadeOut(duration: 800.ms),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(timer.liveCustomerName!,
                      style: theme.textTheme.titleSmall?.copyWith(color: AppColors.primaryDark)),
                  Text('${l.liveTimer} · ${timer.display}',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary)),
                ]),
              ),
              TextButton(
                onPressed: () => context.go('/client/new-entry'),
                child: const Text('View'),
              ),
            ]),
          ),

        // List
        Expanded(
          child: logsState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : logsState.entries.isEmpty
                  ? EmptyState(
                      title: l.noEntries,
                      subtitle: l.noEntriesSubtitle,
                      icon: Icons.assignment_outlined,
                      onAction: () => context.go('/client/new-entry'),
                      actionLabel: l.newEntry,
                    )
                  : _buildGroupedList(logsState, l, theme),
        ),
      ]),
    );
  }

  Widget _buildGroupedList(WorkLogsState state, AppLocalizations l, ThemeData theme) {
    final grouped = state.groupedByDate;
    final dates = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: dates.length,
      itemBuilder: (_, i) {
        final date = dates[i];
        final entries = grouped[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(date,
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.grey500, letterSpacing: 0.5)),
            ),
            ...entries.map((e) => _EntryTile(
              entry: e,
              currency: currency,
              onTap: () => context.go('/client/entry/${e.id}'),
            ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1)),
          ],
        );
      },
    );
  }
}

class _EntryTile extends StatelessWidget {
  final WorkEntryEntity entry;
  final NumberFormat currency;
  final VoidCallback onTap;
  const _EntryTile({required this.entry, required this.currency, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPaid = entry.status == PaymentStatus.paid;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primarySurface,
              backgroundImage: entry.customerPhotoUrl != null
                  ? NetworkImage(entry.customerPhotoUrl!) : null,
              child: entry.customerPhotoUrl == null
                  ? Text(
                      entry.customerName.isNotEmpty
                          ? entry.customerName[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w600))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.customerName,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text('${entry.nativePlace} · ${entry.formattedHours}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.grey500)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              StatusBadge(isPaid: isPaid),
              const SizedBox(height: 4),
              if (!isPaid)
                Text(currency.format(entry.balanceAmount),
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: AppColors.error))
              else
                Text(currency.format(entry.totalAmount),
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: AppColors.success)),
            ]),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.grey300),
          ]),
        ),
      ),
    );
  }
}
