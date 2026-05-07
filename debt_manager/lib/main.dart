import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'core/security/encryption_service.dart';
import 'core/theme/app_theme.dart';
import 'data/models/customer_model.dart';
import 'data/models/debt_model.dart';
import 'data/repositories/debt_repository.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/add_customer_screen.dart';
import 'presentation/screens/customer_detail_screen.dart';
import 'presentation/screens/add_debt_screen.dart';
import 'providers/debt_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Hive
  await Hive.initFlutter();
  Hive.registerAdapter(CustomerModelAdapter());
  Hive.registerAdapter(DebtModelAdapter());

  // Encrypted storage
  final encKey = await EncryptionService.getOrCreateHiveKey();
  final cipher = HiveAesCipher(encKey);

  final repo = DebtRepository();
  await repo.init(cipher);

  runApp(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
      ],
      child: const DebtManagerApp(),
    ),
  );
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/add-customer',
      builder: (context, state) => const AddCustomerScreen(),
    ),
    GoRoute(
      path: '/customer/:id',
      builder: (context, state) => CustomerDetailScreen(
        customerId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/customer/:id/add-debt',
      builder: (context, state) => AddDebtScreen(
        customerId: state.pathParameters['id']!,
      ),
    ),
  ],
);

class DebtManagerApp extends StatelessWidget {
  const DebtManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DebtBook',
      theme: AppTheme.dark,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
