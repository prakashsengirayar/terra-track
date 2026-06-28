// lib/presentation/pages/agri/add_vehicle_page.dart
//
// Add/edit screen for a single agri vehicle. Pushed as a normal full-screen
// route from vehicles_page.dart (rather than the modal-bottom-sheet pattern
// used by Lands/Workers/Expenses/Harvests) since the vehicle form is just
// two short fields with no photo. Reused for both add and edit by accepting
// an optional `existing` vehicle.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../domain/entities/agri_entities.dart';
import '../../bloc/agri/agri_vehicle_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/agri/agri_form_widgets.dart';

const _uuid = Uuid();

class AddVehiclePage extends ConsumerStatefulWidget {
  final String uid;
  final AgriVehicleEntity? existing;
  const AddVehiclePage({super.key, required this.uid, this.existing});

  @override
  ConsumerState<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends ConsumerState<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _numberCtrl;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.vehicleName ?? '');
    _numberCtrl = TextEditingController(text: e?.vehicleNumber ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    final id = widget.existing?.id ?? _uuid.v4();
    final now = DateTime.now();
    final vehicle = AgriVehicleEntity(
      id: id,
      ownerId: widget.uid,
      vehicleName: _nameCtrl.text.trim(),
      vehicleNumber: _numberCtrl.text.trim().toUpperCase(),
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );

    final notifier = ref.read(agriVehicleFormProvider.notifier);
    final ok = _isEdit
        ? await notifier.updateVehicle(vehicle)
        : await notifier.addVehicle(vehicle);

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      showAgriSnack(context,
          error: ref.read(agriVehicleFormProvider).error ?? l.errorOccurred);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formState = ref.watch(agriVehicleFormProvider);
    final isLoading = formState.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l.editVehicle : l.addVehicle)),
      body: LoadingOverlay(
        isLoading: isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AgriField(
                  controller: _nameCtrl,
                  label: l.agriVehicleName,
                  hint: l.agriVehicleNameHint,
                  icon: Icons.directions_car_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l.agriVehicleNameHint
                      : null,
                ),
                const SizedBox(height: 16),
                AgriField(
                  controller: _numberCtrl,
                  label: l.agriVehicleNumber,
                  hint: l.agriVehicleNumberHint,
                  icon: Icons.confirmation_number_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l.agriVehicleNumberHint
                      : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: Text(l.saveChanges),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
