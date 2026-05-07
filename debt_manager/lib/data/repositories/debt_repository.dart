import 'package:hive_flutter/hive_flutter.dart';
import '../models/customer_model.dart';
import '../models/debt_model.dart';
import '../../core/security/encryption_service.dart';

class DebtRepository {
  late Box<CustomerModel> _customerBox;
  late Box<DebtModel> _debtBox;

  Future<void> init(HiveCipher cipher) async {
    _customerBox = await Hive.openBox<CustomerModel>(
      'customers',
      encryptionCipher: cipher,
    );
    _debtBox = await Hive.openBox<DebtModel>(
      'debts',
      encryptionCipher: cipher,
    );
  }

  // ── Customers ──────────────────────────────────────────────
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
    final keys = _debtBox.values
        .where((d) => d.customerId == customerId)
        .map((d) => d.key)
        .toList();
    await _debtBox.deleteAll(keys);
    await _customerBox.delete(customerId);
  }

  // ── Debts ──────────────────────────────────────────────────
  List<DebtModel> getDebtsForCustomer(String customerId) {
    final list =
        _debtBox.values.where((d) => d.customerId == customerId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
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

  double getTotalOutstanding() {
    return _debtBox.values
        .where((d) => !d.isPaid)
        .fold(0.0, (sum, d) => sum + d.amount);
  }

  double getTotalOutstandingForCustomer(String customerId) {
    return _debtBox.values
        .where((d) => d.customerId == customerId && !d.isPaid)
        .fold(0.0, (sum, d) => sum + d.amount);
  }
}
