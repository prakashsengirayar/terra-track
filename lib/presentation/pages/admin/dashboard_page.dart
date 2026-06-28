import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/entities.dart';
import '../../bloc/admin/admin_provider.dart';
import '../../widgets/common/common_widgets.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(dashboardProvider);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.error != null) return EmptyState(title: l.errorOccurred, subtitle: state.error!,
        icon: Icons.error_outline, onAction: () => ref.read(dashboardProvider.notifier).load(),
        actionLabel: l.retry);

    final s = state.summary;
    if (s == null) return EmptyState(title: l.noData, subtitle: '', icon: Icons.dashboard_outlined);

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardProvider.notifier).load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.dashboard, style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: AppColors.primaryDark)),
          const SizedBox(height: 16),

          // Metric cards grid
          GridView.count(
            crossAxisCount: isDesktop ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12, mainAxisSpacing: 12,
            childAspectRatio: isDesktop ? 1.4 : 1.2,
            children: [
              MetricCard(
                label: l.totalHours,
                value: '${s.totalHours.toStringAsFixed(1)}h',
                icon: Icons.timer_outlined,
                color: AppColors.primary,
                bgColor: AppColors.primarySurface,
              ).animate().fadeIn(duration: 400.ms),
              MetricCard(
                label: l.amountCollected,
                value: currency.format(s.totalCollected),
                icon: Icons.currency_rupee,
                color: AppColors.success,
                bgColor: AppColors.successSurface,
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              MetricCard(
                label: l.pendingAmount,
                value: currency.format(s.totalPending),
                icon: Icons.pending_outlined,
                color: AppColors.error,
                bgColor: AppColors.errorSurface,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              MetricCard(
                label: l.activeVehicles,
                value: '${s.activeVehicleCount}',
                icon: Icons.directions_car_outlined,
                color: AppColors.secondary,
                bgColor: AppColors.secondarySurface,
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
            ],
          ),
          const SizedBox(height: 24),

          // Vehicle summary
          Text(l.vehicleSummary, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (s.vehicleSummaries.isEmpty)
            EmptyState(title: l.noData, subtitle: '', icon: Icons.directions_car_outlined)
          else
            ...s.vehicleSummaries.map((v) => _VehicleCard(v: v, currency: currency, l: l)
                .animate().fadeIn(duration: 400.ms).slideX(begin: -0.05)),
        ]),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final VehicleSummaryEntity v;
  final NumberFormat currency;
  final AppLocalizations l;
  const _VehicleCard({required this.v, required this.currency, required this.l});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.agriculture, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v.vehicleName, style: theme.textTheme.titleSmall),
              Text(v.driverName, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.grey500)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: v.isActive ? AppColors.primarySurface : AppColors.grey100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(v.isActive ? 'Active' : 'Idle',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: v.isActive ? AppColors.primary : AppColors.grey500)),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _stat(theme, l.totalHours, '${v.totalHours.toStringAsFixed(1)}h'),
            _stat(theme, l.amountCollected, currency.format(v.totalEarnings)),
            _stat(theme, l.pendingAmount, currency.format(v.totalPending),
                color: v.totalPending > 0 ? AppColors.error : null),
            _stat(theme, l.entriesCount, '${v.entryCount} ${l.entriesCount}'),
          ]),
        ]),
      ),
    );
  }

  Widget _stat(ThemeData theme, String label, String value, {Color? color}) {
    return Expanded(
      child: Column(children: [
        Text(value, style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700, color: color)),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.grey500),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}
