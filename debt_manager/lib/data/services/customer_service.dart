import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class CustomerService {
  final _client = ApiClient.instance;

  Future<List<Map<String, dynamic>>> getAll() async {
    final res = await _client.get(ApiEndpoints.customers);
    return List<Map<String, dynamic>>.from(res['data']);
  }

  Future<Map<String, dynamic>> create({
    required String name,
    required String phone,
    String? address,
  }) async {
    final res = await _client.post(
      ApiEndpoints.customers,
      {'name': name, 'phone': phone, if (address != null) 'address': address},
      auth: true,
    );
    return res['data'];
  }

  Future<void> delete(String id) async {
    await _client.delete(ApiEndpoints.customer(id));
  }
}
