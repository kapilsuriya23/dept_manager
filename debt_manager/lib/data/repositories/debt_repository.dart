import 'package:hive_flutter/hive_flutter.dart';
import '../models/customer_model.dart';
import '../models/debt_model.dart';
import '../models/credit_model.dart';
import '../../core/security/encryption_service.dart';

class DebtRepository {
  late Box<CustomerModel> _customerBox;
  late Box<DebtModel> _debtBox;
  late Box<CreditModel> _creditBox;

  Future<void> init(HiveCipher cipher) async {
    _customerBox = await Hive.openBox<CustomerModel>(
      'customers',
      encryptionCipher: cipher,
    );
    _debtBox = await Hive.openBox<DebtModel>(
      'debts',
      encryptionCipher: cipher,
    );
    _creditBox = await Hive.openBox<CreditModel>(
      'credits',
      encryptionCipher: cipher,
    );
  }

  // ── Customers ──────────────────────────────────────────
  List<CustomerModel> getAllCustomers() => _customerBox.values.toList();

  Future<void> addCustomer(CustomerModel customer) async {
    customer.name = EncryptionService.sanitize(customer.name);
    customer.phone = EncryptionService.sanitize(customer.phone);
    if (customer.address != null) {
      customer.address = EncryptionService.sanitize(customer.address!);
    }
    await _customerBox.put(customer.id, customer);
  }

  Future<void> deleteCustomer(String customerId) async {
    final debtKeys = _debtBox.values
        .where((d) => d.customerId == customerId)
        .map((d) => d.key)
        .toList();
    await _debtBox.deleteAll(debtKeys);

    final creditKeys = _creditBox.values
        .where((c) => c.customerId == customerId)
        .map((c) => c.key)
        .toList();
    await _creditBox.deleteAll(creditKeys);

    await _customerBox.delete(customerId);
  }

  // ── Debts ──────────────────────────────────────────────
  List<DebtModel> getDebtsForCustomer(String customerId) {
    final list = _debtBox.values
        .where((d) => d.customerId == customerId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> addDebt(DebtModel debt) async {
    debt.description = EncryptionService.sanitize(debt.description);
    await _debtBox.put(debt.id, debt);
  }

  Future<void> markDebtPaid(String debtId) async {
    final debt = _debtBox.get(debtId);
    if (debt != null) {
      debt.isPaid = true;
      debt.paidAt = DateTime.now();
      await debt.save();
    }
  }

  Future<void> deleteDebt(String debtId) async {
    await _debtBox.delete(debtId);
  }

  // ── Credits ────────────────────────────────────────────
  List<CreditModel> getCreditsForCustomer(String customerId) {
    final list = _creditBox.values
        .where((c) => c.customerId == customerId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> addCredit(CreditModel credit) async {
    credit.description = EncryptionService.sanitize(credit.description);
    await _creditBox.put(credit.id, credit);
  }

  Future<void> deleteCredit(String creditId) async {
    await _creditBox.delete(creditId);
  }

  // ── Balances ───────────────────────────────────────────

  /// Total debt (unpaid) minus total credits for a customer
  double getNetBalanceForCustomer(String customerId) {
    final totalDebt = _debtBox.values
        .where((d) => d.customerId == customerId && !d.isPaid)
        .fold(0.0, (s, d) => s + d.amount);
    final totalCredit = _creditBox.values
        .where((c) => c.customerId == customerId)
        .fold(0.0, (s, c) => s + c.amount);
    return (totalDebt - totalCredit).clamp(0.0, double.infinity);
  }

  /// App-wide net outstanding
  double getTotalOutstanding() {
    double total = 0;
    for (final c in _customerBox.values) {
      total += getNetBalanceForCustomer(c.id);
    }
    return total;
  }

  // kept for backward compat (used in CustomerCard)
  double getTotalOutstandingForCustomer(String customerId) =>
      getNetBalanceForCustomer(customerId);
}
