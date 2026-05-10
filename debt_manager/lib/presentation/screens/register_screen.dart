import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _cpassCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _shopCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _cpassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    HapticFeedback.lightImpact();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final ok = await ref.read(authProvider.notifier).register(
          shopName: _shopCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          password: _passCtrl.text,
        );
    if (mounted) {
      setState(() => _loading = false);
      if (!ok) {
        HapticFeedback.heavyImpact();
        final err = ref.read(authProvider).error ?? 'Registration failed';
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 30),

            // ── Header ─────────────────────────────────────
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
                  Text('Create Account',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('Register your shop to get started',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // ── Form ───────────────────────────────────────
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Shop Name
                  TextFormField(
                    controller: _shopCtrl,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Shop Name',
                      prefixIcon:
                          Icon(Icons.store_outlined, color: AppTheme.textHint),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Shop name required'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone, color: AppTheme.textHint),
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

                  // Password
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon:
                          Icon(Icons.lock_outline, color: AppTheme.textHint),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppTheme.textHint,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password required';
                      if (v.length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextFormField(
                    controller: _cpassCtrl,
                    obscureText: _obscure,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon:
                          Icon(Icons.lock_outline, color: AppTheme.textHint),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please confirm password';
                      }
                      if (v != _passCtrl.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // ── Button ────────────────────────────────
                  _ActionButton(
                    label: 'Create Account',
                    loading: _loading,
                    onPressed: _submit,
                    color: AppTheme.primaryGreen,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Login link ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account? ',
                    style: TextStyle(color: AppTheme.textSecondary)),
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Text('Sign In',
                      style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  final Color color;

  const _ActionButton({
    required this.label,
    required this.loading,
    required this.onPressed,
    required this.color,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 80),
    lowerBound: 0.0,
    upperBound: 0.05,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.95,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward();
  void _onTapUp(TapUpDetails _) => _ctrl.reverse();
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.loading ? null : _onTapDown,
      onTapUp: widget.loading ? null : _onTapUp,
      onTapCancel: widget.loading ? null : _onTapCancel,
      onTap: widget.loading ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color:
                widget.loading ? widget.color.withOpacity(0.7) : widget.color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.loading
                ? []
                : [
                    BoxShadow(
                      color: widget.color.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: widget.loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }
}
