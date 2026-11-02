import '../../core/widgets/kibo_app_bar.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/kibo_form_layout.dart';
import '../auth/auth_controller.dart';
import 'seller_repository.dart';

class ContactPreferencesPage extends StatefulWidget {
  const ContactPreferencesPage({
    super.key,
    required this.ownerId,
    required this.repository,
  });
  final String ownerId;
  final SellerRepository repository;
  @override
  State<ContactPreferencesPage> createState() => _ContactPreferencesPageState();
}

class _ContactPreferencesPageState extends State<ContactPreferencesPage> {
  final _phone = TextEditingController(), _whatsapp = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _loading = true,
      _saving = false,
      _invalidated = false,
      _calls = false,
      _whatsappEnabled = false,
      _loaded = false;
  String? _updatedAt, _error;
  AuthController? _auth;
  bool get _current =>
      mounted && !_invalidated && widget.repository.userId == widget.ownerId;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.maybeOf(context);
    if (!identical(auth, _auth)) {
      _auth?.removeListener(_sessionChanged);
      _auth = auth;
      _auth?.addListener(_sessionChanged);
    }
    _sessionChanged();
  }

  void _sessionChanged() {
    if (!_invalidated && _auth?.identity?.id != widget.ownerId) {
      _invalidated = true;
      _phone.clear();
      _whatsapp.clear();
      if (mounted) setState(() {});
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loaded = false;
      _error = null;
    });
    try {
      final prefs = await widget.repository.preferences(widget.ownerId);
      if (!_current) return;
      setState(() {
        _phone.text = prefs.phone;
        _whatsapp.text = prefs.whatsapp;
        _calls = prefs.callsEnabled;
        _whatsappEnabled = prefs.whatsappEnabled;
        _updatedAt = prefs.updatedAt;
        _loaded = true;
      });
    } catch (_) {
      if (_current) {
        setState(
          () => _error =
              'Impossible de charger vos coordonnées. Réessayez plus tard.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving ||
        !_loaded ||
        !_current ||
        !(_form.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.save(
        ContactPreferences(
          phone: _phone.text,
          whatsapp: _whatsapp.text,
          callsEnabled: _calls,
          whatsappEnabled: _whatsappEnabled,
          updatedAt: _updatedAt,
        ),
        expectedUserId: widget.ownerId,
      );
      if (mounted && _current) Navigator.of(context).pop(true);
    } catch (_) {
      if (_current) {
        setState(
          () => _error =
              'Enregistrement non confirmé. Vos saisies sont conservées. Actualisez vos coordonnées avant de réessayer.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _auth?.removeListener(_sessionChanged);
    _phone.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: KiboAppBar(
        context,
        title: const Text('Mes coordonnées de contact'),
      ),
      body: !_current
          ? const Center(
              child: Text(
                'Votre session a changé. Fermez ce formulaire pour continuer.',
              ),
            )
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Choisissez comment les membres connectés peuvent vous contacter depuis vos annonces publiées. Chaque moyen de contact est désactivé par défaut.',
                ),
                const SizedBox(height: 16),
                Form(
                  key: _form,
                  child: KiboFormColumn(
                    children: [
                      TextFormField(
                        key: const ValueKey('contact-phone'),
                        controller: _phone,
                        enabled: !_saving,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone au format international',
                          hintText: '+242…',
                        ),
                        validator: (value) =>
                            validateContactNumber(value ?? '', enabled: _calls),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Autoriser les appels des membres connectés',
                        ),
                        value: _calls,
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _calls = value),
                      ),
                      TextFormField(
                        key: const ValueKey('contact-whatsapp'),
                        controller: _whatsapp,
                        enabled: !_saving,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Numéro WhatsApp au format international',
                          hintText: '+242…',
                        ),
                        validator: (value) => validateContactNumber(
                          value ?? '',
                          enabled: _whatsappEnabled,
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Autoriser les contacts WhatsApp des membres connectés',
                        ),
                        value: _whatsappEnabled,
                        onChanged: _saving
                            ? null
                            : (value) =>
                                  setState(() => _whatsappEnabled = value),
                      ),
                      const Text(
                        'Ces coordonnées ne changent pas vos identifiants de connexion. Leur activation permet aux membres de voir le numéro dans l’application de contact ouverte.',
                      ),
                      const SizedBox(height: 16),
                      if (_error != null)
                        Semantics(liveRegion: true, child: Text(_error!)),
                      FilledButton(
                        onPressed: _saving || !_loaded ? null : _save,
                        child: Text(
                          _saving
                              ? 'Enregistrement…'
                              : 'Enregistrer mes préférences',
                        ),
                      ),
                      TextButton(
                        onPressed: _saving ? null : _load,
                        child: const Text('Actualiser les coordonnées'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    ),
  );
}
