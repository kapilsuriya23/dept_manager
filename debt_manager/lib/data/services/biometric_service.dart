import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final _auth = LocalAuthentication();
  static const _phoneKey = 'saved_phone';
  static const _passKey = 'saved_password';

  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      if (!canCheck || !supported) return false;
      final bios = await _auth.getAvailableBiometrics();
      return bios.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneKey) != null &&
        prefs.getString(_passKey) != null;
  }

  static Future<void> saveCredentials(String phone, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phoneKey, phone);
    await prefs.setString(_passKey, password);
  }

  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_phoneKey);
    await prefs.remove(_passKey);
  }

  static Future<Map<String, String>?> authenticate() async {
    try {
      final success = await _auth.authenticate(
        localizedReason: 'Sign in to DebtBook',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // ← allows PIN fallback too
        ),
      );
      if (!success) return null;
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString(_phoneKey);
      final password = prefs.getString(_passKey);
      if (phone == null || password == null) return null;
      return {'phone': phone, 'password': password};
    } catch (_) {
      return null;
    }
  }
}
