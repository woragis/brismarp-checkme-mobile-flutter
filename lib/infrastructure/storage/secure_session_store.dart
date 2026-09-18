import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'session_store.dart';

/// Secure storage with SharedPreferences fallback (Linux without libsecret).
class SecureSessionStore implements SessionStore {
  SecureSessionStore({
    FlutterSecureStorage? secure,
    this._prefs,
  }) : _secure = secure ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secure;
  SharedPreferences? _prefs;
  bool _secureOk = true;

  Future<SharedPreferences> _prefsOr() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<String?> read(String key) async {
    if (_secureOk) {
      try {
        return await _secure.read(key: key);
      } catch (_) {
        _secureOk = false;
      }
    }
    return (await _prefsOr()).getString(key);
  }

  @override
  Future<void> write(String key, String value) async {
    if (_secureOk) {
      try {
        await _secure.write(key: key, value: value);
        return;
      } catch (_) {
        _secureOk = false;
      }
    }
    await (await _prefsOr()).setString(key, value);
  }

  @override
  Future<void> delete(String key) async {
    if (_secureOk) {
      try {
        await _secure.delete(key: key);
        return;
      } catch (_) {
        _secureOk = false;
      }
    }
    await (await _prefsOr()).remove(key);
  }
}
