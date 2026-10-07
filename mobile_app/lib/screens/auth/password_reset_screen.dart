import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/brand_mark.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({required this.authService, super.key});

  final AuthService authService;

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _challengeId;
  String? _errorMessage;
  bool _loading = false;
  bool _resetComplete = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      if (_resetComplete) {
        Navigator.of(context).pop();
      } else if (_challengeId == null) {
        final id = await widget.authService.requestPasswordReset(
          _emailController.text,
        );
        if (mounted) setState(() => _challengeId = id);
      } else {
        await widget.authService.resetPassword(
          challengeId: _challengeId!,
          code: _codeController.text.trim(),
          newPassword: _passwordController.text,
        );
        if (mounted) setState(() => _resetComplete = true);
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Password reset failed. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validateNewPassword(String? value) {
    final password = value ?? '';
    if (password.length < 8) return 'Use at least 8 characters.';
    if (utf8.encode(password).length > 72) {
      return 'Password must be 72 bytes or fewer.';
    }
    if (!password.contains(RegExp(r'[A-Z]')) ||
        !password.contains(RegExp(r'\d'))) {
      return 'Add at least one uppercase letter and one number.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final requested = _challengeId != null;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to Login',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _ResetBrand(),
                    const SizedBox(height: 28),
                    Icon(
                      _resetComplete
                          ? Icons.check_circle_outline_rounded
                          : Icons.lock_reset_rounded,
                      color: colors.primary,
                      size: 44,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _resetComplete ? 'Password updated' : 'Forgot Password?',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _resetComplete
                          ? 'You can now sign in with your new password.'
                          : requested
                          ? 'If an active account exists for that email, a reset code was sent.'
                          : 'Enter your email address and we’ll send reset instructions.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage != null) ...[
                      _ResetError(message: _errorMessage!),
                      const SizedBox(height: 14),
                    ],
                    if (!requested && !_resetComplete) ...[
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'you@example.com',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (value) =>
                            value != null &&
                                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(value.trim())
                            ? null
                            : 'Enter a valid email address.',
                      ),
                    ] else if (requested && !_resetComplete) ...[
                      TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Reset code',
                          prefixIcon: Icon(Icons.mark_email_read_outlined),
                          counterText: '',
                        ),
                        validator: (value) =>
                            value != null &&
                                RegExp(r'^\d{6}$').hasMatch(value.trim())
                            ? null
                            : 'Enter the 6-digit reset code.',
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: 'New password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: _validateNewPassword,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm new password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _obscureConfirm
                                ? 'Show confirm password'
                                : 'Hide confirm password',
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => value != _passwordController.text
                            ? 'Passwords do not match.'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _resetComplete
                                  ? 'BACK TO LOGIN'
                                  : requested
                                  ? 'RESET PASSWORD'
                                  : 'SEND RESET LINK',
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetBrand extends StatelessWidget {
  const _ResetBrand();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        const ScamShieldBrandMark(size: 54),
        const SizedBox(height: 8),
        Text(
          'ScamShield',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(
          'AI-POWERED SCAM PROTECTION',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.primary,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ResetError extends StatelessWidget {
  const _ResetError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: TextStyle(color: colors.onErrorContainer)),
    );
  }
}
