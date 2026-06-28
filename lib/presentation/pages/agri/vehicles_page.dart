// lib/presentation/pages/agri/vehicles_page.dart
//
// Vehicles list for the agri module. Unlike Lands/Workers/Expenses/
// Harvests, the add/edit form lives on its own screen (add_vehicle_page.dart,
// pushed via Navigator) rather than a modal bottom sheet — it's only two
// short fields with no photo, so a sheet would be overkill. Reads live from
// Firestore via agriVehiclesStreamProvider(uid) and writes through
// agriVehicleFormProvider, following the same StreamProvider/
// StateNotifier<AsyncValue> wiring used by every other agri screen.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/agri_entities.dart';
import '../../bloc/agri/agri_auth_provider.dart';
import '../../bloc/agri/agri_vehicle_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/agri/agri_form_widgets.dart';
import 'add_vehicle_page.dart';

class VehiclesPage extends ConsumerWidget {
  const VehiclesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final uid = ref.watch(currentAgriUidProvider);

    if (uid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final vehiclesAsync = ref.watch(agriVehiclesStreamProvider(uid));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddVehicle(context, uid: uid),
        child: const Icon(Icons.add),
      ),
      body: vehiclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => AgriErrorState(message: err.toString()),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return EmptyState(
              title: l.noVehicles,
              subtitle: l.noVehiclesSubtitle,
              icon: Icons.directions_car_outlined,
              onAction: () => _openAddVehicle(context, uid: uid),
              actionLabel: l.addVehicle,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: vehicles.length,
            itemBuilder: (_, i) {
              final vehicle = vehicles[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _VehicleTile(
                  vehicle: vehicle,
                  onTap: () =>
                      _openAddVehicle(context, uid: uid, existing: vehicle),
                  onDelete: () => _deleteVehicle(context, ref, vehicle),
                ),
              ).animate().fadeIn(duration: 250.ms, delay: (i * 30).ms).slideX(begin: -0.03);
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteVehicle(
      BuildContext context, WidgetRef ref, AgriVehicleEntity vehicle) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showAgriDeleteConfirm(context, l.deleteVehicleConfirm);
    if (!confirmed) return;
    final ok = await ref.read(agriVehicleFormProvider.notifier).deleteVehicle(vehicle.id);
    if (!ok && context.mounted) {
      showAgriSnack(context,
          error: ref.read(agriVehicleFormProvider).error ?? l.errorOccurred);
    }
  }

  void _openAddVehicle(BuildContext context,
      {required String uid, AgriVehicleEntity? existing}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddVehiclePage(uid: uid, existing: existing),
      ),
    );
  }
}

class _VehicleTile extends StatelessWidget {
  final AgriVehicleEntity vehicle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _VehicleTile({required this.vehicle, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TerraCard(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.directions_car, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehicle.vehicleName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(vehicle.vehicleNumber,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.grey500)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
