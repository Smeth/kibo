// Lanceur ponctuel : uniquement après autorisation du lot et compte dédié choisi.
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kibo/core/config/supabase_config.dart';
import 'package:kibo/core/supabase/supabase_service.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/features/development/test_catalogue_importer.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/auth/auth_repository.dart';
import 'package:kibo/features/auth/auth_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _SeedApp());
}

class _SeedApp extends StatefulWidget {
  const _SeedApp();
  @override
  State<_SeedApp> createState() => _SeedAppState();
}

class _SeedAppState extends State<_SeedApp> {
  final _service = SupabaseService(
    config: const SupabaseConfig.fromEnvironment(),
  );
  String _status = 'Vérification du compte dédié et des 108 images…';
  // Uniquement après contrôle opérateur des IDs et objets du préfixe distant.
  static const _verifiedPrefix = int.fromEnvironment(
    'KIBO_SEED_VERIFIED_PREFIX',
  );
  int _done = _verifiedPrefix;
  static const _total = int.fromEnvironment(
    'KIBO_SEED_COUNT',
    defaultValue: 108,
  );
  static const _batch = String.fromEnvironment(
    'KIBO_SEED_BATCH',
    defaultValue: testCatalogueBatch,
  );
  AuthController? _auth;
  bool _importing = false, _waitingLogin = false;
  String? _failureType;
  Future<void> _statusWrite = Future<void>.value();
  Future<void> _record(String phase) {
    final done = _done;
    return _statusWrite = _statusWrite
        .then((_) async {
          final directory = await getApplicationSupportDirectory();
          await File(
            '${directory.path}/kibo-test-import-status.json',
          ).writeAsString(
            jsonEncode({
              'batch': _batch,
              'phase': phase,
              'done': done,
              if (_failureType != null) 'failure_type': _failureType,
            }),
            flush: true,
          );
        })
        .catchError((Object _) {});
  }

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await _record('starting');
    try {
      const owner = String.fromEnvironment('KIBO_SEED_OWNER_ID');
      const project = String.fromEnvironment('KIBO_SEED_PROJECT_REF');
      final config = const SupabaseConfig.fromEnvironment();
      if (owner.isEmpty ||
          project.isEmpty ||
          Uri.parse(config.url).host != '$project.supabase.co') {
        throw StateError('Cible de test non configurée');
      }
      final startup = await _service.initialize();
      if (!startup.isReady) throw StateError('Connexion indisponible');
      _auth = AuthController(SupabaseAuthRepository(_service.client));
      _auth!.addListener(_sessionChanged);
      _sessionChanged();
      if (!_importing) {
        _waitingLogin = true;
        await _record('awaiting_login');
        if (mounted) {
          setState(
            () => _status =
                'Connectez le compte vendeur de test ci-dessous. La restauration de session reste également écoutée.',
          );
        }
      }
    } catch (error) {
      await _failed(error);
    }
  }

  void _sessionChanged() {
    const owner = String.fromEnvironment('KIBO_SEED_OWNER_ID');
    if (!_importing && _auth?.identity?.id == owner) {
      _importing = true;
      _waitingLogin = false;
      unawaited(_import());
    }
  }

  Future<void> _import() async {
    try {
      const owner = String.fromEnvironment('KIBO_SEED_OWNER_ID');
      final gateway = SupabaseTestCatalogueGateway(_service.client, owner);
      await _record('preparing');
      if (mounted) {
        setState(
          () => _status =
              'Compte vendeur confirmé. Validation des images et import en cours…',
        );
      }
      final rows = parseTestCatalogue(
        await rootBundle.loadString(
          const String.fromEnvironment(
            'KIBO_SEED_ASSET',
            defaultValue: 'assets/test_catalogue/catalogue.json',
          ),
        ),
      );
      if (rows.length != _total ||
          _verifiedPrefix < 0 ||
          _verifiedPrefix >= _total ||
          !(rows.first['description'] as String).contains(_batch)) {
        throw StateError('Lot cible inattendu');
      }
      await TestCatalogueImporter(
        gateway: gateway,
        owner: owner,
        parallelism: const int.fromEnvironment(
          'KIBO_SEED_PARALLELISM',
          defaultValue: 1,
        ),
      ).run(
        rows.skip(_verifiedPrefix).toList(),
        onProgress: (done, total) {
          if (mounted) {
            setState(() {
              _done = _verifiedPrefix + done;
              _status = '$_done / $_total annonces avec photo confirmées';
            });
          }
          _record('running');
        },
      );
      await _record('done');
      if (mounted) {
        setState(
          () => _status =
              '$_total annonces et leurs photos sont importées. Les commentaires sont ajoutés séparément.',
        );
      }
    } catch (error) {
      await _failed(error);
    }
  }

  Future<void> _failed(Object error) async {
    _failureType = error.runtimeType.toString();
    await _record('failed');
    // Aucune URL signée, clé, identité ou exception brute dans la console.
    if (mounted) {
      setState(
        () => _status =
            'Import interrompu après $_done annonces confirmées. Les données existantes sont conservées ; une relance reprendra les mêmes identifiants.',
      );
    }
  }

  Future<void> _login(BuildContext context) async {
    final auth = _auth;
    if (auth == null || _importing) return;
    if (auth.identity != null) await auth.signOut();
    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => AuthPage(controller: auth)),
      );
    }
  }

  @override
  void dispose() {
    _auth?.removeListener(_sessionChanged);
    _auth?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: KiboTheme.light,
    home: Scaffold(
      appBar: AppBar(title: const Text('Import du jeu de test KIBO')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '$_total annonces fictives · base connectée · aucun rôle administrateur attribué',
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(value: _done / _total),
            const SizedBox(height: 24),
            Text(_status),
            if (_waitingLogin) ...[
              const SizedBox(height: 16),
              const Text(
                String.fromEnvironment(
                  'KIBO_SEED_OWNER_LABEL',
                  defaultValue: 'Compte vendeur dédié',
                ),
              ),
              Builder(
                builder: (innerContext) => FilledButton(
                  onPressed: () => _login(innerContext),
                  child: const Text('Connexion au compte vendeur de test'),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
