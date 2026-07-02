import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/entities.dart';
import '../../bloc/auth/auth_provider.dart';
import '../../bloc/providers.dart';
import '../../bloc/work_entry/work_entry_provider.dart';

/// New Entry screen — restyled to match the "TerraTrack Entry" dark mockup:
/// a deep green/black gradient background with rounded translucent cards
/// (Customer / Work / Payment / Details) and a green accent throughout.
///
/// Also doubles as the Edit screen: pass [entryId] to load and pre-fill an
/// existing entry (including its photos), and "Save Entry" updates that
/// record instead of creating a new one.
class NewEntryPage extends ConsumerStatefulWidget {
  final String? entryId;
  const NewEntryPage({super.key, this.entryId});
  @override
  ConsumerState<NewEntryPage> createState() => _NewEntryPageState();
}

class _NewEntryPageState extends ConsumerState<NewEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nativeCtrl = TextEditingController();
  final _paidCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _picker = ImagePicker();
  final _numFmt = NumberFormat.decimalPattern('en_IN');

  double _rate = 100;
  int _hrs = 0;
  int _mins = 0;
  DateTime _selectedDate = DateTime.now();

  // Rate/Hours/Minutes are shown in steppers, but each center value is also
  // a real text field so the number pad can be used directly instead of
  // only +/-. The controllers hold the "live" typed text; _commitRate/
  // _commitHrs/_commitMins clamp + reformat once the user finishes typing
  // (on submit or when the field loses focus), matching how the stepper
  // buttons themselves clamp.
  late final TextEditingController _rateCtrl;
  late final TextEditingController _hrsCtrl;
  late final TextEditingController _minsCtrl;
  final _rateFocus = FocusNode();
  final _hrsFocus = FocusNode();
  final _minsFocus = FocusNode();

  WorkEntryEntity? _original;
  bool _loading = false;
  bool _saving = false;
  String? _loadError;

  bool get _isEdit => widget.entryId != null;

  double get _totalAmount => _rate * (_hrs + _mins / 60);

  double get _balance {
    final paid = double.tryParse(_paidCtrl.text) ?? 0;
    final b = _totalAmount - paid;
    return b < 0 ? 0 : b;
  }

  String _fmt(num n) => _numFmt.format(n.round());

  void _incRate() => setState(() {
        _rate = (_rate + 10).clamp(0, 9999).toDouble();
        _rateCtrl.text = _rate.round().toString();
      });
  void _decRate() => setState(() {
        _rate = (_rate - 10).clamp(0, 9999).toDouble();
        _rateCtrl.text = _rate.round().toString();
      });
  void _incHrs() => setState(() {
        _hrs = (_hrs + 1).clamp(0, 24).toInt();
        _hrsCtrl.text = _hrs.toString();
      });
  void _decHrs() => setState(() {
        _hrs = (_hrs - 1).clamp(0, 24).toInt();
        _hrsCtrl.text = _hrs.toString();
      });
  void _incMins() => setState(() {
        _mins = (_mins + 5) % 60;
        _minsCtrl.text = _mins.toString().padLeft(2, '0');
      });
  void _decMins() => setState(() {
        _mins = (_mins + 55) % 60;
        _minsCtrl.text = _mins.toString().padLeft(2, '0');
      });

  // Live-updates the underlying value as the user types, without touching
  // the controller's own text (so the cursor never jumps mid-entry).
  void _onRateTyped(String v) {
    final parsed = double.tryParse(v);
    if (parsed != null) setState(() => _rate = parsed);
  }

  void _onHrsTyped(String v) {
    final parsed = int.tryParse(v);
    if (parsed != null) setState(() => _hrs = parsed);
  }

  void _onMinsTyped(String v) {
    final parsed = int.tryParse(v);
    if (parsed != null) setState(() => _mins = parsed);
  }

  // Clamp + reformat once typing is finished (submit or focus lost) —
  // mirrors the clamping the stepper +/- buttons already do.
  void _commitRate() {
    final parsed = double.tryParse(_rateCtrl.text) ?? _rate;
    setState(() {
      _rate = parsed.clamp(0, 9999).toDouble();
      _rateCtrl.text = _rate.round().toString();
    });
  }

  void _commitHrs() {
    final parsed = int.tryParse(_hrsCtrl.text) ?? _hrs;
    setState(() {
      _hrs = parsed.clamp(0, 24).toInt();
      _hrsCtrl.text = _hrs.toString();
    });
  }

  void _commitMins() {
    final parsed = int.tryParse(_minsCtrl.text) ?? _mins;
    setState(() {
      _mins = parsed.clamp(0, 59).toInt();
      _minsCtrl.text = _mins.toString().padLeft(2, '0');
    });
  }

  @override
  void initState() {
    super.initState();
    _rateCtrl = TextEditingController(text: _rate.round().toString());
    _hrsCtrl = TextEditingController(text: _hrs.toString());
    _minsCtrl = TextEditingController(text: _mins.toString().padLeft(2, '0'));
    _rateFocus.addListener(() {
      if (!_rateFocus.hasFocus) _commitRate();
    });
    _hrsFocus.addListener(() {
      if (!_hrsFocus.hasFocus) _commitHrs();
    });
    _minsFocus.addListener(() {
      if (!_minsFocus.hasFocus) _commitMins();
    });
    if (_isEdit) {
      _loading = true;
      _loadEntry();
    }
  }

  Future<void> _loadEntry() async {
    final result =
        await ref.read(workEntryRepositoryProvider).getEntryById(widget.entryId!);
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _loading = false;
        _loadError = f.message;
      }),
      (entry) => setState(() {
        _original = entry;
        _nameCtrl.text = entry.customerName;
        _nativeCtrl.text = entry.nativePlace;
        _phoneCtrl.text = entry.customerPhone;
        _paidCtrl.text = entry.paidAmount.toStringAsFixed(0);
        _rate = entry.ratePerHour;
        _hrs = entry.timerDurationSeconds ~/ 3600;
        _mins = (entry.timerDurationSeconds % 3600) ~/ 60;
        _rateCtrl.text = _rate.round().toString();
        _hrsCtrl.text = _hrs.toString();
        _minsCtrl.text = _mins.toString().padLeft(2, '0');
        _selectedDate = entry.date;
        _loading = false;
      }),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _nativeCtrl.dispose();
    _paidCtrl.dispose(); _phoneCtrl.dispose();
    _rateCtrl.dispose(); _hrsCtrl.dispose(); _minsCtrl.dispose();
    _rateFocus.dispose(); _hrsFocus.dispose(); _minsFocus.dispose();
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
    if (_rate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set a rate per hour first')));
      return;
    }
    if (_hrs == 0 && _mins == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set the hours worked first')));
      return;
    }

    setState(() => _saving = true);

    // Everything below talks to Firebase. Wrapped in try/catch so an
    // unexpected exception (bad network, a null session, an Auth/Firestore
    // error that doesn't come back through the usual Either<Failure,T>
    // path) always surfaces as a visible SnackBar instead of failing
    // silently — the button would otherwise just reset with no feedback.
    try {
      if (_isEdit) {
        final formState = ref.read(entryFormProvider);
        String? customerPhotoUrl = _original!.customerPhotoUrl;
        String? billPhotoUrl = _original!.billPhotoUrl;
        if (formState.customerPhotoBytes != null) {
          final r = await ref
              .read(uploadCustomerPhotoUseCaseProvider)
              .call(formState.customerPhotoBytes!, widget.entryId!);
          r.fold((_) {}, (url) => customerPhotoUrl = url);
        }
        if (formState.billPhotoBytes != null) {
          final r = await ref
              .read(uploadBillPhotoUseCaseProvider)
              .call(formState.billPhotoBytes!, widget.entryId!);
          r.fold((_) {}, (url) => billPhotoUrl = url);
        }
        final paid = double.tryParse(_paidCtrl.text) ?? 0;
        final balance = _totalAmount - paid;
        final updated = _original!.copyWith(
          customerName: _nameCtrl.text.trim(),
          nativePlace: _nativeCtrl.text.trim(),
          customerPhone: _phoneCtrl.text.trim(),
          ratePerHour: _rate,
          timerDurationSeconds: _hrs * 3600 + _mins * 60,
          totalAmount: _totalAmount,
          paidAmount: paid,
          balanceAmount: balance < 0 ? 0 : balance,
          status: balance <= 0 ? PaymentStatus.paid : PaymentStatus.pending,
          date: _selectedDate,
          customerPhotoUrl: customerPhotoUrl,
          billPhotoUrl: billPhotoUrl,
          updatedAt: DateTime.now(),
        );
        final result = await ref.read(updateWorkEntryUseCaseProvider).call(updated);
        if (!mounted) return;
        setState(() => _saving = false);
        result.fold(
          (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
          (_) => context.pop(),
        );
      } else {
        final session = ref.read(authProvider).session;
        if (session == null) {
          setState(() => _saving = false);
          _snack('Your session has expired. Please log in again.');
          return;
        }
        final ok = await ref.read(entryFormProvider.notifier).saveEntry(
          customerName: _nameCtrl.text,
          nativePlace: _nativeCtrl.text,
          vehicleName: session.vehicleName,
          driverName: session.driverName,
          ratePerHour: _rate,
          timerSeconds: _hrs * 3600 + _mins * 60,
          paidAmount: double.tryParse(_paidCtrl.text) ?? 0,
          date: _selectedDate,
          customerPhone: _phoneCtrl.text,
        );
        if (!mounted) return;
        setState(() => _saving = false);
        if (ok) {
          context.pop();
        } else {
          // entryFormProvider.state.error is already shown inline below the
          // form, but a SnackBar too means it can't be missed if the user
          // has already scrolled away from it.
          final err = ref.read(entryFormProvider).error;
          if (err != null) _snack(err);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Something went wrong: $e');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formState = ref.watch(entryFormProvider);
    final session = ref.watch(authProvider).session;

    return Scaffold(
      backgroundColor: AppColors.entryBgBottom,
      appBar: AppBar(
        backgroundColor: AppColors.entryHeaderTop,
        foregroundColor: AppColors.entryTextPrimary,
        elevation: 0,
        title: Text(_isEdit ? 'Edit Entry' : 'New Entry'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.entryBgTop, AppColors.entryBgBottom],
          ),
        ),
        child: SafeArea(
          top: false,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.entryAccent))
              : _loadError != null
                  ? _errorState(_loadError!)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _customerCard(l, formState),
                            const SizedBox(height: 16),
                            _workCard(),
                            const SizedBox(height: 16),
                            _paymentCard(l),
                            const SizedBox(height: 16),
                            _detailsCard(l, formState, session),
                            const SizedBox(height: 20),
                            if (formState.error != null)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.entryRedTintBg,
                                  border: Border.all(color: AppColors.entryRedTintBorder),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.error_outline, color: AppColors.entryRed, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(formState.error!,
                                        style: const TextStyle(
                                            color: AppColors.entryTextSecondary, fontSize: 13)),
                                  ),
                                ]),
                              ),
                            SizedBox(
                              height: 66,
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.entryAccent,
                                  foregroundColor: AppColors.entryPillText,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  textStyle: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                                ),
                                icon: _saving
                                    ? const SizedBox(
                                        width: 20, height: 20,
                                        child: CircularProgressIndicator(
                                            color: AppColors.entryPillText, strokeWidth: 2))
                                    : const Icon(Icons.check_circle_rounded, size: 28),
                                label: Text(_saving ? l.saving : l.saveEntry),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: AppColors.entryRed, size: 40),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.entryTextSecondary)),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: () => context.pop(), child: const Text('Go back')),
        ]),
      ),
    );
  }

  // ─── CUSTOMER card ──────────────────────────────────────────────────────
  Widget _customerCard(AppLocalizations l, EntryFormState formState) {
    return _card(children: [
      _sectionHeader(Icons.person_rounded, 'CUSTOMER'),
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        _PhotoPicker(
          photoBytes: formState.customerPhotoBytes,
          networkUrl: _original?.customerPhotoUrl,
          onTap: () => _pickPhoto(true),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.customerName,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.entryTextMuted)),
              const SizedBox(height: 3),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.entryTextPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: l.customerNameHint,
                  hintStyle: TextStyle(
                      color: AppColors.entryTextMuted.withOpacity(0.5),
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                  suffixIcon: formState.isCheckingName
                      ? const Padding(
                          padding: EdgeInsets.all(4),
                          child: SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.entryAccent)))
                      : formState.isNameUnique && _nameCtrl.text.isNotEmpty
                          ? const Icon(Icons.check_circle, color: AppColors.entryAccent, size: 18)
                          : null,
                ),
                onChanged: (v) {
                  ref.read(entryFormProvider.notifier).checkCustomerName(
                      v, ref.read(authProvider).session?.vehicleName ?? '',
                      excludeId: widget.entryId);
                  setState(() {});
                },
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l.customerNameRequired;
                  if (v.trim().length < 3) return l.customerNameTooShort;
                  if (!formState.isNameUnique) return l.customerNameDuplicate;
                  return null;
                },
              ),
            ],
          ),
        ),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
          child: _NativeTile(
            ctrl: _nativeCtrl,
            l: l,
            suggestions: formState.nativeSuggestions,
            onChanged: (v) => ref.read(entryFormProvider.notifier).fetchNativeSuggestions(v),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _tileField(
            icon: Icons.call_rounded,
            label: l.customerPhone,
            controller: _phoneCtrl,
            hint: l.customerPhoneHint,
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
          ),
        ),
      ]),
    ]);
  }

  // ─── WORK card ──────────────────────────────────────────────────────────
  Widget _workCard() {
    return _card(children: [
      _sectionHeader(Icons.schedule_rounded, 'WORK'),
      const Text('RATE PER HOUR',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.entryTextMuted, letterSpacing: 0.5)),
      const SizedBox(height: 8),
      _StepperControl(
        height: 48,
        controller: _rateCtrl,
        focusNode: _rateFocus,
        prefixText: '₹',
        maxLength: 5,
        valueFontSize: 25,
        onDec: _decRate,
        onInc: _incRate,
        onChanged: _onRateTyped,
        onSubmitted: _commitRate,
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('HOURS',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.entryTextMuted, letterSpacing: 1)),
            const SizedBox(height: 6),
            _StepperControl(
              height: 40,
              controller: _hrsCtrl,
              focusNode: _hrsFocus,
              maxLength: 2,
              valueFontSize: 22,
              onDec: _decHrs,
              onInc: _incHrs,
              onChanged: _onHrsTyped,
              onSubmitted: _commitHrs,
            ),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('MINUTES',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.entryTextMuted, letterSpacing: 1)),
            const SizedBox(height: 6),
            _StepperControl(
              height: 40,
              controller: _minsCtrl,
              focusNode: _minsFocus,
              maxLength: 2,
              valueFontSize: 22,
              onDec: _decMins,
              onInc: _incMins,
              onChanged: _onMinsTyped,
              onSubmitted: _commitMins,
            ),
          ]),
        ),
      ]),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: AppColors.entryPillGreen, borderRadius: BorderRadius.circular(15)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Icon(Icons.calculate_rounded, size: 22, color: AppColors.entryPillText),
            const SizedBox(width: 8),
            const Text('Total',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.entryPillText)),
            const SizedBox(width: 6),
            _autoBadge(),
          ]),
          Text('₹ ${_fmt(_totalAmount)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.entryPillText)),
        ]),
      ),
    ]);
  }

  // ─── PAYMENT card ───────────────────────────────────────────────────────
  Widget _paymentCard(AppLocalizations l) {
    return _card(children: [
      _sectionHeader(Icons.payments_rounded, 'PAYMENT'),
      const Text('AMOUNT PAID (tap to type)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.entryTextMuted)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration:
            BoxDecoration(color: AppColors.entryPillGreenLight, borderRadius: BorderRadius.circular(15)),
        child: Row(children: [
          Expanded(
            child: TextFormField(
              controller: _paidCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.entryPillText),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                prefixText: '₹ ',
                prefixStyle: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.entryPillText),
                hintText: '0',
                hintStyle: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w900,
                    color: AppColors.entryPillText.withOpacity(0.4)),
              ),
            ),
          ),
          Icon(Icons.dialpad_rounded, size: 26, color: AppColors.entryPillText.withOpacity(0.55)),
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.entryAccentSurface,
          border: Border.all(color: AppColors.entryAccentBorderSoft),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Icon(Icons.account_balance_wallet_rounded, size: 22, color: AppColors.entryAccent),
            const SizedBox(width: 8),
            Text(l.balanceAmount.replaceAll(' (₹)', ''),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.entryTextSecondary)),
            const SizedBox(width: 6),
            _autoBadge(dark: true),
          ]),
          Text('₹ ${_fmt(_balance)}',
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.entryTextPrimary)),
        ]),
      ),
    ]);
  }

  // ─── DETAILS card ───────────────────────────────────────────────────────
  Widget _detailsCard(AppLocalizations l, EntryFormState formState, dynamic session) {
    final dateStr = '${_selectedDate.day.toString().padLeft(2, '0')}/'
        '${_selectedDate.month.toString().padLeft(2, '0')}/'
        '${_selectedDate.year}';
    return _card(children: [
      _sectionHeader(Icons.description_rounded, 'DETAILS'),
      Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: _pickDate,
            child: _staticTile(icon: Icons.calendar_month_rounded, label: l.date, value: dateStr),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _staticTile(
            icon: Icons.directions_car_rounded,
            label: l.vehicleNameField,
            value: _original?.vehicleName ?? session?.vehicleName ?? '—',
            iconColor: AppColors.entryTextMuted2,
            valueColor: AppColors.entryTextSecondary,
          ),
        ),
      ]),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () => _pickPhoto(false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.entryAccentDashed,
            border: Border.all(color: AppColors.entryAccentBorderSoft),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            const Icon(Icons.receipt_long_rounded, size: 26, color: AppColors.entryAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l.billPhoto,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.entryTextPrimary),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: AppColors.entryAccentSurface, borderRadius: BorderRadius.circular(999)),
              child: Text(l.attachBill.replaceAll(' Bill', ''),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.entryAccent)),
            ),
          ]),
        ),
      ),
    ]);
  }

  // ─── shared building blocks ────────────────────────────────────────────
  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.entryCardBg,
        border: Border.all(color: AppColors.entryCardBorder),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _sectionHeader(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Icon(icon, size: 20, color: AppColors.entryAccent),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.entryAccent)),
      ]),
    );
  }

  Widget _autoBadge({bool dark = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: dark ? AppColors.entryAccentSurface : AppColors.entryPillText.withOpacity(0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text('AUTO',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: dark ? AppColors.entryAccentDark : AppColors.entryPillText)),
    );
  }

  Widget _tileField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(color: AppColors.entryTileBg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Icon(icon, size: 17, color: AppColors.entryAccent),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.entryTextMuted)),
          ]),
          const SizedBox(height: 3),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            onChanged: onChanged,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.entryTextPrimary),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: hint,
              hintStyle: TextStyle(
                  color: AppColors.entryTextMuted.withOpacity(0.5),
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _staticTile({
    required IconData icon,
    required String label,
    required String value,
    Color iconColor = AppColors.entryAccent,
    Color valueColor = AppColors.entryTextPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(color: AppColors.entryTileBg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Icon(icon, size: 17, color: iconColor),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.entryTextMuted)),
          ]),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: valueColor)),
        ],
      ),
    );
  }
}

// ─── Stepper control (used for Rate / Hours / Minutes) ─────────────────────
// The centre value is a real, numeric-keyboard text field — so it can be
// stepped with +/- or typed directly — styled to look like plain text.
class _StepperControl extends StatelessWidget {
  final double height;
  final TextEditingController controller;
  final FocusNode focusNode;
  final double valueFontSize;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final void Function(String) onChanged;
  final VoidCallback onSubmitted;
  final String? prefixText;
  final int? maxLength;

  const _StepperControl({
    required this.height,
    required this.controller,
    required this.focusNode,
    required this.valueFontSize,
    required this.onDec,
    required this.onInc,
    required this.onChanged,
    required this.onSubmitted,
    this.prefixText,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(height >= 48 ? 7 : 6),
      decoration: BoxDecoration(color: AppColors.entryTileBg, borderRadius: BorderRadius.circular(height >= 48 ? 15 : 13)),
      child: Row(children: [
        _StepBtn(icon: Icons.remove_rounded, size: height, onTap: onDec),
        Expanded(
          child: Center(
            child: IntrinsicWidth(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (prefixText != null)
                    Text(prefixText!,
                        style: TextStyle(
                            fontSize: valueFontSize,
                            fontWeight: FontWeight.w900,
                            color: AppColors.entryTextPrimary)),
                  Flexible(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
                      ],
                      onChanged: onChanged,
                      onSubmitted: (_) => onSubmitted(),
                      textInputAction: TextInputAction.done,
                      style: TextStyle(
                          fontSize: valueFontSize,
                          fontWeight: FontWeight.w900,
                          color: AppColors.entryTextPrimary),
                      decoration: const InputDecoration(
                        isDense: true,
                        isCollapsed: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _StepBtn(icon: Icons.add_rounded, size: height, onTap: onInc),
      ]),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.27;
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: AppColors.entryAccentSurface,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: AppColors.entryAccentBorder, width: 2),
            ),
            child: Icon(icon, color: AppColors.entryAccent, size: size * 0.5),
          ),
        ),
      ),
    );
  }
}

// ─── Native place tile with suggestions ─────────────────────────────────────
class _NativeTile extends StatefulWidget {
  final TextEditingController ctrl;
  final AppLocalizations l;
  final List<String> suggestions;
  final void Function(String) onChanged;
  const _NativeTile({required this.ctrl, required this.l, required this.suggestions, required this.onChanged});

  @override
  State<_NativeTile> createState() => _NativeTileState();
}

class _NativeTileState extends State<_NativeTile> {
  bool _showSuggestions = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(color: AppColors.entryTileBg, borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                const Icon(Icons.location_on_rounded, size: 17, color: AppColors.entryAccent),
                const SizedBox(width: 6),
                Text(widget.l.nativePlace,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.entryTextMuted)),
              ]),
              const SizedBox(height: 3),
              TextFormField(
                controller: widget.ctrl,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.entryTextPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: widget.l.nativePlaceHint,
                  hintStyle: TextStyle(
                      color: AppColors.entryTextMuted.withOpacity(0.5),
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
                onChanged: (v) {
                  widget.onChanged(v);
                  setState(() => _showSuggestions = v.isNotEmpty);
                },
                onTap: () => setState(() => _showSuggestions = widget.ctrl.text.isNotEmpty),
              ),
            ],
          ),
        ),
        if (_showSuggestions && widget.suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.entryTileBg,
              border: Border.all(color: AppColors.entryCardBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.suggestions
                  .map((s) => InkWell(
                        onTap: () {
                          widget.ctrl.text = s;
                          setState(() => _showSuggestions = false);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(children: [
                            const Icon(Icons.history, size: 15, color: AppColors.entryTextMuted2),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(s,
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.entryTextPrimary)),
                            ),
                          ]),
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

// ─── Customer photo picker ───────────────────────────────────────────────────
class _PhotoPicker extends StatelessWidget {
  final Uint8List? photoBytes;
  final String? networkUrl;
  final VoidCallback onTap;
  const _PhotoPicker({required this.photoBytes, this.networkUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = photoBytes != null || networkUrl != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.entryAccentSurfaceSoft,
          border: Border.all(color: AppColors.entryAccentBorderSoft, width: 1.4),
          image: photoBytes != null
              ? DecorationImage(image: MemoryImage(photoBytes!), fit: BoxFit.cover)
              : networkUrl != null
                  ? DecorationImage(image: NetworkImage(networkUrl!), fit: BoxFit.cover)
                  : null,
        ),
        child: !hasImage
            ? const Icon(Icons.photo_camera_rounded, color: AppColors.entryAccent, size: 26)
            : null,
      ),
    );
  }
}
