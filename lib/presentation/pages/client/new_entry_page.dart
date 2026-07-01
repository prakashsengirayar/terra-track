import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/auth/auth_provider.dart';
import '../../bloc/work_entry/work_entry_provider.dart';

/// New Entry screen — restyled to match the "TerraTrack Entry" dark mockup:
/// a deep green/black gradient background with rounded translucent cards
/// (Customer / Work / Payment / Details) and a green accent throughout.
class NewEntryPage extends ConsumerStatefulWidget {
  const NewEntryPage({super.key});
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

  double get _totalAmount => _rate * (_hrs + _mins / 60);

  double get _balance {
    final paid = double.tryParse(_paidCtrl.text) ?? 0;
    final b = _totalAmount - paid;
    return b < 0 ? 0 : b;
  }

  String _fmt(num n) => _numFmt.format(n.round());

  void _incRate() => setState(() => _rate = (_rate + 10).clamp(0, 9999).toDouble());
  void _decRate() => setState(() => _rate = (_rate - 10).clamp(0, 9999).toDouble());
  void _incHrs() => setState(() => _hrs = (_hrs + 1).clamp(0, 24).toInt());
  void _decHrs() => setState(() => _hrs = (_hrs - 1).clamp(0, 24).toInt());
  void _incMins() => setState(() => _mins = (_mins + 5) % 60);
  void _decMins() => setState(() => _mins = (_mins + 55) % 60);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nativeCtrl.dispose();
    _paidCtrl.dispose();
    _phoneCtrl.dispose();
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
    final session = ref.read(authProvider).session!;
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
    if (ok && mounted) {
      _formKey.currentState!.reset();
      _nameCtrl.clear();
      _nativeCtrl.clear();
      _paidCtrl.clear();
      _phoneCtrl.clear();
      setState(() {
        _rate = 100;
        _hrs = 0;
        _mins = 0;
        _selectedDate = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).entrySaved),
            backgroundColor: AppColors.entryAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final formState = ref.watch(entryFormProvider);
    final session = ref.watch(authProvider).session;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.entryBgTop, AppColors.entryBgBottom],
        ),
      ),
      child: SingleChildScrollView(
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
              _detailsCard(l, session),
              const SizedBox(height: 20),
              if (formState.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(formState.error!,
                      style: const TextStyle(color: Color(0xFFFF6B6B))),
                ),
              SizedBox(
                height: 66,
                child: ElevatedButton.icon(
                  onPressed: formState.isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.entryAccent,
                    foregroundColor: AppColors.entryPillText,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    textStyle: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                  ),
                  icon: formState.isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.entryPillText, strokeWidth: 2))
                      : const Icon(Icons.check_circle_rounded, size: 28),
                  label: Text(formState.isLoading ? l.saving : l.saveEntry),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── CUSTOMER card ──────────────────────────────────────────────────────
  Widget _customerCard(AppLocalizations l, EntryFormState formState) {
    return _card(children: [
      _sectionHeader(Icons.person_rounded, 'CUSTOMER'),
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        _PhotoPicker(photoBytes: formState.customerPhotoBytes, onTap: () => _pickPhoto(true)),
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
                  ref.read(entryFormProvider.notifier)
                      .checkCustomerName(v, ref.read(authProvider).session?.vehicleName ?? '');
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
        valueText: '₹${_fmt(_rate)}',
        valueFontSize: 25,
        onDec: _decRate,
        onInc: _incRate,
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('HOURS',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.entryTextMuted, letterSpacing: 1)),
            const SizedBox(height: 6),
            _StepperControl(height: 40, valueText: '$_hrs', valueFontSize: 22, onDec: _decHrs, onInc: _incHrs),
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
              valueText: _mins.toString().padLeft(2, '0'),
              valueFontSize: 22,
              onDec: _decMins,
              onInc: _incMins,
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
  Widget _detailsCard(AppLocalizations l, dynamic session) {
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
            value: session?.vehicleName ?? '—',
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
class _StepperControl extends StatelessWidget {
  final double height;
  final String valueText;
  final double valueFontSize;
  final VoidCallback onDec;
  final VoidCallback onInc;

  const _StepperControl({
    required this.height,
    required this.valueText,
    required this.valueFontSize,
    required this.onDec,
    required this.onInc,
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
            child: Text(valueText,
                style: TextStyle(
                    fontSize: valueFontSize, fontWeight: FontWeight.w900, color: AppColors.entryTextPrimary)),
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
  final VoidCallback onTap;
  const _PhotoPicker({required this.photoBytes, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
              : null,
        ),
        child: photoBytes == null
            ? const Icon(Icons.photo_camera_rounded, color: AppColors.entryAccent, size: 26)
            : null,
      ),
    );
  }
}
