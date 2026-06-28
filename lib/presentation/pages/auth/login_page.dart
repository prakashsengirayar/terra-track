import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/auth/auth_provider.dart';
import '../../widgets/common/common_widgets.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();
  bool _vehicleVerified = false;
  bool _checking = false;

  @override
  void dispose() {
    _vehicleCtrl.dispose();
    _driverCtrl.dispose();
    super.dispose();
  }

  Future<void> _onVehicleFocusLost() async {
    final name = _vehicleCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() { _checking = true; _vehicleVerified = false; });
    await Future.delayed(const Duration(milliseconds: 200));
    // Verified by submit; this just shows the indicator
    setState(() { _checking = false; });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
          _vehicleCtrl.text.trim(),
          _driverCtrl.text.trim(),
        );
    final state = ref.read(authProvider);
    if (state.isAuthenticated && mounted) {
      context.go('/client');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final isLoading = auth.status == AuthStatus.loading;

    return Scaffold(
      body: AgriBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Logo
                Column(children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.white.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.agriculture, color: AppColors.white, size: 44),
                  ),
                  const SizedBox(height: 16),
                  Text(l.appName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(l.appTagline,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.white.withOpacity(0.8))),
                ]).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
                const SizedBox(height: 40),
                // Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.login,
                            style: theme.textTheme.titleLarge?.copyWith(
                                color: AppColors.primaryDark)),
                          const SizedBox(height: 24),
                          // Vehicle name
                          Focus(
                            onFocusChange: (hasFocus) {
                              if (!hasFocus) _onVehicleFocusLost();
                            },
                            child: TextFormField(
                              controller: _vehicleCtrl,
                              decoration: InputDecoration(
                                labelText: l.vehicleName,
                                hintText: l.vehicleNameHint,
                                prefixIcon: const Icon(Icons.directions_car_outlined),
                                suffixIcon: _checking
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(width: 16, height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2)))
                                    : null,
                              ),
                              textCapitalization: TextCapitalization.characters,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return l.vehicleNameRequired;
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Driver name
                          TextFormField(
                            controller: _driverCtrl,
                            decoration: InputDecoration(
                              labelText: l.driverOwnerName,
                              hintText: l.driverNameHint,
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return l.driverNameRequired;
                              if (v.trim().length < 3) return l.driverNameTooShort;
                              return null;
                            },
                          ),
                          if (auth.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.errorSurface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.error, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(auth.errorMessage!,
                                    style: const TextStyle(color: AppColors.error, fontSize: 13)),
                                ),
                              ]),
                            ),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: isLoading ? null : _submit,
                            child: isLoading
                                ? const SizedBox(height: 20, width: 20,
                                    child: CircularProgressIndicator(
                                        color: AppColors.white, strokeWidth: 2))
                                : Text(l.signIn),
                          ),
                          const SizedBox(height: 12),
                          // Admin link
                          Center(
                            child: TextButton(
                              onPressed: () => context.go('/admin'),
                              child: const Text('Admin Panel →',
                                  style: TextStyle(color: AppColors.grey500, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
