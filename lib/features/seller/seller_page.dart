import '../../core/widgets/kibo_app_bar.dart';
import 'package:flutter/material.dart';
import '../trust/official_badge.dart';
import '../trust/report_target_page.dart';
import '../trust/trust_scope.dart';
import '../auth/auth_controller.dart';
import 'seller_repository.dart';
import '../safety/trading_safety_notice.dart';
import '../../core/widgets/kibo_form_layout.dart';
import '../chat/chat_repository.dart';
import '../chat/open_seller_chat.dart';

class SellerPage extends StatefulWidget {
  const SellerPage({
    super.key,
    required this.sellerId,
    required this.listingId,
    required this.repository,
    required this.launcher,
    this.chats,
  });
  final String sellerId, listingId;
  final SellerRepository repository;
  final ContactLauncher launcher;
  final ChatRepository? chats;
  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {
  late Future<PublicSeller?> _profile = widget.repository.profile(
    widget.sellerId,
  );
  bool _busy = false;
  String? _message;
  int _session = 0;
  String? _owner;
  AuthController? _auth;
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
    final owner = _auth?.identity?.id;
    if (owner != _owner) {
      _owner = owner;
      _session++;
      _message = null;
      if (mounted) setState(() {});
    }
  }

  Future<void> _contact(bool whatsapp) async {
    if (_busy) return;
    if (_owner == null) {
      setState(
        () => _message =
            'Connectez-vous depuis Profil pour contacter ce vendeur.',
      );
      return;
    }
    final owner = _owner!, session = _session;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final contact = await widget.repository.contact(
        widget.listingId,
        expectedUserId: owner,
      );
      if (!mounted ||
          session != _session ||
          widget.repository.userId != owner) {
        return;
      }
      final number = whatsapp ? contact.whatsapp : contact.phone;
      if (number == null) {
        setState(
          () => _message = 'Ce vendeur n’a pas activé ce moyen de contact.',
        );
        return;
      }
      final opened = await widget.launcher.open(
        whatsapp ? whatsappUri(number) : callUri(number),
      );
      if (mounted && session == _session && !opened) {
        setState(
          () => _message =
              'Impossible d’ouvrir l’application. Vérifiez qu’une application compatible est installée.',
        );
      }
    } catch (_) {
      if (mounted && session == _session) {
        setState(
          () => _message =
              'Contact indisponible. Vérifiez votre connexion ou réessayez plus tard.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _auth?.removeListener(_sessionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: KiboAppBar(
      context,
      title: const Text('Profil du vendeur'),
      actions: [
        if (TrustScope.maybeClient(context) != null &&
            _owner != widget.sellerId)
          IconButton(
            tooltip: 'Signaler ce profil',
            icon: const Icon(Icons.flag_outlined),
            onPressed: () =>
                openTargetReport(context, 'profile', widget.sellerId),
          ),
      ],
    ),
    body: FutureBuilder<PublicSeller?>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Impossible de charger le vendeur.'),
                TextButton(
                  onPressed: () => setState(
                    () => _profile = widget.repository.profile(widget.sellerId),
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }
        final seller = snapshot.data;
        if (seller == null) {
          return const Center(child: Text('Ce profil n’est plus disponible.'));
        }
        return KiboFormListView(
          padding: const EdgeInsets.all(16),
          children: [
            OfficialBadge(userId: widget.sellerId),
            Text(seller.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(seller.city),
            const TradingSafetyNotice(),
            const SizedBox(height: 24),
            const Text(
              'Les moyens de contact sont choisis par le vendeur et réservés aux membres connectés.',
            ),
            const SizedBox(height: 12),
            if (widget.chats != null)
              FilledButton.icon(
                key: const ValueKey('seller-direct-message'),
                onPressed: _busy || _owner == widget.sellerId
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        try {
                          await openSellerChat(
                            context,
                            repository: widget.chats!,
                            listingId: widget.listingId,
                            sellerId: widget.sellerId,
                          );
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Message direct'),
              ),
            if (widget.chats != null && _owner == widget.sellerId)
              const Text(
                'Cette annonce vous appartient. Vous ne pouvez pas vous envoyer de message.',
              ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _contact(true),
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  'assets/branding/whatsapp.png',
                  width: 24,
                  height: 24,
                  excludeFromSemantics: true,
                ),
              ),
              label: const Text('Contacter sur WhatsApp'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _contact(false),
              icon: const Icon(Icons.phone_outlined),
              label: const Text('Appeler le vendeur'),
            ),
            if (_busy) const Center(child: CircularProgressIndicator()),
            if (_message != null)
              Semantics(liveRegion: true, child: Text(_message!)),
          ],
        );
      },
    ),
  );
}
