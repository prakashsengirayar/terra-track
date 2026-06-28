// lib/presentation/pages/agri/lands_page.dart
//
// Lands list + add/edit form for the agri module. Replaces no mock data —
// this is a brand-new screen reading live from Firestore via
// landsStreamProvider(uid) and writing through landFormProvider, following
// the same StreamProvider/StateNotifier<AsyncValue> wiring used by every
// other agri screen.

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
import '../../bloc/agri/land_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/agri/agri_form_widgets.dart';

const _uuid = Uuid();

class LandsPage extends ConsumerWidget {
  const LandsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final uid = ref.watch(currentAgriUidProvider);

    if (uid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final landsAsync = ref.watch(landsStreamProvider(uid));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openLandForm(context, uid: uid),
        child: const Icon(Icons.add),
      ),
      body: landsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => AgriErrorState(message: err.toString()),
        data: (lands) {
          if (lands.isEmpty) {
            return EmptyState(
              title: l.noLands,
              subtitle: l.noLandsSubtitle,
              icon: Icons.terrain_outlined,
              onAction: () => _openLandForm(context, uid: uid),
              actionLabel: l.addLand,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: lands.length,
            itemBuilder: (_, i) {
              final land = lands[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LandTile(
                  land: land,
                  onTap: () => _openLandForm(context, uid: uid, existing: land),
                  onDelete: () => _deleteLand(context, ref, land),
                ),
              ).animate().fadeIn(duration: 250.ms, delay: (i * 30).ms).slideX(begin: -0.03);
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteLand(BuildContext context, WidgetRef ref, LandEntity land) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showAgriDeleteConfirm(context, l.deleteLandConfirm);
    if (!confirmed) return;
    final ok = await ref.read(landFormProvider.notifier).deleteLand(land.id);
    if (!ok && context.mounted) {
      showAgriSnack(context, error: ref.read(landFormProvider).error ?? l.errorOccurred);
    }
  }

  void _openLandForm(BuildContext context, {required String uid, LandEntity? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LandFormSheet(uid: uid, existing: existing),
    );
  }
}

class _LandTile extends StatelessWidget {
  final LandEntity land;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _LandTile({required this.land, required this.onTap, required this.onDelete});

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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                image: (land.photoUrl != null && land.photoUrl!.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(land.photoUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: (land.photoUrl == null || land.photoUrl!.isEmpty)
                  ? const Icon(Icons.terrain, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(land.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.place_outlined, size: 14, color: AppColors.grey500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(land.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.grey500)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Chip(label: '${land.areaInAcres} ${l.landAreaHint}'),
                      _Chip(label: land.soilType),
                      if (land.currentCrop != null && land.currentCrop!.isNotEmpty)
                        _Chip(label: land.currentCrop!, color: AppColors.secondary),
                    ],
                  ),
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
  final Color? color;
  const _Chip({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
    );
  }
}

class _LandFormSheet extends ConsumerStatefulWidget {
  final String uid;
  final LandEntity? existing;
  const _LandFormSheet({required this.uid, this.existing});

  @override
  ConsumerState<_LandFormSheet> createState() => _LandFormSheetState();
}

class _LandFormSheetState extends ConsumerState<_LandFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _areaCtrl;
  late final TextEditingController _soilCtrl;
  late final TextEditingController _cropCtrl;
  late final TextEditingController _notesCtrl;

  Uint8List? _newPhotoBytes;
  bool _photoRemoved = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _locationCtrl = TextEditingController(text: e?.location ?? '');
    _areaCtrl = TextEditingController(text: e != null ? e.areaInAcres.toString() : '');
    _soilCtrl = TextEditingController(text: e?.soilType ?? '');
    _cropCtrl = TextEditingController(text: e?.currentCrop ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _areaCtrl.dispose();
    _soilCtrl.dispose();
    _cropCtrl.dispose();
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

    final id = widget.existing?.id ?? _uuid.v4();
    String? photoUrl = _photoRemoved ? null : widget.existing?.photoUrl;

    if (_newPhotoBytes != null) {
      try {
        photoUrl = await ref.read(agriStorageServiceProvider).uploadPhoto(
              _newPhotoBytes!,
              '${AgriConstants.landPhotosPath}/$id.jpg',
            );
      } catch (e) {
        if (mounted) showAgriSnack(context, error: e);
        return;
      }
    }

    final now = DateTime.now();
    final land = LandEntity(
      id: id,
      ownerId: widget.uid,
      name: _nameCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      areaInAcres: double.tryParse(_areaCtrl.text.trim()) ?? 0,
      soilType: _soilCtrl.text.trim(),
      currentCrop: _cropCtrl.text.trim().isEmpty ? null : _cropCtrl.text.trim(),
      photoUrl: photoUrl,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );

    final notifier = ref.read(landFormProvider.notifier);
    final ok = _isEdit ? await notifier.updateLand(land) : await notifier.addLand(land);

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      showAgriSnack(context, error: ref.read(landFormProvider).error ?? l.errorOccurred);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formState = ref.watch(landFormProvider);
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
                Text(_isEdit ? l.editLand : l.addLand,
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
                    placeholderIcon: Icons.terrain,
                  ),
                ),
                const SizedBox(height: 20),
                AgriField(
                  controller: _nameCtrl,
                  label: l.landName,
                  hint: l.landNameHint,
                  icon: Icons.terrain_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty) ? l.landNameHint : null,
                ),
                const SizedBox(height: 16),
                AgriField(
                  controller: _locationCtrl,
                  label: l.landLocation,
                  hint: l.landLocationHint,
                  icon: Icons.place_outlined,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l.landLocationHint : null,
                ),
                const SizedBox(height: 16),
                AgriField(
                  controller: _areaCtrl,
                  label: l.landArea,
                  hint: l.landAreaHint,
                  icon: Icons.square_foot_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    if (n == null || n <= 0) return l.landAreaHint;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AgriField(
                  controller: _soilCtrl,
                  label: l.soilType,
                  hint: l.soilTypeHint,
                  icon: Icons.layers_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty) ? l.soilTypeHint : null,
                ),
                const SizedBox(height: 16),
                AgriField(
                  controller: _cropCtrl,
                  label: l.currentCrop,
                  hint: l.currentCropHint,
                  icon: Icons.eco_outlined,
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
