// lib/presentation/pages/agri/work_entries_page.dart
//
// Agri work-entry list + add/edit form. Distinct from the existing vehicle/
// customer work-log screens — this models a day's farm work tying a Land
// and a Worker together. The add/edit form reads landsStreamProvider and
// workersStreamProvider to populate selection dropdowns, matching the
// land/worker pickers described in the original spec.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/agri_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/agri_entities.dart';
import '../../bloc/agri/agri_auth_provider.dart';
import '../../bloc/agri/agri_repository_providers.dart';
import '../../bloc/agri/agri_work_entry_provider.dart';
import '../../bloc/agri/land_provider.dart';
import '../../bloc/agri/worker_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/agri/agri_form_widgets.dart';

const _uuid = Uuid();

class WorkEntriesPage extends ConsumerWidget {
  const WorkEntriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final uid = ref.watch(currentAgriUidProvider);

    if (uid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final entriesAsync = ref.watch(agriWorkEntriesStreamProvider(uid));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEntryForm(context, uid: uid),
        child: const Icon(Icons.add),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => AgriErrorState(message: err.toString()),
        data: (entries) {
          if (entries.isEmpty) {
            return EmptyState(
              title: l.noWorkEntriesAgri,
              subtitle: l.noWorkEntriesAgriSubtitle,
              icon: Icons.work_outline,
              onAction: () => _openEntryForm(context, uid: uid),
              actionLabel: l.addWorkEntryAgri,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: entries.length,
            itemBuilder: (_, i) {
              final entry = entries[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _WorkEntryTile(
                  entry: entry,
                  onTap: () => _openEntryForm(context, uid: uid, existing: entry),
                  onDelete: () => _deleteEntry(context, ref, entry),
                ),
              ).animate().fadeIn(duration: 250.ms, delay: (i * 30).ms).slideX(begin: -0.03);
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteEntry(
      BuildContext context, WidgetRef ref, AgriWorkEntryEntity entry) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showAgriDeleteConfirm(context, l.deleteWorkEntryAgriConfirm);
    if (!confirmed) return;
    final ok = await ref.read(agriWorkEntryFormProvider.notifier).deleteWorkEntry(entry.id);
    if (!ok && context.mounted) {
      showAgriSnack(context,
          error: ref.read(agriWorkEntryFormProvider).error ?? l.errorOccurred);
    }
  }

  void _openEntryForm(BuildContext context,
      {required String uid, AgriWorkEntryEntity? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _WorkEntryFormSheet(uid: uid, existing: existing),
    );
  }
}

class _WorkEntryTile extends StatelessWidget {
  final AgriWorkEntryEntity entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WorkEntryTile({required this.entry, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return TerraCard(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.work_outline, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.workDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${entry.landName} • ${entry.workerName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.grey500)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    _Chip(
                        label: DateFormat('dd MMM yyyy').format(entry.date),
                        icon: Icons.calendar_today_outlined),
                    _Chip(
                        label: '${entry.hoursWorked} ${l.hoursWorkedAgri}',
                        icon: Icons.timer_outlined),
                    _Chip(
                        label: '${l.wageAmount}: ${entry.wageAmount.toStringAsFixed(0)}',
                        icon: Icons.payments_outlined,
                        color: AppColors.secondary),
                  ]),
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

class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  const _Chip({required this.label, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) Icon(icon, size: 12, color: c),
        if (icon != null) const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _WorkEntryFormSheet extends ConsumerStatefulWidget {
  final String uid;
  final AgriWorkEntryEntity? existing;
  const _WorkEntryFormSheet({required this.uid, this.existing});

  @override
  ConsumerState<_WorkEntryFormSheet> createState() => _WorkEntryFormSheetState();
}

class _WorkEntryFormSheetState extends ConsumerState<_WorkEntryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _hoursCtrl;
  late final TextEditingController _wageCtrl;
  late final TextEditingController _notesCtrl;

  String? _landId;
  String? _landName;
  String? _workerId;
  String? _workerName;
  late DateTime _date;
  Uint8List? _newPhotoBytes;
  bool _photoRemoved = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _descriptionCtrl = TextEditingController(text: e?.workDescription ?? '');
    _hoursCtrl = TextEditingController(text: e != null ? e.hoursWorked.toString() : '');
    _wageCtrl = TextEditingController(text: e != null ? e.wageAmount.toString() : '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _landId = e?.landId;
    _landName = e?.landName;
    _workerId = e?.workerId;
    _workerName = e?.workerName;
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _hoursCtrl.dispose();
    _wageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final bytes = await pickAgriPhotoBytes(context);
    if (bytes != null) {
      setState(() {
        _newPhotoBytes = bytes;
        _photoRemoved = false;
      });
    }
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_landId == null || _workerId == null) return;

    final id = widget.existing?.id ?? _uuid.v4();
    String? photoUrl = _photoRemoved ? null : widget.existing?.photoUrl;

    if (_newPhotoBytes != null) {
      try {
        photoUrl = await ref.read(agriStorageServiceProvider).uploadPhoto(
              _newPhotoBytes!,
              '${AgriConstants.workEntryPhotosPath}/$id.jpg',
            );
      } catch (e) {
        if (mounted) showAgriSnack(context, error: e);
        return;
      }
    }

    final now = DateTime.now();
    final entry = AgriWorkEntryEntity(
      id: id,
      ownerId: widget.uid,
      landId: _landId!,
      landName: _landName!,
      workerId: _workerId!,
      workerName: _workerName!,
      workDescription: _descriptionCtrl.text.trim(),
      date: _date,
      hoursWorked: double.tryParse(_hoursCtrl.text.trim()) ?? 0,
      wageAmount: double.tryParse(_wageCtrl.text.trim()) ?? 0,
      photoUrl: photoUrl,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );

    final notifier = ref.read(agriWorkEntryFormProvider.notifier);
    final ok =
        _isEdit ? await notifier.updateWorkEntry(entry) : await notifier.addWorkEntry(entry);

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      showAgriSnack(context,
          error: ref.read(agriWorkEntryFormProvider).error ?? l.errorOccurred);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formState = ref.watch(agriWorkEntryFormProvider);
    final isLoading = formState.isLoading;
    final landsAsync = ref.watch(landsStreamProvider(widget.uid));
    final workersAsync = ref.watch(workersStreamProvider(widget.uid));

    return LoadingOverlay(
      isLoading: isLoading,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(_isEdit ? l.editWorkEntryAgri : l.addWorkEntryAgri,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: AppColors.primaryDark)),
                const SizedBox(height: 20),
                landsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, st) => Text(e.toString(),
                      style: const TextStyle(color: AppColors.error)),
                  data: (lands) => DropdownButtonFormField<String>(
                    value: _landId,
                    decoration: InputDecoration(
                      labelText: l.selectLand,
                      prefixIcon: const Icon(Icons.terrain_outlined),
                    ),
                    items: lands
                        .map((land) => DropdownMenuItem(
                              value: land.id,
                              child: Text(land.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (id) {
                      final land = lands.firstWhere((l) => l.id == id);
                      setState(() {
                        _landId = land.id;
                        _landName = land.name;
                      });
                    },
                    validator: (v) => v == null ? l.selectLand : null,
                  ),
                ),
                const SizedBox(height: 16),
                workersAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, st) => Text(e.toString(),
                      style: const TextStyle(color: AppColors.error)),
                  data: (workers) => DropdownButtonFormField<String>(
                    value: _workerId,
                    decoration: InputDecoration(
                      labelText: l.selectWorker,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    items: workers
                        .map((worker) => DropdownMenuItem(
                              value: worker.id,
                              child: Text(worker.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (id) {
                      final worker = workers.firstWhere((w) => w.id == id);
                      setState(() {
                        _workerId = worker.id;
                        _workerName = worker.name;
                        if (_wageCtrl.text.trim().isEmpty) {
                          _wageCtrl.text = worker.dailyWage.toString();
                        }
                      });
                    },
                    validator: (v) => v == null ? l.selectWorker : null,
                  ),
                ),
                const SizedBox(height: 16),
                AgriField(
                  controller: _descriptionCtrl,
                  label: l.workDescription,
                  hint: l.workDescriptionHint,
                  icon: Icons.description_outlined,
                  maxLines: 2,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l.workDescriptionHint : null,
                ),
                const SizedBox(height: 16),
                AgriDateField(
                  label: l.date,
                  value: _date,
                  lastDate: DateTime.now(),
                  onChanged: (d) => setState(() => _date = d),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: AgriField(
                      controller: _hoursCtrl,
                      label: l.hoursWorkedAgri,
                      icon: Icons.timer_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final n = double.tryParse(v?.trim() ?? '');
                        if (n == null || n <= 0) return l.hoursWorkedAgri;
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AgriField(
                      controller: _wageCtrl,
                      label: l.wageAmount,
                      icon: Icons.payments_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final n = double.tryParse(v?.trim() ?? '');
                        if (n == null || n < 0) return l.wageAmount;
                        return null;
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                Center(
                  child: AgriPhotoAvatar(
                    newBytes: _newPhotoBytes,
                    networkUrl: _photoRemoved ? null : widget.existing?.photoUrl,
                    onTap: _pickPhoto,
                    onRemove: () => setState(() {
                      _newPhotoBytes = null;
                      _photoRemoved = true;
                    }),
                    placeholderIcon: Icons.camera_alt_outlined,
                  ),
                ),
                const SizedBox(height: 16),
                AgriField(
                  controller: _notesCtrl,
                  label: l.notes,
                  hint: l.notesHint,
                  icon: Icons.notes_outlined,
                  maxLines: 3,
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
