import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../screens/home_screen.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // React as soon as auth state resolves from loading
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.loading) return;
      if (next.status == AuthStatus.authenticated) {
        context.go('/');
      } else {
        context.go('/login');
      }
    });

    // If already resolved when splash builds (cached token check fast)
    final status = ref.read(authProvider).status;
    if (status == AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
    } else if (status == AuthStatus.unauthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
    }
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.store_rounded,
                  size: 56, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 24),
            Text(
              user?.shopName ?? 'DebtBook',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Credit & Debit Manager",
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 28,
              height: 28,
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
