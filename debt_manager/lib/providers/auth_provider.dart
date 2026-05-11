import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.loading,
    this.user,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, UserModel? user, String? error}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;
  AuthNotifier(this._service) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    // Check token exists locally first — no network call
    final token = await _service.getMe();
    state = AuthState(
      status:
          token != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      user: token,
    );
  }

  Future<bool> login({required String phone, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final user = await _service.login(phone: phone, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state =
          AuthState(status: AuthStatus.unauthenticated, error: e.toString());
      return false;
    }
  }

  Future<bool> register({
    required String shopName,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final user = await _service.register(
          shopName: shopName, phone: phone, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state =
          AuthState(status: AuthStatus.unauthenticated, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _service.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authServiceProvider = Provider((_) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authServiceProvider)),
);
