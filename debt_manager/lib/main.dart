import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/add_customer_screen.dart';
import 'presentation/screens/customer_detail_screen.dart';
import 'presentation/screens/add_debt_screen.dart';
import 'presentation/screens/add_credit_screen.dart';
import 'presentation/screens/privacy_policy_screen.dart';
import 'providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DebtManagerApp()));
}

class DebtManagerApp extends StatelessWidget {
  const DebtManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          final authState = ref.watch(authProvider);

          final router = GoRouter(
            initialLocation: '/login',
            redirect: (context, state) {
              final isAuth = authState.status == AuthStatus.authenticated;
              final isLoading = authState.status == AuthStatus.loading;
              final onLogin = state.matchedLocation == '/login';
              final onRegister = state.matchedLocation == '/register';

              // Still checking token — stay on login quietly
              if (isLoading) return null;

              // Authenticated but on login/register → go home
              if (isAuth && (onLogin || onRegister)) return '/';

              // Not authenticated and not on login/register → go login
              if (!isAuth && !onLogin && !onRegister) return '/login';

              return null;
            },
            routes: [
              GoRoute(
                path: '/login',
                builder: (c, s) => const LoginScreen(),
              ),
              GoRoute(
                path: '/register',
                builder: (c, s) => const RegisterScreen(),
              ),
              GoRoute(
                path: '/',
                builder: (c, s) => const HomeScreen(),
              ),
              GoRoute(
                path: '/add-customer',
                builder: (c, s) => const AddCustomerScreen(),
              ),
              GoRoute(
                path: '/customer/:id',
                builder: (c, s) => CustomerDetailScreen(
                  customerId: s.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: '/customer/:id/add-debt',
                builder: (c, s) => AddDebtScreen(
                  customerId: s.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: '/customer/:id/add-credit',
                builder: (c, s) => AddCreditScreen(
                  customerId: s.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: '/privacy-policy',
                builder: (c, s) => const PrivacyPolicyScreen(),
              ),
            ],
          );

          return MaterialApp.router(
            title: 'DebtBook',
            theme: AppTheme.light,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
