import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/user_model.dart';

class AuthService {
  final _client = ApiClient.instance;

  Future<UserModel> register({
    required String shopName,
    required String phone,
    required String password,
  }) async {
    final res = await _client.post(ApiEndpoints.register, {
      'shopName': shopName,
      'phone': phone,
      'password': password,
    });
    await _client.saveToken(res['token']);
    return UserModel.fromJson(res['user']);
  }

  Future<UserModel> login({
    required String phone,
    required String password,
  }) async {
    final res = await _client.post(ApiEndpoints.login, {
      'phone': phone,
      'password': password,
    });
    await _client.saveToken(res['token']);
    return UserModel.fromJson(res['user']);
  }

  Future<UserModel?> getMe() async {
    try {
      final token = await _client.getToken();
      if (token == null) return null;
      final res = await _client.get(ApiEndpoints.me);
      return UserModel.fromJson(res['user']);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _client.clearToken();
  }
}
