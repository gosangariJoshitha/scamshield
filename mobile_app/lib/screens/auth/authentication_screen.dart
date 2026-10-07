import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/theme_mode_toggle.dart';
import 'password_reset_screen.dart';

enum _AuthMode { login, signup, admin }

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({
    required this.authService,
    required this.onAuthenticated,
    required this.onAdminAuthenticated,
    required this.onThemeChanged,
    this.initialMode = 'login',
    this.initialMessage,
    super.key,
  });

  final AuthService authService;
  final ValueChanged<User> onAuthenticated;
  final ValueChanged<User> onAdminAuthenticated;
  final ValueChanged<bool> onThemeChanged;
  final String initialMode;
  final String? initialMessage;

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();

  late _AuthMode _mode;
  String? _challengeId;
  String? _errorMessage;
  bool _loading = false;
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;
  bool _signupCreated = false;
  bool _verificationEmailSent = false;
  bool _signupVerified = false;

  bool get _isVerifyingLogin => _challengeId != null && !_signupCreated;
  bool get _isVerifyingSignup =>
      _signupCreated && !_signupVerified && _challengeId != null;
  String get _loadingLabel {
    if (_isVerifyingSignup) return 'Verifying email...';
    if (_isVerifyingLogin) return 'Verifying sign-in...';
    return switch (_mode) {
      _AuthMode.signup => 'Creating account...',
      _AuthMode.admin => 'Sending verification code...',
      _AuthMode.login => 'Signing in...',
    };
  }

  @override
  void initState() {
    super.initState();
    _mode = switch (widget.initialMode) {
      'signup' => _AuthMode.signup,
      'admin' => _AuthMode.admin,
      _ => _AuthMode.login,
    };
    _errorMessage = widget.initialMessage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _selectMode(_AuthMode mode) {
    setState(() {
      _mode = mode;
      _challengeId = null;
      _codeController.clear();
      _errorMessage = null;
      _signupCreated = false;
      _signupVerified = false;
    });
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    if (_mode == _AuthMode.signup && !_signupCreated && !_termsAccepted) {
      setState(
        () => _errorMessage = 'Please accept the Terms and Privacy Policy.',
      );
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      if (_isVerifyingSignup) {
        await widget.authService.verifyEmail(
          challengeId: _challengeId!,
          code: _codeController.text.trim(),
        );
        if (mounted) {
          setState(() {
            _signupVerified = true;
            _challengeId = null;
          });
        }
      } else if (_signupCreated) {
        _selectMode(_AuthMode.login);
      } else if (_mode == _AuthMode.signup) {
        final result = await widget.authService.signUp(
          fullName: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (mounted) {
          setState(() {
            _signupCreated = true;
            _challengeId = result.challengeId;
            _verificationEmailSent = result.verificationEmailSent;
            _signupVerified = false;
          });
        }
      } else {
        final result = _challengeId == null
            ? await widget.authService.login(
                _emailController.text,
                _passwordController.text,
                isAdmin: _mode == _AuthMode.admin,
                rememberMe: _rememberMe,
              )
            : await widget.authService.verifyLogin(
                challengeId: _challengeId!,
                code: _codeController.text.trim(),
                isAdmin: _mode == _AuthMode.admin,
                rememberMe: _rememberMe,
              );
        if (!mounted) return;
        if (result.user case final user?) {
          if (result.isAdmin) {
            widget.onAdminAuthenticated(user);
          } else {
            widget.onAuthenticated(user);
          }
        } else {
          setState(() => _challengeId = result.challengeId);
        }
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = _mode == _AuthMode.signup
              ? 'Could not complete sign-up. Please try again.'
              : 'Sign-in failed. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validatePassword(String? value) {
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

  void _openPasswordReset() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PasswordResetScreen(authService: widget.authService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isAdmin = _mode == _AuthMode.admin;
    final accent = isAdmin ? const Color(0xFF7138E8) : colors.primary;
    final adminScheme = isAdmin
        ? colors.copyWith(
            primary: accent,
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFFF0E9FF),
            onPrimaryContainer: const Color(0xFF361273),
          )
        : colors;
    final authTheme = theme.copyWith(
      colorScheme: adminScheme,
      inputDecorationTheme: isAdmin
          ? theme.inputDecorationTheme.copyWith(
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: accent, width: 1.5),
              ),
            )
          : theme.inputDecorationTheme,
    );

    return Theme(
      data: authTheme,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 380;
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 22,
                  12,
                  compact ? 16 : 22,
                  28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AuthTopBar(
                          onThemeChanged: widget.onThemeChanged,
                          onBack: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(height: 12),
                        _BrandHeader(isAdmin: isAdmin, accent: accent),
                        const SizedBox(height: 22),
                        if (isAdmin)
                          _AdminHeading(
                            accent: accent,
                            verifying: _isVerifyingLogin,
                          )
                        else
                          _UserHeading(
                            mode: _mode,
                            verifyingLogin: _isVerifyingLogin,
                            verifyingSignup: _isVerifyingSignup,
                            signupCreated: _signupCreated,
                          ),
                        const SizedBox(height: 20),
                        if (!isAdmin && !_isVerifyingLogin && !_signupCreated)
                          _AuthModeToggle(mode: _mode, onChanged: _selectMode),
                        if (!isAdmin && !_isVerifyingLogin && !_signupCreated)
                          const SizedBox(height: 18),
                        _AuthCard(
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeInOut,
                            child: Form(
                              key: _formKey,
                              child: _buildFields(context, accent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_errorMessage != null) ...[
                          _ErrorBanner(message: _errorMessage!),
                          const SizedBox(height: 14),
                        ],
                        _submitButton(accent),
                        if (isAdmin)
                          TextButton(
                            onPressed: () => _selectMode(_AuthMode.login),
                            child: const Text('Back to Login / Sign Up'),
                          )
                        else if (_mode == _AuthMode.login && !_isVerifyingLogin)
                          _AdminAccessCard(
                            onTap: () => _selectMode(_AuthMode.admin),
                          )
                        else if (_mode == _AuthMode.signup && !_signupCreated)
                          TextButton(
                            onPressed: () => _selectMode(_AuthMode.login),
                            child: const Text('Already have an account? Login'),
                          ),
                        if (_mode == _AuthMode.login &&
                            !_isVerifyingLogin &&
                            !_signupCreated)
                          TextButton(
                            onPressed: () => _selectMode(_AuthMode.signup),
                            child: const Text("Don't have an account? Sign Up"),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Your credentials are sent securely to ScamShield. '
                          'Passwords are not stored on this device.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFields(BuildContext context, Color accent) {
    if (_isVerifyingLogin || _isVerifyingSignup) {
      final signupVerification = _isVerifyingSignup;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            signupVerification
                ? 'Email verification code'
                : 'Verification code',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _codeController,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 6,
            decoration: const InputDecoration(
              hintText: 'Enter the 6-digit code',
              prefixIcon: Icon(Icons.mark_email_read_outlined),
              counterText: '',
            ),
            validator: (value) =>
                value != null && RegExp(r'^\d{6}$').hasMatch(value.trim())
                ? null
                : 'Enter the 6-digit code.',
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your email for the code. It expires in 10 minutes.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    if (_signupCreated) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            _signupVerified
                ? Icons.mark_email_read_outlined
                : Icons.check_circle_outline_rounded,
            color: accent,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            _signupVerified ? 'Account created' : 'Check your email',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            _verificationEmailSent
                ? _signupVerified
                      ? 'Your email is verified. Sign in to continue.'
                      : 'Enter the verification code sent to ${_emailController.text.trim()}.'
                : 'Your account was created. Email verification is unavailable right now.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_mode == _AuthMode.signup) ...[
          _FieldLabel('Full name'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(
              hintText: 'Your full name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter your full name.'
                : null,
          ),
          const SizedBox(height: 14),
        ],
        _FieldLabel('Email'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            hintText: 'you@example.com',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
          validator: (value) =>
              value != null &&
                  RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())
              ? null
              : 'Enter a valid email address.',
        ),
        const SizedBox(height: 14),
        _FieldLabel('Password'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: _mode == _AuthMode.signup
              ? TextInputAction.next
              : TextInputAction.done,
          autofillHints: [
            _mode == _AuthMode.signup
                ? AutofillHints.newPassword
                : AutofillHints.password,
          ],
          onFieldSubmitted: (_) {
            if (_mode == _AuthMode.login || _mode == _AuthMode.admin) {
              _submit();
            }
          },
          decoration: InputDecoration(
            hintText: _mode == _AuthMode.signup
                ? 'At least 8 characters'
                : 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          validator: _mode == _AuthMode.signup
              ? _validatePassword
              : (value) => value == null || value.isEmpty
                    ? 'Enter your password.'
                    : null,
        ),
        if (_mode == _AuthMode.signup) ...[
          const SizedBox(height: 14),
          _FieldLabel('Confirm password'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Re-enter your password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _obscureConfirmPassword
                    ? 'Show confirm password'
                    : 'Hide confirm password',
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) => value != _passwordController.text
                ? 'Passwords do not match.'
                : null,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: _termsAccepted,
                onChanged: (value) =>
                    setState(() => _termsAccepted = value ?? false),
                visualDensity: VisualDensity.compact,
              ),
              const Expanded(
                child: Text(
                  'I agree to the ScamShield Terms and Privacy Policy.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ] else if (_mode == _AuthMode.login || _mode == _AuthMode.admin) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 40,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) =>
                      setState(() => _rememberMe = value ?? false),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Remember me',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (_mode == _AuthMode.login)
                TextButton(
                  onPressed: _openPasswordReset,
                  child: const Text('Forgot password?'),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _submitButton(Color accent) {
    final isVerification = _isVerifyingLogin || _isVerifyingSignup;
    final label = switch ((_mode, isVerification, _signupCreated)) {
      (_, true, _) =>
        _isVerifyingSignup ? 'VERIFY EMAIL' : 'VERIFY AND SIGN IN',
      (_AuthMode.login, _, _) => 'LOGIN',
      (_AuthMode.signup, _, true) => 'BACK TO LOGIN',
      (_AuthMode.signup, _, false) => 'CREATE ACCOUNT',
      (_AuthMode.admin, _, _) => 'ADMIN LOGIN',
    };
    return FilledButton(
      onPressed: _loading ? null : _submit,
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
      ),
      child: _loading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Text(_loadingLabel),
              ],
            )
          : Text(label),
    );
  }
}

class _AuthTopBar extends StatelessWidget {
  const _AuthTopBar({required this.onThemeChanged, required this.onBack});

  final ValueChanged<bool> onThemeChanged;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const Spacer(),
        ThemeModeToggle(isDarkMode: isDarkMode, onChanged: onThemeChanged),
      ],
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.isAdmin, required this.accent});

  final bool isAdmin;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ScamShieldBrandMark(size: 54),
        const SizedBox(height: 8),
        Text(
          isAdmin ? 'SCAMSHIELD' : 'ScamShield',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          isAdmin ? 'ADMIN PORTAL' : 'AI-POWERED SCAM PROTECTION',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: accent,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _UserHeading extends StatelessWidget {
  const _UserHeading({
    required this.mode,
    required this.verifyingLogin,
    required this.verifyingSignup,
    required this.signupCreated,
  });

  final _AuthMode mode;
  final bool verifyingLogin;
  final bool verifyingSignup;
  final bool signupCreated;

  @override
  Widget build(BuildContext context) {
    final heading = verifyingLogin
        ? 'Verify your sign-in'
        : verifyingSignup
        ? 'Verify your email'
        : signupCreated
        ? 'Account created'
        : mode == _AuthMode.signup
        ? 'Create an account'
        : 'Welcome back';
    final detail = verifyingLogin || verifyingSignup
        ? 'Enter the 6-digit code sent to your email.'
        : signupCreated
        ? 'Your ScamShield account is ready.'
        : mode == _AuthMode.signup
        ? 'Join ScamShield to stay informed and protected.'
        : 'Sign in or create an account to continue with ScamShield.';
    return Column(
      children: [
        Text(
          heading,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _AdminHeading extends StatelessWidget {
  const _AdminHeading({required this.accent, required this.verifying});

  final Color accent;
  final bool verifying;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_outlined, color: accent, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Secure access for authorized administrators only.',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: accent, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          verifying ? 'Verify admin sign-in' : 'Admin Sign-in',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to access the ScamShield Admin Portal.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _AuthModeToggle extends StatelessWidget {
  const _AuthModeToggle({required this.mode, required this.onChanged});

  final _AuthMode mode;
  final ValueChanged<_AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          _AuthModeButton(
            label: 'Login',
            selected: mode == _AuthMode.login,
            onTap: () => onChanged(_AuthMode.login),
          ),
          _AuthModeButton(
            label: 'Sign Up',
            selected: mode == _AuthMode.signup,
            onTap: () => onChanged(_AuthMode.signup),
          ),
        ],
      ),
    );
  }
}

class _AuthModeButton extends StatelessWidget {
  const _AuthModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? colors.onPrimary : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.12
                  : 0.035,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.labelLarge
        ?.copyWith(fontWeight: FontWeight.w700),
  );
}

class _AdminAccessCard extends StatelessWidget {
  const _AdminAccessCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Material(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  color: colors.primary,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Sign-in',
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Access the ScamShield Admin Portal',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colors.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
