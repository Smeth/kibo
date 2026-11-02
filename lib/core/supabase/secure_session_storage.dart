import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// La session reste sur l’appareil, chiffrée ; aucun mot de passe n’est conservé.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({
    required String projectHost,
    FlutterSecureStorage? storage,
  }) : _key = 'kibo.session.$projectHost',
       _storage = storage ?? const FlutterSecureStorage();

  final String _key;
  final FlutterSecureStorage _storage;
  Future<void> _pending = Future<void>.value();

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _pending.then((_) => operation());
    _pending = next.catchError((Object _) {});
    return next;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: _key);

  @override
  Future<String?> accessToken() => _storage.read(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _enqueue(() => _storage.write(key: _key, value: persistSessionString));

  @override
  Future<void> removePersistedSession() =>
      _enqueue(() => _storage.delete(key: _key));
}

/// Même protection pour les vérificateurs temporaires du protocole PKCE.
class SecurePkceStorage extends GotrueAsyncStorage {
  SecurePkceStorage({required this.projectHost, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  final String projectHost;
  final FlutterSecureStorage _storage;
  String _key(String key) => 'kibo.pkce.$projectHost.$key';

  @override
  Future<String?> getItem({required String key}) =>
      _storage.read(key: _key(key));
  @override
  Future<void> setItem({required String key, required String value}) =>
      _storage.write(key: _key(key), value: value);
  @override
  Future<void> removeItem({required String key}) =>
      _storage.delete(key: _key(key));
}
