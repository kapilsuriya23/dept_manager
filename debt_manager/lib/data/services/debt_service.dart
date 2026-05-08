import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class DebtService {
  final _client = ApiClient.instance;

  Future<List<Map<String, dynamic>>> getForCustomer(String customerId) async {
    final res = await _client.get(ApiEndpoints.debts(customerId));
    return List<Map<String, dynamic>>.from(res['data']);
  }

  Future<Map<String, dynamic>> create({
    required String customerId,
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    final res = await _client.post(
      ApiEndpoints.debts(customerId),
      {
        'amount': amount,
        'description': description,
        'date': date.toIso8601String(),
      },
      auth: true,
    );
    return res['data'];
  }

  Future<void> markPaid(String debtId) async {
    await _client.patch(ApiEndpoints.debtMarkPaid(debtId));
  }

  Future<void> delete(String debtId) async {
    await _client.delete(ApiEndpoints.debt(debtId));
  }
}
