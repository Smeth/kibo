import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const pushEnabled = bool.fromEnvironment('KIBO_PUSH_ENABLED');
const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
const _appId = String.fromEnvironment('FIREBASE_APP_ID');
const _sender = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
const _project = String.fromEnvironment('FIREBASE_PROJECT_ID');
bool get pushConfigured =>
    pushEnabled &&
    !kIsWeb &&
    defaultTargetPlatform == TargetPlatform.android &&
    [_apiKey, _appId, _sender, _project].every((v) => v.isNotEmpty);

/// Token values stay in local secure storage and server RPCs, never in logs.
class PushRegistration {
  PushRegistration(this.client);
  final SupabaseClient client;
  static const _storage = FlutterSecureStorage();
  StreamSubscription<String>? _refresh;
  StreamSubscription<AuthState>? _auth;
  bool _started = false;
  String get _prefix => 'kibo-push-${Uri.parse(client.rest.url).host}';
  Future<void> _initialize() async {
    if (!pushConfigured) throw StateError('Push unavailable');
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: _apiKey,
          appId: _appId,
          messagingSenderId: _sender,
          projectId: _project,
        ),
      );
    }
  }

  Future<void> start() async {
    if (_started || !pushConfigured) return;
    _started = true;
    _auth = client.auth.onAuthStateChange.listen((event) {
      if (event.session != null) unawaited(_restore());
    });
    await _restore();
  }

  Future<void> _restore() async {
    try {
      final owner = client.auth.currentUser?.id;
      if (owner == null ||
          await _storage.read(key: '$_prefix-consent-$owner') != 'yes') {
        return;
      }
      await _initialize();
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        return;
      }
      final token = await _token();
      if (client.auth.currentUser?.id == owner) {
        await _register(owner, token);
      }
      _refresh ??= FirebaseMessaging.instance.onRegistered.listen((token) {
        final current = client.auth.currentUser?.id;
        if (current != null) unawaited(_refreshToken(current, token));
      });
    } catch (_) {
      /* Internal notifications remain available. */
    }
  }

  Future<void> _refreshToken(String owner, String token) async {
    try {
      if (await _storage.read(key: '$_prefix-consent-$owner') == 'yes' &&
          client.auth.currentUser?.id == owner) {
        await _register(owner, token);
      }
    } catch (_) {
      /* The next authenticated startup retries registration. */
    }
  }

  Future<String> _token() async {
    final completer = Completer<String>();
    final subscription = FirebaseMessaging.instance.onRegistered.listen(
      (token) {
        if (!completer.isCompleted) completer.complete(token);
      },
      onError: (Object error) {
        if (!completer.isCompleted) {
          completer.completeError(StateError('Registration failed'));
        }
      },
    );
    try {
      await FirebaseMessaging.instance.register();
      return await completer.future.timeout(const Duration(seconds: 20));
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> _register(String owner, String token) async {
    if (client.auth.currentUser?.id != owner) {
      throw StateError('Session changed');
    }
    await client.rpc('kibo_push_register', params: {'p_token': token});
    if (client.auth.currentUser?.id != owner) {
      throw StateError('Session changed');
    }
    await _storage.write(key: '$_prefix-token', value: token);
  }

  Future<bool> enable() async {
    final owner = client.auth.currentUser?.id;
    if (owner == null) throw StateError('Authentication required');
    await _initialize();
    final permission = await FirebaseMessaging.instance.requestPermission();
    if (permission.authorizationStatus != AuthorizationStatus.authorized) {
      return false;
    }
    if (client.auth.currentUser?.id != owner) {
      throw StateError('Session changed');
    }
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    final token = await _token();
    await _register(owner, token);
    await _storage.write(key: '$_prefix-consent-$owner', value: 'yes');
    return true;
  }

  Future<void> disable() async {
    if (!pushConfigured) return;
    final owner = client.auth.currentUser?.id;
    final token = await _storage.read(key: '$_prefix-token');
    try {
      if (token != null && owner != null) {
        await client.rpc('kibo_push_unregister', params: {'p_token': token});
      }
    } finally {
      if (owner != null) await _storage.delete(key: '$_prefix-consent-$owner');
      await _storage.delete(key: '$_prefix-token');
      if (Firebase.apps.isNotEmpty) {
        await FirebaseMessaging.instance.setAutoInitEnabled(false);
        await FirebaseMessaging.instance.unregister();
      }
    }
  }

  Future<void> dispose() async {
    await _refresh?.cancel();
    await _auth?.cancel();
  }
}
