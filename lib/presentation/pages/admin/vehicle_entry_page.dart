import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../core/theme/app_theme.dart';
import '../../bloc/admin/vehicle_provider.dart';
import '../../widgets/common/common_widgets.dart';

class VehicleEntryPage extends ConsumerStatefulWidget {
  const VehicleEntryPage({super.key});

  @override
  ConsumerState<VehicleEntryPage> createState() => _VehicleEntryPageState();
}

class _VehicleEntryPageState extends ConsumerState<VehicleEntryPage> {
  bool _showForm = false;
  String? _editingId;
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberCtrl = TextEditingController();
  final _vehicleNameCtrl = TextEditingController();
  final _driverNameCtrl = TextEditingController();

  @override
  void dispose() {
    _vehicleNumberCtrl.dispose();
    _vehicleNameCtrl.dispose();
    _driverNameCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _vehicleNumberCtrl.clear();
    _vehicleNameCtrl.clear();
    _driverNameCtrl.clear();
    setState(() {
      _showForm = false;
      _editingId = null;
    });
  }

  void _editVehicle(
    String id,
    String vehicleNumber,
    String vehicleName,
    String driverName,
  ) {
    _vehicleNumberCtrl.text = vehicleNumber;
    _vehicleNameCtrl.text = vehicleName;
    _driverNameCtrl.text = driverName;
    setState(() {
      _editingId = id;
      _showForm = true;
    });
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(vehicleFormProvider.notifier).submitVehicle(
          id: _editingId,
          vehicleNumber: _vehicleNumberCtrl.text,
          vehicleName: _vehicleNameCtrl.text,
          driverName: _driverNameCtrl.text,
        );

    if (success && mounted) {
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle saved successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      // Reload list
      ref.read(vehicleListProvider.notifier).load(includeInactive: true);
    }
  }

  Future<void> _deleteVehicle(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: const Text('Are you sure you want to delete this vehicle?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success =
          await ref.read(vehicleListProvider.notifier).deleteVehicle(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle deleted'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final listState = ref.watch(vehicleListProvider);
    final formState = ref.watch(vehicleFormProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vehicle Management',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: AppColors.primaryDark),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (_showForm) {
                    _resetForm();
                  } else {
                    setState(() => _showForm = true);
                  }
                },
                icon: Icon(_showForm ? Icons.close : Icons.add),
                label: Text(_showForm ? 'Cancel' : 'Add Vehicle'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Form section
          if (_showForm)
            TerraCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editingId == null ? 'Add New Vehicle' : 'Edit Vehicle',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _vehicleNumberCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Vehicle Number',
                        prefixIcon: const Icon(Icons.pin_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Vehicle number is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _vehicleNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Vehicle Name',
                        prefixIcon: const Icon(Icons.directions_car_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Vehicle name is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _driverNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Driver Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Driver name is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: formState.isLoading ? null : _saveVehicle,
                        child: formState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Vehicle'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_showForm) const SizedBox(height: 24),

          // Error message
          if (formState.error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      formState.error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          if (formState.error != null) const SizedBox(height: 16),

          // Vehicle list
          if (listState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (listState.error != null)
            EmptyState(
              title: 'Error',
              subtitle: listState.error!,
              icon: Icons.error_outline,
              onAction: () => ref
                  .read(vehicleListProvider.notifier)
                  .load(includeInactive: true),
              actionLabel: 'Retry',
            )
          else if (listState.vehicles.isEmpty)
            EmptyState(
              title: 'No Vehicles',
              subtitle: 'Create your first vehicle to get started',
              icon: Icons.directions_car_outlined,
            )
          else
            GridView.count(
              crossAxisCount: isDesktop ? 3 : 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isDesktop ? 1.2 : 1.4,
              children: listState.vehicles.map((vehicle) {
                return TerraCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicle.vehicleNumber,
                                  style: theme.textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  vehicle.vehicleName,
                                  style: theme.textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vehicle.driverName,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: AppColors.grey500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: vehicle.isActive
                                  ? AppColors.successSurface
                                  : AppColors.errorSurface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              vehicle.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: vehicle.isActive
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      // Info
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: AppColors.grey500,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            vehicle.createdAt.toString().split(' ')[0],
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppColors.grey500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _editVehicle(
                              vehicle.id,
                              vehicle.vehicleNumber,
                              vehicle.vehicleName,
                              vehicle.driverName,
                            ),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                          ),
                          TextButton.icon(
                            onPressed: () => _deleteVehicle(vehicle.id),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
