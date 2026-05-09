import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/customer_service.dart';
import '../data/services/debt_service.dart';
import '../data/services/credit_service.dart';

// ── Service providers ──────────────────────────────────────
final customerServiceProvider =
    Provider<CustomerService>((_) => CustomerService());
final debtServiceProvider = Provider<DebtService>((_) => DebtService());
final creditServiceProvider = Provider<CreditService>((_) => CreditService());

// ── Customer state ─────────────────────────────────────────
class CustomerState {
  final List<Map<String, dynamic>> customers;
  final bool loading;
  final String? error;

  const CustomerState({
    this.customers = const [],
    this.loading = false,
    this.error,
  });

  CustomerState copyWith({
    List<Map<String, dynamic>>? customers,
    bool? loading,
    String? error,
  }) =>
      CustomerState(
        customers: customers ?? this.customers,
        loading: loading ?? this.loading,
        error: error,
      );
}

class CustomerNotifier extends StateNotifier<CustomerState> {
  final CustomerService _service;
  CustomerNotifier(this._service) : super(const CustomerState()) {
    fetchAll();
  }

  Future<void> fetchAll() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final list = await _service.getAll();
      state = state.copyWith(customers: list, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> addCustomer({
    required String name,
    required String phone,
    String? address,
  }) async {
    try {
      await _service.create(name: name, phone: phone, address: address);
      await fetchAll();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    try {
      await _service.delete(id);
      await fetchAll();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final customersProvider =
    StateNotifierProvider<CustomerNotifier, CustomerState>(
  (ref) => CustomerNotifier(ref.read(customerServiceProvider)),
);

// ── Transaction state ──────────────────────────────────────
class TransactionState {
  final List<Map<String, dynamic>> debts;
  final List<Map<String, dynamic>> credits;
  final bool loading;
  final String? error;

  const TransactionState({
    this.debts = const [],
    this.credits = const [],
    this.loading = false,
    this.error,
  });

  double get totalDebt => debts
      .where((d) => d['isPaid'] == false)
      .fold(0.0, (s, d) => s + (d['amount'] as num).toDouble());

  double get totalCredit =>
      credits.fold(0.0, (s, c) => s + (c['amount'] as num).toDouble());

  double get netBalance =>
      (totalDebt - totalCredit).clamp(0.0, double.infinity);

  TransactionState copyWith({
    List<Map<String, dynamic>>? debts,
    List<Map<String, dynamic>>? credits,
    bool? loading,
    String? error,
  }) =>
      TransactionState(
        debts: debts ?? this.debts,
        credits: credits ?? this.credits,
        loading: loading ?? this.loading,
        error: error,
      );
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  final DebtService _debtService;
  final CreditService _creditService;
  final String customerId;

  TransactionNotifier(
    this._debtService,
    this._creditService,
    this.customerId,
  ) : super(const TransactionState()) {
    fetchAll();
  }

  Future<void> fetchAll() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final results = await Future.wait([
        _debtService.getForCustomer(customerId),
        _creditService.getForCustomer(customerId),
      ]);
      state = state.copyWith(
        debts: results[0],
        credits: results[1],
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> addDebt({
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    try {
      await _debtService.create(
        customerId: customerId,
        amount: amount,
        description: description,
        date: date,
      );
      await fetchAll();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> addCredit({
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    try {
      await _creditService.create(
        customerId: customerId,
        amount: amount,
        description: description,
        date: date,
      );
      await fetchAll();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> markPaid(String debtId) async {
    try {
      await _debtService.markPaid(debtId);
      await fetchAll();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteDebt(String debtId) async {
    try {
      await _debtService.delete(debtId);
      await fetchAll();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteCredit(String creditId) async {
    try {
      await _creditService.delete(creditId);
      await fetchAll();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final transactionProvider =
    StateNotifierProvider.family<TransactionNotifier, TransactionState, String>(
  (ref, customerId) => TransactionNotifier(
    ref.read(debtServiceProvider),
    ref.read(creditServiceProvider),
    customerId,
  ),
);

final totalOutstandingProvider = Provider<double>((ref) {
  final state = ref.watch(customersProvider);
  return state.customers.fold(
    0.0,
    (sum, c) => sum + ((c['netBalance'] as num?)?.toDouble() ?? 0.0),
  );
});
