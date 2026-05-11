import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    if (!_formKey.currentState!.validate()) return;

    // Show overlay immediately
    setState(() => _loading = true);

    final ok = await ref.read(authProvider.notifier).login(
          phone: _phoneCtrl.text.trim(),
          password: _passCtrl.text,
        );

    if (!mounted) return;

    if (ok) {
      // Keep loading true — router will navigate away
      // No need to setState here
    } else {
      setState(() => _loading = false);
      HapticFeedback.heavyImpact();
      final err = ref.read(authProvider).error ?? 'Login failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppTheme.dangerColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppTheme.bgPage,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 40),

                // ── Logo ───────────────────────────────────
                Center(
                  child: Column(
                    children: [
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
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to your shop account',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // ── Form ───────────────────────────────────
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
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
                                : () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Password required'
                            : null,
                      ),
                      const SizedBox(height: 28),

                      // ── Sign In Button ────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppTheme.primaryGreen.withOpacity(0.7),
                            elevation: 3,
                            shadowColor: AppTheme.primaryGreen.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Register link ──────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    GestureDetector(
                      onTap: _loading ? null : () => context.go('/register'),
                      child: Text(
                        'Register',
                        style: TextStyle(
                          color: _loading
                              ? AppTheme.textHint
                              : AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Loading overlay ────────────────────────────────
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
                          CircularProgressIndicator(
                            color: AppTheme.primaryGreen,
                            strokeWidth: 3.5,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Signing in...',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please wait',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
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
}
