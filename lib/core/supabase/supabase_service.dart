import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

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
    : _initializer = initializer ?? _initializeSdk;

  final SupabaseConfig config;
  final SupabaseInitializer _initializer;
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
      _client = await _initializer(config);
      return const SupabaseStartupResult.ready();
    } catch (_) {
      // Ne jamais afficher ni journaliser une exception pouvant contenir une clé.
      return const SupabaseStartupResult.failure(
        'Impossible d’initialiser la connexion Supabase. '
        'Vérifiez la configuration et relancez l’application.',
      );
    }
  }

  static Future<SupabaseClient> _initializeSdk(SupabaseConfig config) async {
    final supabase = await Supabase.initialize(
      url: config.url,
      publishableKey: config.publicKey,
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        persistSession: false,
      ),
    );
    return supabase.client;
  }
}
