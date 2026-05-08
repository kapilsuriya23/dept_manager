import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Wait for auth check
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final status = ref.read(authProvider).status;
    if (status == AuthStatus.authenticated) {
      context.go('/');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Also react if auth resolves before delay
    ref.listen(authProvider, (_, next) {
      if (next.status == AuthStatus.authenticated) context.go('/');
      if (next.status == AuthStatus.unauthenticated) context.go('/login');
    });

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.store_rounded,
                  size: 56, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 20),
            Text('DebtBook',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 6),
            Text("Dad's Shop Manager",
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 40),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
