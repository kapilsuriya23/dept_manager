import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../data/services/biometric_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure  = true;
  bool _loading  = false;
  bool _showForm = false; // hidden until biometric fails/unavailable

  @override
  void initState() {
    super.initState();
    _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    final available = await BiometricService.isAvailable();
    final hasCreds  = await BiometricService.hasSavedCredentials();

    // Show biometric only when device supports it AND creds are saved
    if (available && hasCreds) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      await _loginWithBiometric();
    } else {
      // No biometric or first time — show form directly
      if (mounted) setState(() => _showForm = true);
    }
  }

  Future<void> _loginWithBiometric() async {
    setState(() => _loading = true);

    final creds = await BiometricService.authenticate();

    if (!mounted) return;

    if (creds != null) {
      final ok = await ref.read(authProvider.notifier).login(
            phone: creds['phone']!,
            password: creds['password']!,
          );
      if (!mounted) return;
      if (ok) {
        context.go('/');
        return;
      }
    }

    // Biometric failed or cancelled — show password form
    setState(() {
      _loading   = false;
      _showForm  = true;
    });
  }

  Future<void> _submitPassword() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final ok = await ref.read(authProvider.notifier).login(
          phone: _phoneCtrl.text.trim(),
          password: _passCtrl.text,
        );

    if (!mounted) return;

    if (ok) {
      // Save credentials for future biometric logins
      await BiometricService.saveCredentials(
        _phoneCtrl.text.trim(),
        _passCtrl.text,
      );
      context.go('/');
    } else {
      setState(() => _loading = false);
      HapticFeedback.heavyImpact();
      final err = ref.read(authProvider).error ?? 'Login failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppTheme.dangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppTheme.bgPage,
          body: SafeArea(
            child: _showForm
                ? _buildForm()
                : _buildBiometricWaiting(),
          ),
        ),

        // ── Loading overlay ─────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _loading
              ? Container(
                  key: const ValueKey('loader'),
                  color: Colors.black54,
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PulsingIcon(),
                          const SizedBox(height: 20),
                          Text('Signing in...',
                              style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Please wait',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('empty')),
        ),
      ],
    );
  }

  // ── Biometric waiting screen ─────────────────────────────
  Widget _buildBiometricWaiting() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.store_rounded,
                size: 52, color: AppTheme.primaryGreen),
          ),
          const SizedBox(height: 20),
          Text('DebtBook',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Authenticating...',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 32),
          CircularProgressIndicator(
              color: AppTheme.primaryGreen, strokeWidth: 2.5),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => setState(() => _showForm = true),
            child: Text('Use password instead',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── Password form ────────────────────────────────────────
  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 40),

        // Logo
        Center(
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.store_rounded,
                  size: 48, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 16),
            Text('Welcome Back',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Sign in to your shop account',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14)),
          ]),
        ),
        const SizedBox(height: 40),

        // Form
        Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              enabled: !_loading,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon:
                    Icon(Icons.phone, color: AppTheme.textHint),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Phone required';
                }
                if (!RegExp(r'^\d{10}$').hasMatch(v.trim())) {
                  return 'Enter valid 10-digit number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              enabled: !_loading,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline,
                    color: AppTheme.textHint),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppTheme.textHint,
                  ),
                  onPressed: _loading
                      ? null
                      : () =>
                          setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Password required' : null,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppTheme.primaryGreen.withOpacity(0.7),
                  elevation: 3,
                  shadowColor:
                      AppTheme.primaryGreen.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Sign In',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        // Register link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Don't have an account? ",
                style: TextStyle(color: AppTheme.textSecondary)),
            GestureDetector(
              onTap: _loading ? null : () => context.go('/register'),
              child: Text('Register',
                  style: TextStyle(
                    color: _loading
                        ? AppTheme.textHint
                        : AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Pulsing icon ─────────────────────────────────────────────
class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon();
  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(
    begin: 0.88, end: 1.08,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.5, end: 1.0,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryGreen
                  .withOpacity(_opacity.value * 0.15),
              border: Border.all(
                color: AppTheme.primaryGreen
                    .withOpacity(_opacity.value * 0.4),
                width: 2,
              ),
            ),
            child: Icon(Icons.store_rounded,
                color: AppTheme.primaryGreen
                    .withOpacity(_opacity.value),
                size: 30),
          ),
        ),
      );
}