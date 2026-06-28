import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/entities.dart';
import '../../bloc/providers.dart';
import '../../widgets/common/common_widgets.dart';

class EntryDetailPage extends ConsumerStatefulWidget {
  final String entryId;
  const EntryDetailPage({super.key, required this.entryId});
  @override
  ConsumerState<EntryDetailPage> createState() => _EntryDetailPageState();
}

class _EntryDetailPageState extends ConsumerState<EntryDetailPage> {
  final _paidCtrl = TextEditingController();
  WorkEntryEntity? _entry;
  bool _loading = true;
  bool _saving = false;
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  double get _balance {
    final paid = double.tryParse(_paidCtrl.text) ?? _entry?.paidAmount ?? 0;
    final total = _entry?.totalAmount ?? 0;
    final b = total - paid;
    return b < 0 ? 0 : b;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await ref.read(workEntryRepositoryProvider)
        .getEntryById(widget.entryId);
    result.fold(
      (_) => setState(() => _loading = false),
      (entry) {
        setState(() {
          _entry = entry;
          _paidCtrl.text = entry.paidAmount.toStringAsFixed(0);
          _loading = false;
        });
      },
    );
  }

  Future<void> _update() async {
    if (_entry == null) return;
    setState(() => _saving = true);
    final paid = double.tryParse(_paidCtrl.text) ?? _entry!.paidAmount;
    final balance = (_entry!.totalAmount - paid).clamp(0, double.infinity) as double;
    final updated = _entry!.copyWith(
      paidAmount: paid,
      balanceAmount: balance,
      status: balance <= 0 ? PaymentStatus.paid : PaymentStatus.pending,
      updatedAt: DateTime.now(),
    );
    final result = await ref.read(updateWorkEntryUseCaseProvider).call(updated);
    setState(() => _saving = false);
    if (mounted) {
      result.fold(
        (f) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(f.message))),
        (_) {
          setState(() => _entry = updated);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Payment updated'),
                backgroundColor: AppColors.success),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _paidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.entryDetail),
        actions: [
          if (_entry != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: StatusBadge(isPaid: _entry!.status == PaymentStatus.paid),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entry == null
              ? EmptyState(title: l.errorOccurred, subtitle: l.noData)
              : _buildBody(l, theme),
    );
  }

  Widget _buildBody(AppLocalizations l, ThemeData theme) {
    final e = _entry!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Customer card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              _CustomerAvatar(entry: e),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.customerName, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(e.nativePlace,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.grey500)),
                  if (e.customerPhone.isNotEmpty)
                    Text('+91 ${e.customerPhone}',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary)),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),

        // Details grid
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _row(theme, l.date,
                  '${e.date.day.toString().padLeft(2,'0')}/${e.date.month.toString().padLeft(2,'0')}/${e.date.year}'),
              _row(theme, l.vehicleNameField, e.vehicleName),
              _row(theme, l.hoursWorked, e.formattedHours),
              _row(theme, l.ratePerHour, _currency.format(e.ratePerHour) + '/hr'),
              const Divider(height: 24),
              _row(theme, l.totalAmount, _currency.format(e.totalAmount),
                  valueColor: AppColors.primary),
            ]),
          ),
        ),
        const SizedBox(height: 12),

        // Balance card
        Card(
          color: _balance > 0 ? AppColors.errorSurface : AppColors.successSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: _balance > 0 ? AppColors.error : AppColors.success,
                width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(_balance > 0 ? Icons.warning_amber_outlined : Icons.check_circle_outline,
                  color: _balance > 0 ? AppColors.error : AppColors.success, size: 28),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.balanceAmount,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: _balance > 0 ? AppColors.error : AppColors.success)),
                Text(_currency.format(_balance),
                    style: theme.textTheme.headlineSmall?.copyWith(
                        color: _balance > 0 ? AppColors.error : AppColors.success,
                        fontWeight: FontWeight.w700)),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // Edit paid amount
        Text(l.updatePayment,
            style: theme.textTheme.titleSmall?.copyWith(color: AppColors.grey700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _paidCtrl,
          decoration: InputDecoration(
            labelText: l.paidAmount,
            prefixIcon: const Icon(Icons.currency_rupee),
            helperText: l.onlyPaidEditable,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),

        // Actions row
        Row(children: [
          if (e.billPhotoUrl != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _viewBill(e.billPhotoUrl!),
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(l.viewBill),
              ),
            ),
          if (e.billPhotoUrl != null) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _update,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? l.saving : l.update),
            ),
          ),
        ]),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _row(ThemeData theme, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.grey500)),
        const Spacer(),
        Text(value,
            style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? Theme.of(context).colorScheme.onSurface)),
      ]),
    );
  }

  void _viewBill(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AppBar(
            title: const Text('Bill Photo'),
            automaticallyImplyLeading: false,
            actions: [IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context))],
          ),
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (_, __) => const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator()),
            errorWidget: (_, __, ___) => const Icon(Icons.error),
          ),
        ]),
      ),
    );
  }
}

class _CustomerAvatar extends StatelessWidget {
  final WorkEntryEntity entry;
  const _CustomerAvatar({required this.entry});

  @override
  Widget build(BuildContext context) {
    if (entry.customerPhotoUrl != null) {
      return CircleAvatar(
        radius: 30,
        backgroundImage: CachedNetworkImageProvider(entry.customerPhotoUrl!),
      );
    }
    return CircleAvatar(
      radius: 30,
      backgroundColor: AppColors.primarySurface,
      child: Text(
        entry.customerName.isNotEmpty ? entry.customerName[0].toUpperCase() : '?',
        style: const TextStyle(
            color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 22),
      ),
    );
  }
}
