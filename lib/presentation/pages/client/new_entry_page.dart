import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/auth/auth_provider.dart';
import '../../bloc/work_entry/work_entry_provider.dart';

class NewEntryPage extends ConsumerStatefulWidget {
  const NewEntryPage({super.key});
  @override
  ConsumerState<NewEntryPage> createState() => _NewEntryPageState();
}

class _NewEntryPageState extends ConsumerState<NewEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nativeCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _paidCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final _picker = ImagePicker();
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  double get _totalAmount {
    final secs = ref.read(timerProvider).elapsedSeconds;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    return (secs / 3600.0) * rate;
  }

  double get _balance {
    final paid = double.tryParse(_paidCtrl.text) ?? 0;
    final b = _totalAmount - paid;
    return b < 0 ? 0 : b;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _nativeCtrl.dispose(); _rateCtrl.dispose();
    _paidCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(bool isCustomer) async {
    final xf = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (xf == null) return;
    // Read raw bytes instead of wrapping in a dart:io File — File is
    // unavailable on Flutter Web, while readAsBytes() works on every platform.
    final bytes = await xf.readAsBytes();
    if (isCustomer) {
      ref.read(entryFormProvider.notifier).setCustomerPhotoBytes(bytes);
    } else {
      ref.read(entryFormProvider.notifier).setBillPhotoBytes(bytes);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final timer = ref.read(timerProvider);
    if (timer.status != TimerStatus.stopped || timer.elapsedSeconds == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).startTimerFirst)),
      );
      return;
    }
    final session = ref.read(authProvider).session!;
    final ok = await ref.read(entryFormProvider.notifier).saveEntry(
      customerName: _nameCtrl.text,
      nativePlace: _nativeCtrl.text,
      vehicleName: session.vehicleName,
      driverName: session.driverName,
      ratePerHour: double.parse(_rateCtrl.text),
      timerSeconds: timer.elapsedSeconds,
      paidAmount: double.tryParse(_paidCtrl.text) ?? 0,
      date: _selectedDate,
      customerPhone: _phoneCtrl.text,
    );
    if (ok && mounted) {
      _formKey.currentState!.reset();
      _nameCtrl.clear(); _nativeCtrl.clear(); _rateCtrl.clear();
      _paidCtrl.clear(); _phoneCtrl.clear();
      setState(() => _selectedDate = DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).entrySaved),
            backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final timer = ref.watch(timerProvider);
    final formState = ref.watch(entryFormProvider);
    final session = ref.watch(authProvider).session;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(children: [
          // Customer photo
          _PhotoRow(
            photoBytes: formState.customerPhotoBytes,
            label: l.customerPhoto,
            onTap: () => _pickPhoto(true),
          ),
          const SizedBox(height: 12),

          // Timer card
          _TimerCard(l: l, theme: theme, timer: timer),
          const SizedBox(height: 16),

          // Customer name
          _field(
            ctrl: _nameCtrl,
            label: l.customerName,
            hint: l.customerNameHint,
            icon: Icons.person_outline,
            onChanged: (v) {
              ref.read(entryFormProvider.notifier)
                  .checkCustomerName(v, session?.vehicleName ?? '');
              setState(() {});
            },
            validator: (v) {
              if (v == null || v.trim().isEmpty) return l.customerNameRequired;
              if (v.trim().length < 3) return l.customerNameTooShort;
              if (!formState.isNameUnique) return l.customerNameDuplicate;
              return null;
            },
            suffix: formState.isCheckingName
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : formState.isNameUnique && _nameCtrl.text.isNotEmpty
                    ? const Icon(Icons.check_circle, color: AppColors.success, size: 20)
                    : null,
          ),
          const SizedBox(height: 12),

          // Native with suggestions
          _NativeField(
            ctrl: _nativeCtrl,
            l: l,
            suggestions: formState.nativeSuggestions,
            onChanged: (v) => ref.read(entryFormProvider.notifier).fetchNativeSuggestions(v),
          ),
          const SizedBox(height: 12),

          // Rate per hour
          _field(
            ctrl: _rateCtrl,
            label: l.ratePerHour,
            hint: l.ratePerHourHint,
            icon: Icons.currency_rupee,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return l.rateRequired;
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Total + paid row
          Row(children: [
            Expanded(child: _readonlyField(
              label: l.totalAmount,
              value: _currency.format(_totalAmount),
              color: AppColors.primary,
            )),
            const SizedBox(width: 12),
            Expanded(child: _field(
              ctrl: _paidCtrl,
              label: l.paidAmount,
              hint: l.paidAmountHint,
              icon: Icons.payment_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            )),
          ]),
          const SizedBox(height: 12),

          // Balance
          _readonlyField(
            label: l.balanceAmount,
            value: _currency.format(_balance),
            color: _balance > 0 ? AppColors.error : AppColors.success,
            bgColor: _balance > 0 ? AppColors.errorSurface : AppColors.successSurface,
          ),
          const SizedBox(height: 12),

          // Date + phone row
          Row(children: [
            Expanded(child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l.date,
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  '${_selectedDate.day.toString().padLeft(2, '0')}/'
                  '${_selectedDate.month.toString().padLeft(2, '0')}/'
                  '${_selectedDate.year}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: _field(
              ctrl: _phoneCtrl,
              label: l.customerPhone,
              hint: l.customerPhoneHint,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (v) {
                if (v != null && v.isNotEmpty && v.length != 10) {
                  return l.customerPhoneInvalid;
                }
                return null;
              },
            )),
          ]),
          const SizedBox(height: 12),

          // Vehicle name (locked)
          InputDecorator(
            decoration: InputDecoration(
              labelText: l.vehicleNameField,
              helperText: l.vehicleNameLocked,
              prefixIcon: const Icon(Icons.directions_car_outlined),
              fillColor: AppColors.grey100,
            ),
            child: Text(session?.vehicleName ?? '—',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.grey500)),
          ),
          const SizedBox(height: 12),

          // Bill photo
          _BillPhotoRow(
            photoBytes: formState.billPhotoBytes,
            label: l.billPhoto,
            onTap: () => _pickPhoto(false),
          ),
          const SizedBox(height: 24),

          if (formState.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(formState.error!,
                  style: const TextStyle(color: AppColors.error)),
            ),

          ElevatedButton.icon(
            onPressed: formState.isLoading ? null : _save,
            icon: formState.isLoading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: Text(formState.isLoading ? l.saving : l.saveEntry),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixIcon: suffix,
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _readonlyField({
    required String label,
    required String value,
    Color? color,
    Color? bgColor,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        fillColor: bgColor ?? AppColors.grey100,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
      child: Text(value,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.grey700,
              fontSize: 15)),
    );
  }
}

// ─── Timer card ──────────────────────────────────────────────────────────────
class _TimerCard extends ConsumerWidget {
  final AppLocalizations l;
  final ThemeData theme;
  final TimerState timer;
  const _TimerCard({required this.l, required this.theme, required this.timer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = timer.status == TimerStatus.running;
    final isPaused = timer.status == TimerStatus.paused;
    final isStopped = timer.status == TimerStatus.stopped;

    return Card(
      color: AppColors.primarySurface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.primaryLight, width: 0.5)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Display
          Text(timer.display,
              style: const TextStyle(
                  fontSize: 42, fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark, letterSpacing: 4,
                  fontFamily: 'monospace')),
          const SizedBox(height: 4),
          Text(
            isStopped ? l.timerStopped
                : isPaused ? l.timerPaused
                : isRunning ? l.timerRunning
                : l.hoursWorked,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          // Buttons
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _TimerBtn(
              label: l.timerStart,
              icon: Icons.play_arrow,
              color: AppColors.primary,
              enabled: !isRunning,
              onTap: () {
                final ctrl = context.findAncestorStateOfType<_NewEntryPageState>();
                final name = ctrl?._nameCtrl.text ?? '';
                if (name.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter customer name first')));
                  return;
                }
                ref.read(timerProvider.notifier).start(name);
              },
            ),
            const SizedBox(width: 10),
            _TimerBtn(
              label: l.timerPause,
              icon: Icons.pause,
              color: AppColors.secondary,
              enabled: isRunning,
              onTap: () => ref.read(timerProvider.notifier).pause(),
            ),
            const SizedBox(width: 10),
            _TimerBtn(
              label: l.timerStop,
              icon: Icons.stop,
              color: AppColors.error,
              enabled: isRunning || isPaused,
              onTap: () => ref.read(timerProvider.notifier).stop(),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _TimerBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  const _TimerBtn({required this.label, required this.icon, required this.color,
      required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.white,
        minimumSize: const Size(90, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─── Native field with suggestions ───────────────────────────────────────────
class _NativeField extends StatefulWidget {
  final TextEditingController ctrl;
  final AppLocalizations l;
  final List<String> suggestions;
  final void Function(String) onChanged;
  const _NativeField({required this.ctrl, required this.l,
      required this.suggestions, required this.onChanged});

  @override
  State<_NativeField> createState() => _NativeFieldState();
}

class _NativeFieldState extends State<_NativeField> {
  bool _showSuggestions = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.ctrl,
          decoration: InputDecoration(
            labelText: widget.l.nativePlace,
            hintText: widget.l.nativePlaceHint,
            prefixIcon: const Icon(Icons.location_on_outlined),
          ),
          onChanged: (v) {
            widget.onChanged(v);
            setState(() => _showSuggestions = v.isNotEmpty);
          },
          onTap: () => setState(
              () => _showSuggestions = widget.ctrl.text.isNotEmpty),
        ),
        if (_showSuggestions && widget.suggestions.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 4),
            child: Column(
              children: widget.suggestions.map((s) => ListTile(
                dense: true,
                leading: const Icon(Icons.history, size: 18, color: AppColors.grey500),
                title: Text(s, style: const TextStyle(fontSize: 14)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(widget.l.existingSuggestion,
                      style: const TextStyle(fontSize: 10, color: AppColors.secondaryDark)),
                ),
                onTap: () {
                  widget.ctrl.text = s;
                  setState(() => _showSuggestions = false);
                },
              )).toList(),
            ),
          ),
      ],
    );
  }
}

// ─── Photo rows ───────────────────────────────────────────────────────────────
class _PhotoRow extends StatelessWidget {
  final Uint8List? photoBytes;
  final String label;
  final VoidCallback onTap;
  const _PhotoRow({required this.photoBytes, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.grey100,
            border: Border.all(color: AppColors.grey200),
            // MemoryImage works on Android, iOS and Web; FileImage does not
            // exist on Web since dart:io is unavailable there.
            image: photoBytes != null
                ? DecorationImage(image: MemoryImage(photoBytes!), fit: BoxFit.cover)
                : null,
          ),
          child: photoBytes == null
              ? const Icon(Icons.add_a_photo_outlined, color: AppColors.grey500)
              : null,
        ),
      ),
      const SizedBox(width: 16),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.camera_alt_outlined, size: 16),
          label: const Text('Camera', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ),
      ]),
    ]);
  }
}

class _BillPhotoRow extends StatelessWidget {
  final Uint8List? photoBytes;
  final String label;
  final VoidCallback onTap;
  const _BillPhotoRow({required this.photoBytes, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 80, height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.grey100,
            border: Border.all(color: AppColors.grey200, style: BorderStyle.solid),
            image: photoBytes != null
                ? DecorationImage(image: MemoryImage(photoBytes!), fit: BoxFit.cover)
                : null,
          ),
          child: photoBytes == null
              ? const Icon(Icons.receipt_long_outlined, color: AppColors.grey500)
              : null,
        ),
      ),
      const SizedBox(width: 16),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.camera_alt_outlined, size: 16),
          label: const Text('Attach bill', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ),
      ]),
    ]);
  }
}
