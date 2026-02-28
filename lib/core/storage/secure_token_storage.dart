import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../constants/storage_keys.dart';

/// Wrapper around [FlutterSecureStorage] for storing auth/session values.
///
/// - Android: uses EncryptedSharedPreferences
/// - iOS: uses Keychain
///
/// ✅ Stores only non-sensitive identifiers + access token.
/// ❌ Never store passwords.
class SecureTokenStorage {
  final FlutterSecureStorage _storage;

  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            (kIsWeb
                // Web: stored in browser storage (not the same security
                // guarantees as Keychain/EncryptedSharedPreferences).
                ? const FlutterSecureStorage()
                : const FlutterSecureStorage(
                    aOptions: AndroidOptions(
                      encryptedSharedPreferences: true,
                    ),
                  ));

  // ── Token ─────────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    await _storage.write(key: StorageKeys.token, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: StorageKeys.token);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Employee / Company ────────────────────────────────────────────

  Future<void> saveEmployeeId(int id) async {
    await _storage.write(key: StorageKeys.employeeId, value: id.toString());
  }

  Future<int?> getEmployeeId() async {
    final value = await _storage.read(key: StorageKeys.employeeId);
    if (value == null) return null;
    return int.tryParse(value);
  }

  Future<void> saveCompanyId(int id) async {
    await _storage.write(key: StorageKeys.companyId, value: id.toString());
  }

  Future<int?> getCompanyId() async {
    final value = await _storage.read(key: StorageKeys.companyId);
    if (value == null) return null;
    return int.tryParse(value);
  }

  // ── Clear ─────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
