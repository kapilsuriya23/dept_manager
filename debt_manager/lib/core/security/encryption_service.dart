import 'dart:typed_data';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class EncryptionService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<Uint8List> getOrCreateHiveKey() async {
    const keyName = 'hive_box_key';
    final existing = await _storage.read(key: keyName);
    if (existing != null) {
      return base64Decode(existing);
    }
    final rng = Random.secure();
    final key = Uint8List.fromList(List.generate(32, (_) => rng.nextInt(256)));
    await _storage.write(key: keyName, value: base64Encode(key));
    return key;
  }

  static String sanitize(String input) {
    final trimmed = input.trim();
    final cleaned = trimmed.replaceAll(RegExp(r'[<>"\\/;{}]'), '');
    return cleaned.length > 200 ? cleaned.substring(0, 200) : cleaned;
  }
}
