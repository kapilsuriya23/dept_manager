import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/customer_model.dart';
import '../data/models/debt_model.dart';
import '../data/repositories/debt_repository.dart';

// ── Repository provider ────────────────────────────────────
final repositoryProvider = Provider<DebtRepository>((ref) {
  throw UnimplementedError('Override repositoryProvider in ProviderScope');
});

// ── Customers ──────────────────────────────────────────────
final customersProvider =
    StateNotifierProvider<CustomerNotifier, List<CustomerModel>>(
  (ref) => CustomerNotifier(ref.watch(repositoryProvider)),
);

class CustomerNotifier extends StateNotifier<List<CustomerModel>> {
  final DebtRepository _repo;

  CustomerNotifier(this._repo) : super(_repo.getAllCustomers());

  Future<void> addCustomer({
    required String name,
    required String phone,
    String? address,
  }) async {
    final customer = CustomerModel(
      id: const Uuid().v4(),
      name: name,
      phone: phone,
      address: address,
      createdAt: DateTime.now(),
    );
    await _repo.addCustomer(customer);
    state = _repo.getAllCustomers();
  }

  Future<void> deleteCustomer(String id) async {
    await _repo.deleteCustomer(id);
    state = _repo.getAllCustomers();
  }

  void refresh() {
    state = _repo.getAllCustomers();
  }
}

// ── Debts for a customer ───────────────────────────────────
final customerDebtsProvider =
    StateNotifierProvider.family<DebtNotifier, List<DebtModel>, String>(
  (ref, customerId) => DebtNotifier(ref.watch(repositoryProvider), customerId),
);

class DebtNotifier extends StateNotifier<List<DebtModel>> {
  final DebtRepository _repo;
  final String customerId;

  DebtNotifier(this._repo, this.customerId)
      : super(_repo.getDebtsForCustomer(customerId));

  void refresh() {
    state = _repo.getDebtsForCustomer(customerId);
  }
}

// ── Debt actions ───────────────────────────────────────────
final debtActionsProvider = Provider((ref) => DebtActions(ref));

class DebtActions {
  final Ref _ref;
  DebtActions(this._ref);

  Future<void> addDebt({
    required String customerId,
    required double amount,
    required String description,
  }) async {
    final debt = DebtModel(
      id: const Uuid().v4(),
      customerId: customerId,
      amount: amount,
      description: description,
      date: DateTime.now(),
    );
    await _ref.read(repositoryProvider).addDebt(debt);
    _ref.read(customerDebtsProvider(customerId).notifier).refresh();
    _ref.read(customersProvider.notifier).refresh();
  }

  Future<void> markPaid(String customerId, String debtId) async {
    await _ref.read(repositoryProvider).markDebtPaid(debtId);
    _ref.read(customerDebtsProvider(customerId).notifier).refresh();
    _ref.read(customersProvider.notifier).refresh();
  }

  Future<void> deleteDebt(String customerId, String debtId) async {
    await _ref.read(repositoryProvider).deleteDebt(debtId);
    _ref.read(customerDebtsProvider(customerId).notifier).refresh();
    _ref.read(customersProvider.notifier).refresh();
  }
}
