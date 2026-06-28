// lib/presentation/pages/agri/agri_login_page.dart
//
// Email/password sign-in and sign-up screen for the agri module's Firebase
// Auth flow. Styled after the existing lib/presentation/pages/auth/
// login_page.dart (same AgriBackground + animated Card + Form pattern) but
// wired to agriAuthFormProvider/agriAuthProvider instead of the vehicle/
// driver session authProvider — the two auth systems are intentionally
// independent.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/agri/agri_auth_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/agri/agri_form_widgets.dart';

class AgriLoginPage extends ConsumerStatefulWidget {
  const AgriLoginPage({super.key});

  @override
  ConsumerState<AgriLoginPage> createState() => _AgriLoginPageState();
}

class _AgriLoginPageState extends ConsumerState<AgriLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final l = AppLocalizations.of(context);
    final value = v?.trim() ?? '';
    if (value.isEmpty) return l.agriEmailRequired;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value)) return l.agriEmailInvalid;
    return null;
  }

  String? _validatePassword(String? v) {
    final l = AppLocalizations.of(context);
    final value = v ?? '';
    if (value.isEmpty) return l.agriPasswordRequired;
    if (value.length < 6) return l.agriPasswordTooShort;
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    final l = AppLocalizations.of(context);
    if (v != _passwordCtrl.text) return l.agriPasswordMismatch;
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(agriAuthFormProvider.notifier);
    final ok = _isSignUp
        ? await notifier.signUp(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
            displayName: _nameCtrl.text,
          )
        : await notifier.signIn(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
          );
    // On success, agriAuthProvider's authStateChanges listener flips to
    // `authenticated` and the router's redirect callback takes over; this
    // explicit context.go is a fast-path so the UI doesn't wait an extra
    // frame for that listener to fire.
    if (ok && mounted) {
      context.go('/agri/lands');
    }
  }

  Future<void> _forgotPassword() async {
    final l = AppLocalizations.of(context);
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || _validateEmail(email) != null) {
      showAgriSnack(context, error: l.agriEmailInvalid);
      return;
    }
    final ok =
        await ref.read(agriAuthFormProvider.notifier).sendPasswordResetEmail(email);
    if (ok && mounted) {
      showAgriSnack(context, success: l.agriResetPasswordSent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final formState = ref.watch(agriAuthFormProvider);
    final isLoading = formState.isLoading;

    return Scaffold(
      body: AgriBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.white.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.eco_outlined,
                          color: AppColors.white, size: 44),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.agriModuleTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppColors.white, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.agriModuleSubtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.white.withOpacity(0.8)),
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSignUp ? l.agriSignUp : l.agriLogin,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(color: AppColors.primaryDark),
                          ),
                          const SizedBox(height: 24),
                          if (_isSignUp) ...[
                            AgriField(
                              controller: _nameCtrl,
                              label: l.agriFullName,
                              hint: l.agriFullNameHint,
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 16),
                          ],
                          AgriField(
                            controller: _emailCtrl,
                            label: l.agriEmail,
                            hint: l.agriEmailHint,
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: l.agriPassword,
                              hintText: l.agriPasswordHint,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: _validatePassword,
                          ),
                          if (_isSignUp) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordCtrl,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: l.agriConfirmPassword,
                                prefixIcon: const Icon(Icons.lock_outline),
                              ),
                              validator: _validateConfirmPassword,
                            ),
                          ],
                          if (!_isSignUp) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: isLoading ? null : _forgotPassword,
                                child: Text(l.agriForgotPassword),
                              ),
                            ),
                          ],
                          if (formState.hasError) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.errorSurface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: AppColors.error, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      formState.error.toString(),
                                      style: const TextStyle(
                                          color: AppColors.error, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: isLoading ? null : _submit,
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: AppColors.white, strokeWidth: 2),
                                  )
                                : Text(_isSignUp ? l.agriCreateAccount : l.agriLogin),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => setState(() => _isSignUp = !_isSignUp),
                              child: Text(
                                _isSignUp
                                    ? l.agriAlreadyHaveAccount
                                    : l.agriDontHaveAccount,
                                style: const TextStyle(
                                    color: AppColors.grey500, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.2),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    '← ${l.appName}',
                    style: TextStyle(color: AppColors.white.withOpacity(0.85)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
