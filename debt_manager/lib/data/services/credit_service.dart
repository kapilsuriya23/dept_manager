import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class CreditService {
  final _client = ApiClient.instance;

  Future<List<Map<String, dynamic>>> getForCustomer(String customerId) async {
    final res = await _client.get(ApiEndpoints.credits(customerId));
    return List<Map<String, dynamic>>.from(res['data']);
  }

  Future<Map<String, dynamic>> create({
    required String customerId,
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    final res = await _client.post(
      ApiEndpoints.credits(customerId),
      {
        'amount': amount,
        'description': description,
        'date': date.toIso8601String(),
      },
      auth: true,
    );
    return res['data'];
  }

  Future<void> delete(String creditId) async {
    await _client.delete(ApiEndpoints.credit(creditId));
  }
}
