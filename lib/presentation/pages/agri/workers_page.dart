// lib/presentation/pages/agri/workers_page.dart
//
// Workers list + add/edit form for the agri module. Same StreamProvider /
// StateNotifier<AsyncValue> wiring pattern as lands_page.dart.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/agri_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/agri_entities.dart';
import '../../bloc/agri/agri_auth_provider.dart';
import '../../bloc/agri/agri_repository_providers.dart';
import '../../bloc/agri/worker_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/agri/agri_form_widgets.dart';

const _uuid = Uuid();

class WorkersPage extends ConsumerWidget {
  const WorkersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final uid = ref.watch(currentAgriUidProvider);

    if (uid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final workersAsync = ref.watch(workersStreamProvider(uid));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openWorkerForm(context, uid: uid),
        child: const Icon(Icons.add),
      ),
      body: workersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => AgriErrorState(message: err.toString()),
        data: (workers) {
          if (workers.isEmpty) {
            return EmptyState(
              title: l.noWorkers,
              subtitle: l.noWorkersSubtitle,
              icon: Icons.groups_outlined,
              onAction: () => _openWorkerForm(context, uid: uid),
              actionLabel: l.addWorker,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: workers.length,
            itemBuilder: (_, i) {
              final worker = workers[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _WorkerTile(
                  worker: worker,
                  onTap: () => _openWorkerForm(context, uid: uid, existing: worker),
                  onDelete: () => _deleteWorker(context, ref, worker),
                ),
              ).animate().fadeIn(duration: 250.ms, delay: (i * 30).ms).slideX(begin: -0.03);
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteWorker(BuildContext context, WidgetRef ref, WorkerEntity worker) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showAgriDeleteConfirm(context, l.deleteWorkerConfirm);
    if (!confirmed) return;
    final ok = await ref.read(workerFormProvider.notifier).deleteWorker(worker.id);
    if (!ok && context.mounted) {
      showAgriSnack(context, error: ref.read(workerFormProvider).error ?? l.errorOccurred);
    }
  }

  void _openWorkerForm(BuildContext context, {required String uid, WorkerEntity? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _WorkerFormSheet(uid: uid, existing: existing),
    );
  }
}

class _WorkerTile extends StatelessWidget {
  final WorkerEntity worker;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WorkerTile({required this.worker, required this.onTap, required this.onDelete});

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
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primarySurface,
              backgroundImage: (worker.photoUrl != null && worker.photoUrl!.isNotEmpty)
                  ? NetworkImage(worker.photoUrl!)
                  : null,
              child: (worker.photoUrl == null || worker.photoUrl!.isEmpty)
                  ? const Icon(Icons.person, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(worker.name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    _ActiveBadge(isActive: worker.isActive),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.call_outlined, size: 14, color: AppColors.grey500),
                    const SizedBox(width: 4),
                    Text(worker.phone,
                        style:
                            theme.textTheme.bodySmall?.copyWith(color: AppColors.grey500)),
                  ]),
                  const SizedBox(height: 6),
                  _Chip(label: '${l.dailyWage}: ${worker.dailyWage.toStringAsFixed(0)}'),
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

class _ActiveBadge extends StatelessWidget {
  final bool isActive;
  const _ActiveBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.successSurface : AppColors.errorSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? l.activeWorker : l.inactiveWorker,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11, color: AppColors.secondaryDark, fontWeight: FontWeight.w600)),
    );
  }
}

class _WorkerFormSheet extends ConsumerStatefulWidget {
  final String uid;
  final WorkerEntity? existing;
  const _WorkerFormSheet({required this.uid, this.existing});

  @override
  ConsumerState<_WorkerFormSheet> createState() => _WorkerFormSheetState();
}

class _WorkerFormSheetState extends ConsumerState<_WorkerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _wageCtrl;
  late final TextEditingController _addressCtrl;

  late DateTime _joinedDate;
  late bool _isActive;
  Uint8List? _newPhotoBytes;
  bool _photoRemoved = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _wageCtrl = TextEditingController(text: e != null ? e.dailyWage.toString() : '');
    _addressCtrl = TextEditingController(text: e?.address ?? '');
    _joinedDate = e?.joinedDate ?? DateTime.now();
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _wageCtrl.dispose();
    _addressCtrl.dispose();
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

    final id = widget.existing?.id ?? _uuid.v4();
    String? photoUrl = _photoRemoved ? null : widget.existing?.photoUrl;

    if (_newPhotoBytes != null) {
      try {
        photoUrl = await ref.read(agriStorageServiceProvider).uploadPhoto(
              _newPhotoBytes!,
              '${AgriConstants.workerPhotosPath}/$id.jpg',
            );
      } catch (e) {
        if (mounted) showAgriSnack(context, error: e);
        return;
      }
    }

    final now = DateTime.now();
    final worker = WorkerEntity(
      id: id,
      ownerId: widget.uid,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      dailyWage: double.tryParse(_wageCtrl.text.trim()) ?? 0,
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      photoUrl: photoUrl,
      isActive: _isActive,
      joinedDate: _joinedDate,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );

    final notifier = ref.read(workerFormProvider.notifier);
    final ok = _isEdit ? await notifier.updateWorker(worker) : await notifier.addWorker(worker);

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      showAgriSnack(context, error: ref.read(workerFormProvider).error ?? l.errorOccurred);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formState = ref.watch(workerFormProvider);
    final isLoading = formState.isLoading;

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
                Text(_isEdit ? l.editWorker : l.addWorker,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: AppColors.primaryDark)),
                const SizedBox(height: 20),
                Center(
                  child: AgriPhotoAvatar(
                    newBytes: _newPhotoBytes,
                    networkUrl: _photoRemoved ? null : widget.existing?.photoUrl,
                    onTap: _pickPhoto,
                    onRemove: () => setState(() {
                      _newPhotoBytes = null;
                      _photoRemoved = true;
                    }),
                    placeholderIcon: Icons.person,
                  ),
                ),
                const SizedBox(height: 20),
                AgriField(
                  controller: _nameCtrl,
                  label: l.workerName,
                  hint: l.workerNameHint,
                  icon: Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l.workerNameHint : null,
                ),
                const SizedBox(height: 16),
                AgriField(
                  controller: _phoneCtrl,
                  label: l.workerPhone,
                  hint: l.workerPhoneHint,
                  icon: Icons.call_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l.workerPhoneHint : null,
                ),
                const SizedBox(height: 16),
                AgriField(
                  controller: _wageCtrl,
                  label: l.dailyWage,
                  hint: l.dailyWageHint,
                  icon: Icons.payments_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    if (n == null || n <= 0) return l.dailyWageHint;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AgriField(
                  controller: _addressCtrl,
                  label: l.workerAddress,
                  hint: l.workerAddressHint,
                  icon: Icons.home_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                AgriDateField(
                  label: l.joinedDate,
                  value: _joinedDate,
                  lastDate: DateTime.now(),
                  onChanged: (d) => setState(() => _joinedDate = d),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: Text(_isActive ? l.activeWorker : l.inactiveWorker),
                ),
                const SizedBox(height: 16),
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
