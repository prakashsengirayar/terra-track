// lib/presentation/pages/agri/expenses_harvests_page.dart
//
// Combined Expenses + Harvests screen (one tab each) for the agri module.
// Both tabs follow the same StreamProvider/StateNotifier<AsyncValue> wiring
// as the other 3 agri screens; they're combined into a single screen (with
// an internal TabBar) per the original 4-screen layout
// (Lands / Workers / Work Entries / Expenses & Harvests).

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
import '../../bloc/agri/expense_provider.dart';
import '../../bloc/agri/harvest_provider.dart';
import '../../bloc/agri/land_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/agri/agri_form_widgets.dart';

const _uuid = Uuid();

String _categoryLabel(AppLocalizations l, ExpenseCategory c) {
  switch (c) {
    case ExpenseCategory.seeds:
      return l.categorySeeds;
    case ExpenseCategory.fertilizer:
      return l.categoryFertilizer;
    case ExpenseCategory.pesticide:
      return l.categoryPesticide;
    case ExpenseCategory.labor:
      return l.categoryLabor;
    case ExpenseCategory.equipment:
      return l.categoryEquipment;
    case ExpenseCategory.irrigation:
      return l.categoryIrrigation;
    case ExpenseCategory.transport:
      return l.categoryTransport;
    case ExpenseCategory.other:
      return l.categoryOther;
  }
}

class ExpensesHarvestsPage extends ConsumerStatefulWidget {
  const ExpensesHarvestsPage({super.key});

  @override
  ConsumerState<ExpensesHarvestsPage> createState() => _ExpensesHarvestsPageState();
}

class _ExpensesHarvestsPageState extends ConsumerState<ExpensesHarvestsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final uid = ref.watch(currentAgriUidProvider);

    if (uid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          Material(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.grey500,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: l.expenses, icon: const Icon(Icons.receipt_long_outlined)),
                Tab(text: l.harvests, icon: const Icon(Icons.agriculture_outlined)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ExpensesTab(uid: uid),
                _HarvestsTab(uid: uid),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _openExpenseForm(context, uid: uid);
          } else {
            _openHarvestForm(context, uid: uid);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

void _openExpenseForm(BuildContext context, {required String uid, ExpenseEntity? existing}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ExpenseFormSheet(uid: uid, existing: existing),
  );
}

void _openHarvestForm(BuildContext context, {required String uid, HarvestEntity? existing}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _HarvestFormSheet(uid: uid, existing: existing),
  );
}

// =====================================================================
// Expenses tab
// =====================================================================
class _ExpensesTab extends ConsumerWidget {
  final String uid;
  const _ExpensesTab({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final expensesAsync = ref.watch(expensesStreamProvider(uid));

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => AgriErrorState(message: err.toString()),
      data: (expenses) {
        if (expenses.isEmpty) {
          return EmptyState(
            title: l.noExpenses,
            subtitle: l.noExpensesSubtitle,
            icon: Icons.receipt_long_outlined,
            onAction: () => _openExpenseForm(context, uid: uid),
            actionLabel: l.addExpense,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          itemCount: expenses.length,
          itemBuilder: (_, i) {
            final expense = expenses[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ExpenseTile(
                expense: expense,
                onTap: () => _openExpenseForm(context, uid: uid, existing: expense),
                onDelete: () => _deleteExpense(context, ref, expense),
              ),
            ).animate().fadeIn(duration: 250.ms, delay: (i * 30).ms).slideX(begin: -0.03);
          },
        );
      },
    );
  }

  Future<void> _deleteExpense(BuildContext context, WidgetRef ref, ExpenseEntity expense) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showAgriDeleteConfirm(context, l.deleteExpenseConfirm);
    if (!confirmed) return;
    final ok = await ref.read(expenseFormProvider.notifier).deleteExpense(expense.id);
    if (!ok && context.mounted) {
      showAgriSnack(context, error: ref.read(expenseFormProvider).error ?? l.errorOccurred);
    }
  }
}

class _ExpenseTile extends StatelessWidget {
  final ExpenseEntity expense;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _ExpenseTile({required this.expense, required this.onTap, required this.onDelete});

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
                color: AppColors.errorSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_upward, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    expense.landName ?? DateFormat('dd MMM yyyy').format(expense.date),
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.grey500),
                  ),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    _Chip(label: _categoryLabel(l, expense.category)),
                    _Chip(
                        label: DateFormat('dd MMM yyyy').format(expense.date),
                        color: AppColors.grey500),
                  ]),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('-${expense.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Harvests tab
// =====================================================================
class _HarvestsTab extends ConsumerWidget {
  final String uid;
  const _HarvestsTab({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final harvestsAsync = ref.watch(harvestsStreamProvider(uid));

    return harvestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => AgriErrorState(message: err.toString()),
      data: (harvests) {
        if (harvests.isEmpty) {
          return EmptyState(
            title: l.noHarvests,
            subtitle: l.noHarvestsSubtitle,
            icon: Icons.agriculture_outlined,
            onAction: () => _openHarvestForm(context, uid: uid),
            actionLabel: l.addHarvest,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          itemCount: harvests.length,
          itemBuilder: (_, i) {
            final harvest = harvests[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HarvestTile(
                harvest: harvest,
                onTap: () => _openHarvestForm(context, uid: uid, existing: harvest),
                onDelete: () => _deleteHarvest(context, ref, harvest),
              ),
            ).animate().fadeIn(duration: 250.ms, delay: (i * 30).ms).slideX(begin: -0.03);
          },
        );
      },
    );
  }

  Future<void> _deleteHarvest(BuildContext context, WidgetRef ref, HarvestEntity harvest) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showAgriDeleteConfirm(context, l.deleteHarvestConfirm);
    if (!confirmed) return;
    final ok = await ref.read(harvestFormProvider.notifier).deleteHarvest(harvest.id);
    if (!ok && context.mounted) {
      showAgriSnack(context, error: ref.read(harvestFormProvider).error ?? l.errorOccurred);
    }
  }
}

class _HarvestTile extends StatelessWidget {
  final HarvestEntity harvest;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _HarvestTile({required this.harvest, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
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
                color: AppColors.successSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_downward, color: AppColors.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(harvest.cropName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(harvest.landName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.grey500)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    _Chip(label: '${harvest.quantity} ${harvest.unit}'),
                    _Chip(
                        label: DateFormat('dd MMM yyyy').format(harvest.harvestDate),
                        color: AppColors.grey500),
                  ]),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('+${harvest.totalRevenue.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: AppColors.success, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: onDelete,
                ),
              ],
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

// =====================================================================
// Expense form
// =====================================================================
class _ExpenseFormSheet extends ConsumerStatefulWidget {
  final String uid;
  final ExpenseEntity? existing;
  const _ExpenseFormSheet({required this.uid, this.existing});

  @override
  ConsumerState<_ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<_ExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descriptionCtrl;

  ExpenseCategory _category = ExpenseCategory.other;
  String? _landId;
  String? _landName;
  late DateTime _date;
  Uint8List? _newPhotoBytes;
  bool _photoRemoved = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _amountCtrl = TextEditingController(text: e != null ? e.amount.toString() : '');
    _descriptionCtrl = TextEditingController(text: e?.description ?? '');
    _category = e?.category ?? ExpenseCategory.other;
    _landId = e?.landId;
    _landName = e?.landName;
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
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
    String? receiptUrl = _photoRemoved ? null : widget.existing?.receiptPhotoUrl;

    if (_newPhotoBytes != null) {
      try {
        receiptUrl = await ref.read(agriStorageServiceProvider).uploadPhoto(
              _newPhotoBytes!,
              '${AgriConstants.expenseReceiptsPath}/$id.jpg',
            );
      } catch (e) {
        if (mounted) showAgriSnack(context, error: e);
        return;
      }
    }

    final now = DateTime.now();
    final expense = ExpenseEntity(
      id: id,
      ownerId: widget.uid,
      landId: _landId,
      landName: _landName,
      category: _category,
      amount: double.tryParse(_amountCtrl.text.trim()) ?? 0,
      date: _date,
      description: _descriptionCtrl.text.trim(),
      receiptPhotoUrl: receiptUrl,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );

    final notifier = ref.read(expenseFormProvider.notifier);
    final ok = _isEdit ? await notifier.updateExpense(expense) : await notifier.addExpense(expense);

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      showAgriSnack(context, error: ref.read(expenseFormProvider).error ?? l.errorOccurred);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formState = ref.watch(expenseFormProvider);
    final isLoading = formState.isLoading;
    final landsAsync = ref.watch(landsStreamProvider(widget.uid));

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
                Text(_isEdit ? l.editExpense : l.addExpense,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: AppColors.primaryDark)),
                const SizedBox(height: 20),
                DropdownButtonFormField<ExpenseCategory>(
                  value: _category,
                  decoration: InputDecoration(
                    labelText: l.expenseCategory,
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                  items: ExpenseCategory.values
                      .map((c) => DropdownMenuItem(value: c, child: Text(_categoryLabel(l, c))))
                      .toList(),
                  onChanged: (c) => setState(() => _category = c ?? ExpenseCategory.other),
                ),
                const SizedBox(height: 16),
                AgriField(
                  controller: _amountCtrl,
                  label: l.expenseAmount,
                  icon: Icons.payments_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    if (n == null || n <= 0) return l.expenseAmount;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AgriDateField(
                  label: l.date,
                  value: _date,
                  lastDate: DateTime.now(),
                  onChanged: (d) => setState(() => _date = d),
                ),
                const SizedBox(height: 16),
                landsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, st) => const SizedBox.shrink(),
                  data: (lands) => DropdownButtonFormField<String?>(
                    value: _landId,
                    decoration: InputDecoration(
                      labelText: l.selectLand,
                      prefixIcon: const Icon(Icons.terrain_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('—')),
                      ...lands.map((land) => DropdownMenuItem<String?>(
                            value: land.id,
                            child: Text(land.name, overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (id) {
                      if (id == null) {
                        setState(() {
                          _landId = null;
                          _landName = null;
                        });
                      } else {
                        final land = lands.firstWhere((l) => l.id == id);
                        setState(() {
                          _landId = land.id;
                          _landName = land.name;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                AgriField(
                  controller: _descriptionCtrl,
                  label: l.expenseDescription,
                  hint: l.expenseDescriptionHint,
                  icon: Icons.description_outlined,
                  maxLines: 2,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l.expenseDescriptionHint : null,
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    Text(l.receiptPhoto,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.grey500)),
                    const SizedBox(height: 8),
                    AgriPhotoAvatar(
                      newBytes: _newPhotoBytes,
                      networkUrl: _photoRemoved ? null : widget.existing?.receiptPhotoUrl,
                      onTap: _pickPhoto,
                      onRemove: () => setState(() {
                        _newPhotoBytes = null;
                        _photoRemoved = true;
                      }),
                      placeholderIcon: Icons.receipt_long_outlined,
                    ),
                  ],
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

// =====================================================================
// Harvest form
// =====================================================================
class _HarvestFormSheet extends ConsumerStatefulWidget {
  final String uid;
  final HarvestEntity? existing;
  const _HarvestFormSheet({required this.uid, this.existing});

  @override
  ConsumerState<_HarvestFormSheet> createState() => _HarvestFormSheetState();
}

class _HarvestFormSheetState extends ConsumerState<_HarvestFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cropCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _notesCtrl;

  String? _landId;
  String? _landName;
  late DateTime _harvestDate;
  Uint8List? _newPhotoBytes;
  bool _photoRemoved = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _cropCtrl = TextEditingController(text: e?.cropName ?? '');
    _quantityCtrl = TextEditingController(text: e != null ? e.quantity.toString() : '');
    _unitCtrl = TextEditingController(text: e?.unit ?? '');
    _priceCtrl = TextEditingController(text: e != null ? e.pricePerUnit.toString() : '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _landId = e?.landId;
    _landName = e?.landName;
    _harvestDate = e?.harvestDate ?? DateTime.now();

    _quantityCtrl.addListener(() => setState(() {}));
    _priceCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _cropCtrl.dispose();
    _quantityCtrl.dispose();
    _unitCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _computedRevenue {
    final qty = double.tryParse(_quantityCtrl.text.trim()) ?? 0;
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    return qty * price;
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
    if (_landId == null) return;

    final id = widget.existing?.id ?? _uuid.v4();
    String? photoUrl = _photoRemoved ? null : widget.existing?.photoUrl;

    if (_newPhotoBytes != null) {
      try {
        photoUrl = await ref.read(agriStorageServiceProvider).uploadPhoto(
              _newPhotoBytes!,
              '${AgriConstants.harvestPhotosPath}/$id.jpg',
            );
      } catch (e) {
        if (mounted) showAgriSnack(context, error: e);
        return;
      }
    }

    final now = DateTime.now();
    final harvest = HarvestEntity(
      id: id,
      ownerId: widget.uid,
      landId: _landId!,
      landName: _landName!,
      cropName: _cropCtrl.text.trim(),
      quantity: double.tryParse(_quantityCtrl.text.trim()) ?? 0,
      unit: _unitCtrl.text.trim(),
      pricePerUnit: double.tryParse(_priceCtrl.text.trim()) ?? 0,
      totalRevenue: _computedRevenue,
      harvestDate: _harvestDate,
      photoUrl: photoUrl,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );

    final notifier = ref.read(harvestFormProvider.notifier);
    final ok = _isEdit ? await notifier.updateHarvest(harvest) : await notifier.addHarvest(harvest);

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      showAgriSnack(context, error: ref.read(harvestFormProvider).error ?? l.errorOccurred);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formState = ref.watch(harvestFormProvider);
    final isLoading = formState.isLoading;
    final landsAsync = ref.watch(landsStreamProvider(widget.uid));

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
                Text(_isEdit ? l.editHarvest : l.addHarvest,
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
                AgriField(
                  controller: _cropCtrl,
                  label: l.cropName,
                  hint: l.cropNameHint,
                  icon: Icons.eco_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty) ? l.cropNameHint : null,
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: AgriField(
                      controller: _quantityCtrl,
                      label: l.quantity,
                      hint: l.quantityHint,
                      icon: Icons.scale_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final n = double.tryParse(v?.trim() ?? '');
                        if (n == null || n <= 0) return l.quantityHint;
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AgriField(
                      controller: _unitCtrl,
                      label: l.unit,
                      hint: l.unitHint,
                      icon: Icons.straighten_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? l.unitHint : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                AgriField(
                  controller: _priceCtrl,
                  label: l.pricePerUnit,
                  hint: l.pricePerUnitHint,
                  icon: Icons.sell_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    if (n == null || n <= 0) return l.pricePerUnitHint;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l.totalRevenue,
                    prefixIcon: const Icon(Icons.payments_outlined),
                  ),
                  child: Text(
                    _computedRevenue.toStringAsFixed(2),
                    style: const TextStyle(
                        color: AppColors.success, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 16),
                AgriDateField(
                  label: l.harvestDate,
                  value: _harvestDate,
                  lastDate: DateTime.now(),
                  onChanged: (d) => setState(() => _harvestDate = d),
                ),
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
                    placeholderIcon: Icons.agriculture_outlined,
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
