import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/entities.dart';
import '../../bloc/admin/admin_provider.dart';
import '../../widgets/common/common_widgets.dart';

class AddEntryPage extends ConsumerStatefulWidget {
  const AddEntryPage({super.key});
  @override
  ConsumerState<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends ConsumerState<AddEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String? _selectedVehicleId;
  String? _selectedVehicleName;
  AdminEntryType _entryType = AdminEntryType.diesel;

  @override
  void dispose() {
    _amountCtrl.dispose(); _noteCtrl.dispose(); _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle')));
      return;
    }
    final ok = await ref.read(adminEntryFormProvider.notifier).submitEntry(
      vehicleId: _selectedVehicleId!,
      vehicleName: _selectedVehicleName!,
      entryType: _entryType,
      amount: double.parse(_amountCtrl.text),
      note: _noteCtrl.text.trim(),
      date: _date,
      messageText: _messageCtrl.text.trim(),
    );
    if (ok && mounted) {
      _formKey.currentState!.reset();
      _amountCtrl.clear(); _noteCtrl.clear(); _messageCtrl.clear();
      setState(() { _selectedVehicleId = null; _date = DateTime.now(); });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry saved'), backgroundColor: AppColors.success));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final vehicles = ref.watch(allVehiclesProvider);
    final formState = ref.watch(adminEntryFormProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.addEntry, style: theme.textTheme.headlineSmall
              ?.copyWith(color: AppColors.primaryDark)),
          const SizedBox(height: 16),

          TerraCard(child: Column(children: [
            // Vehicle dropdown
            vehicles.when(
              data: (list) => DropdownButtonFormField<String>(
                initialValue: _selectedVehicleId,
                decoration: InputDecoration(
                  labelText: l.selectVehicle,
                  prefixIcon: const Icon(Icons.directions_car_outlined),
                ),
                items: list.map((v) => DropdownMenuItem(
                  value: v.id,
                  child: Text('${v.vehicleName} — ${v.driverName}'),
                )).toList(),
                onChanged: (id) {
                  if (id == null) return;
                  final v = list.firstWhere((e) => e.id == id);
                  setState(() {
                    _selectedVehicleId = id;
                    _selectedVehicleName = v.vehicleName;
                  });
                },
                validator: (v) => v == null ? l.selectVehicle : null,
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => Text(l.errorOccurred),
            ),
            const SizedBox(height: 12),

            // Entry type
            DropdownButtonFormField<AdminEntryType>(
              initialValue: _entryType,
              decoration: InputDecoration(
                labelText: l.entryType,
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              items: AdminEntryType.values.map((t) => DropdownMenuItem(
                value: t,
                child: Text(_typeLabel(t, l)),
              )).toList(),
              onChanged: (t) => setState(() => _entryType = t!),
            ),
            const SizedBox(height: 12),

            // Amount + Date row
            Row(children: [
              Expanded(child: TextFormField(
                controller: _amountCtrl,
                decoration: InputDecoration(
                  labelText: l.amount,
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (v == null || v.isEmpty) ? l.rateRequired : null,
              )),
              const SizedBox(width: 12),
              Expanded(child: InkWell(
                onTap: () async {
                  final p = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (p != null) setState(() => _date = p);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l.date,
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    '${_date.day.toString().padLeft(2,'0')}/${_date.month.toString().padLeft(2,'0')}/${_date.year}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )),
            ]),
            const SizedBox(height: 12),

            TextFormField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                labelText: l.note,
                prefixIcon: const Icon(Icons.note_outlined),
              ),
            ),
          ])),
          const SizedBox(height: 16),

          // Message section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.message_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(l.messageToOwner, style: theme.textTheme.titleSmall),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageCtrl,
                  decoration: InputDecoration(
                    hintText: l.messagePlaceholder,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                Text('Message will appear as a notification in the driver\'s app',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.grey500)),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          if (formState.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(formState.error!, style: const TextStyle(color: AppColors.error)),
            ),

          ElevatedButton.icon(
            onPressed: formState.isLoading ? null : _save,
            icon: formState.isLoading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: Text(formState.isLoading ? l.saving : l.send),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  String _typeLabel(AdminEntryType t, AppLocalizations l) {
    switch (t) {
      case AdminEntryType.diesel: return l.diesel;
      case AdminEntryType.food: return l.food;
      case AdminEntryType.maintenance: return l.maintenance;
      case AdminEntryType.vehicleAdvance: return l.vehicleAdvance;
      case AdminEntryType.others: return l.others;
    }
  }
}
