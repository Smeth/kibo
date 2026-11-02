import 'package:flutter/material.dart';
import '../auth/auth_controller.dart';
import '../profile/engagement_repository.dart';
import '../../core/widgets/kibo_form_layout.dart';
import 'safety_repository.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({
    super.key,
    required this.auth,
    required this.safety,
    required this.onReports,
    required this.onAccounts,
    this.accounts,
  });
  final AuthController auth;
  final SafetyRepository safety;
  final AccountEngagementRepository? accounts;
  final Future<void> Function() onReports, onAccounts;
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late final _owner = widget.auth.identity?.id;
  bool _invalid = false,
      _loading = false,
      _allowed = false,
      _canAccounts = false;
  String? _error;
  int _reports = 0, _requests = 0, _generation = 0;
  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_changed);
    _load();
  }

  bool get _current =>
      mounted && !_invalid && widget.auth.identity?.id == _owner;
  void _changed() {
    if (widget.auth.identity?.id != _owner) {
      _invalid = true;
      _generation++;
      _allowed = false;
      _reports = _requests = 0;
      if (mounted) setState(() {});
    }
  }

  Future<void> _load() async {
    if (!_current || _owner == null || _loading) return;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      _allowed = false;
    });
    try {
      final allowed = await widget.safety.canModerate(_owner);
      if (!_current || generation != _generation) return;
      if (allowed) {
        final reports = await widget.safety.reports(_owner, status: 'pending');
        if (!_current || generation != _generation) return;
        _reports = reports.length;
        final accounts = widget.accounts;
        _canAccounts = accounts != null && await accounts.canReview(_owner);
        if (!_current || generation != _generation) return;
        if (_canAccounts) {
          final queue = await accounts!.queue(_owner, 'pending');
          if (!_current || generation != _generation) return;
          _requests = queue.length;
        }
      }
      if (_current) setState(() => _allowed = allowed);
    } catch (_) {
      if (_current) {
        setState(
          () => _error =
              'Administration indisponible. Vérifiez votre connexion et actualisez.',
        );
      }
    } finally {
      if (_current && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _open(Future<void> Function() action) async {
    if (!_current || !_allowed || _loading) return;
    await action();
    if (_current) await _load();
  }

  @override
  void dispose() {
    widget.auth.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Administration'),
      actions: [
        IconButton(
          tooltip: 'Actualiser l’administration',
          onPressed: !_current || _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _invalid
        ? const Center(child: Text('Session modifiée. Revenez depuis Profil.'))
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                KiboFormColumn(
                  children: [
                    if (_loading) const LinearProgressIndicator(),
                    if (_error != null) ...[
                      Text(_error!),
                      OutlinedButton(
                        onPressed: _load,
                        child: const Text('Réessayer'),
                      ),
                    ],
                    if (!_loading && _error == null && !_allowed)
                      const Text(
                        'Accès administrateur requis. Reconnectez-vous après l’attribution du rôle.',
                      ),
                    if (_allowed) ...[
                      Text(
                        'Pilotage de KIBO',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Text(
                        'Publication immédiate, contrôle après publication. Chaque décision est motivée et journalisée.',
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: KiboFormColumn(
                            children: [
                              const Icon(Icons.policy_outlined, size: 32),
                              Text(
                                'Signalements à traiter : ${_reports >= 20 ? '20+' : _reports}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Text(
                                'Examiner les annonces et commentaires signalés, traiter les demandes et consulter le journal de chaque décision.',
                              ),
                              FilledButton.icon(
                                onPressed: () => _open(widget.onReports),
                                icon: const Icon(Icons.flag_outlined),
                                label: const Text('Ouvrir la modération'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_canAccounts)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: KiboFormColumn(
                              children: [
                                const Icon(
                                  Icons.manage_accounts_outlined,
                                  size: 32,
                                ),
                                Text(
                                  'Demandes de compte : ${_requests >= 20 ? '20+' : _requests}',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const Text(
                                  'Examiner les demandes en attente, demander des précisions, consigner une réponse et suivre leur traitement.',
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: () => _open(widget.onAccounts),
                                  icon: const Icon(Icons.fact_check_outlined),
                                  label: const Text(
                                    'Gérer les demandes de compte',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const Text(
                        'Les compteurs affichent la première page, avec 20+ si une suite est disponible.',
                      ),
                      const Divider(),
                      Text(
                        'Règles de traitement',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Text(
                        'Rejeter un signalement, le clôturer sans masque ou masquer son contenu. Le motif de masquage est communiqué à l’auteur. L’identité du signaleur reste protégée.',
                      ),
                      const Text(
                        'L’attribution des rôles, les suspensions globales et les suppressions définitives ne sont pas proposées dans cet espace MVP. Un suivi clôturé ne prouve pas une suppression de compte.',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
  );
}
