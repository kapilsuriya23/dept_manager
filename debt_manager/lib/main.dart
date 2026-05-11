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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DebtManagerApp()));
}

// Router lives outside widget tree — never rebuilt
final _router = GoRouter(
  initialLocation: '/login',
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

class DebtManagerApp extends StatelessWidget {
  const DebtManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DebtBook',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
