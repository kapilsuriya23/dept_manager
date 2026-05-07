import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'core/security/encryption_service.dart';
import 'core/theme/app_theme.dart';
import 'data/models/customer_model.dart';
import 'data/models/debt_model.dart';
import 'data/models/credit_model.dart';
import 'data/repositories/debt_repository.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/add_customer_screen.dart';
import 'presentation/screens/customer_detail_screen.dart';
import 'presentation/screens/add_debt_screen.dart';
import 'presentation/screens/add_credit_screen.dart';
import 'providers/debt_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(CustomerModelAdapter());
  Hive.registerAdapter(DebtModelAdapter());
  Hive.registerAdapter(CreditModelAdapter());
  final encKey = await EncryptionService.getOrCreateHiveKey();
  final cipher = HiveAesCipher(encKey);
  final repo = DebtRepository();
  await repo.init(cipher);
  runApp(
    ProviderScope(
      overrides: [repositoryProvider.overrideWithValue(repo)],
      child: const DebtManagerApp(),
    ),
  );
}

final GoRouter _router = GoRouter(
  routes: [
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
  ],
);

class DebtManagerApp extends StatelessWidget {
  const DebtManagerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'DebtBook',
        theme: AppTheme.light,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      );
}
