import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

import '../config/supabase_config.dart';
import '../config/auth_callback.dart';
import 'secure_session_storage.dart';
import '../diagnostics/photo_upload_diagnostics.dart';

typedef SupabaseInitializer =
    Future<SupabaseClient> Function(SupabaseConfig config);

class SupabaseStartupResult {
  const SupabaseStartupResult.ready() : errorMessage = null;
  const SupabaseStartupResult.failure(this.errorMessage);

  final String? errorMessage;
  bool get isReady => errorMessage == null;
}

/// Une instance au démarrage ; les futurs consommateurs reçoivent ce service.
/// Aucun repository ni opération métier n’est créé ici.
class SupabaseService {
  SupabaseService({required this.config, SupabaseInitializer? initializer})
    : _initializer = initializer;

  final SupabaseConfig config;
  final SupabaseInitializer? _initializer;
  SecureSessionStorage? _sessionStorage;

  Future<void> clearPersistedSession() async {
    await _sessionStorage?.removePersistedSession();
  }

  Future<SupabaseStartupResult>? _startup;
  SupabaseClient? _client;

  SupabaseClient get client =>
      _client ?? (throw StateError('Supabase n’est pas initialisé.'));

  // Le Future est partagé, y compris en cas d’appels concurrents ou d’échec.
  Future<SupabaseStartupResult> initialize() => _startup ??= _initialize();

  Future<SupabaseStartupResult> _initialize() async {
    final error = config.validationError;
    if (error != null) return SupabaseStartupResult.failure(error);
    try {
      _client = await (_initializer ?? _initializeSdk)(config);
      return const SupabaseStartupResult.ready();
    } catch (_) {
      // Ne jamais afficher ni journaliser une exception pouvant contenir une clé.
      return const SupabaseStartupResult.failure(
        'Impossible d’initialiser la connexion Supabase. '
        'Vérifiez la configuration et relancez l’application.',
      );
    }
  }

  Future<SupabaseClient> _initializeSdk(SupabaseConfig config) async {
    _sessionStorage = SecureSessionStorage(
      projectHost: Uri.parse(config.url).host,
    );
    final supabase = await Supabase.initialize(
      url: config.url,
      publishableKey: config.publicKey,
      debug: false,
      httpClient: PhotoDiagnosticHttpClient(http.Client()),
      authOptions: FlutterAuthClientOptions(
        autoRefreshToken: true,
        authFlowType: AuthFlowType.pkce,
        pkceAsyncStorage: SecurePkceStorage(
          projectHost: Uri.parse(config.url).host,
        ),
        detectSessionInUri: true,
        detectSessionInUriPredicate: KiboAuthCallback.accepts,
        persistSession: true,
        localStorage: _sessionStorage,
      ),
    );
    return supabase.client;
  }
}
