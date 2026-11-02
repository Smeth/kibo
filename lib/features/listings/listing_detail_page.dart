import 'package:flutter/material.dart';
import '../../core/widgets/publication_age.dart';
import '../../core/widgets/kibo_state_panel.dart';
import 'listing_models.dart';
import 'listing_repository.dart';
import 'listing_photo_widgets.dart';
import '../favorites/favorite_button.dart';
import '../auth/auth_controller.dart';
import '../comments/comments_repository.dart';
import '../comments/comments_page.dart';
import '../seller/seller_repository.dart';
import '../seller/seller_page.dart';
import '../chat/chat_repository.dart';
import '../chat/open_seller_chat.dart';
import '../safety/safety_repository.dart';
import '../safety/safety_page.dart';
import '../safety/trading_safety_notice.dart';

class ListingDetailPage extends StatefulWidget {
  const ListingDetailPage({
    super.key,
    required this.id,
    required this.repository,
    this.comments,
    this.sellers,
    this.contactLauncher,
    this.chats,
    this.safety,
  });
  final String id;
  final ListingRepository repository;
  final CommentsRepository? comments;
  final SellerRepository? sellers;
  final ContactLauncher? contactLauncher;
  final ChatRepository? chats;
  final SafetyRepository? safety;
  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  bool _openingChat = false;
  Future<PublicListing?> _read() {
    final future = Future<PublicListing?>.sync(
      () => widget.repository.detail(widget.id),
    );
    // Preserve the failed future for the UI, including failures before the next frame.
    future.ignore();
    return future;
  }

  late Future<PublicListing?> _future = _read();
  void _reload() => setState(() {
    _future = _read();
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Détail de l’annonce'),
      actions: [
        IconButton(
          tooltip: 'Actualiser',
          onPressed: _reload,
          icon: Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<PublicListing?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: SingleChildScrollView(
              child: KiboStatePanel(
                title: listingReadError(snapshot.error!, detail: true),
                icon: Icons.wifi_off_outlined,
                actionLabel: 'Réessayer',
                onAction: _reload,
              ),
            ),
          );
        }
        final listing = snapshot.data;
        if (listing == null) {
          return const Center(
            child: SingleChildScrollView(
              child: KiboStatePanel(
                title: 'Cette annonce n’est plus disponible.',
                message:
                    'Revenez au catalogue pour découvrir les autres annonces.',
                icon: Icons.inventory_2_outlined,
              ),
            ),
          );
        }
        final text = Theme.of(context).textTheme;
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (listing.photoPaths.isNotEmpty)
                          Stack(
                            children: [
                              ListingPhotoGallery(
                                key: ValueKey('listing-gallery-${listing.id}'),
                                paths: listing.photoPaths,
                                title: listing.title,
                                immersive: true,
                              ),
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Material(
                                  color: Theme.of(context).colorScheme.surface,
                                  shape: const CircleBorder(),
                                  child: FavoriteButton(listingId: listing.id),
                                ),
                              ),
                            ],
                          ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (listing.photosUnavailable)
                                  const Text(
                                    'Photos momentanément indisponibles.',
                                  ),
                                if (listing.categoryName != null) ...[
                                  Text(
                                    listing.categoryName!,
                                    style: text.labelLarge?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Semantics(
                                  header: true,
                                  child: Text(
                                    listing.title,
                                    style: text.headlineSmall,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        listing.priceLabel,
                                        style: text.headlineSmall?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    if (listing.photoPaths.isEmpty)
                                      FavoriteButton(listingId: listing.id),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 20,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        listing.location,
                                        style: text.bodyMedium?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 18,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: PublicationAge(
                                        publishedAt: listing.publishedAt,
                                        detailed: true,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    'Description',
                                    style: text.titleMedium,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(listing.description),

                                if (widget.comments != null) ...[
                                  const SizedBox(height: 24),
                                  OutlinedButton.icon(
                                    icon: Icon(Icons.forum_outlined),
                                    label: const Text(
                                      'Commentaires et réponses',
                                    ),
                                    onPressed: () async {
                                      final auth = AuthScope.maybeOf(context);
                                      await Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) {
                                            Widget page = CommentsPage(
                                              safety: widget.safety,
                                              listingId: widget.id,
                                              repository: widget.comments!,
                                            );
                                            return auth == null
                                                ? page
                                                : AuthScope(
                                                    controller: auth,
                                                    child: page,
                                                  );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ],
                                const TradingSafetyNotice(),
                                const SizedBox(height: 24),
                                if (widget.safety != null)
                                  TextButton.icon(
                                    onPressed: () => openReportForm(
                                      context,
                                      widget.safety!,
                                      listingId: listing.id,
                                    ),
                                    icon: Icon(Icons.flag_outlined),
                                    label: const Text('Signaler cette annonce'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if ((widget.chats != null &&
                    listing.sellerId != null &&
                    listing.sellerId !=
                        AuthScope.maybeOf(context)?.identity?.id) ||
                (listing.sellerId != null &&
                    widget.sellers != null &&
                    widget.contactLauncher != null))
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: _contactActions(listing),
                ),
              ),
          ],
        );
      },
    ),
  );
  Widget _contactActions(PublicListing listing) {
    final actions = <Widget>[
      if (widget.chats != null &&
          listing.sellerId != null &&
          listing.sellerId != AuthScope.maybeOf(context)?.identity?.id) ...[
        FilledButton.icon(
          icon: Icon(Icons.chat_bubble_outline),
          label: const Tooltip(
            message: 'Écrire au vendeur',
            child: Text('Message'),
          ),
          onPressed: _openingChat
              ? null
              : () async {
                  setState(() => _openingChat = true);
                  try {
                    await openSellerChat(
                      context,
                      repository: widget.chats!,
                      listingId: listing.id,
                      sellerId: listing.sellerId!,
                    );
                  } finally {
                    if (mounted) setState(() => _openingChat = false);
                  }
                },
        ),
      ],
      if (listing.sellerId != null &&
          widget.sellers != null &&
          widget.contactLauncher != null) ...[
        OutlinedButton.icon(
          icon: Icon(Icons.storefront_outlined),
          label: const Tooltip(
            message: 'Voir le vendeur et le contacter',
            child: Text('Contacter'),
          ),
          onPressed: () {
            final auth = AuthScope.maybeOf(context);
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) {
                  Widget page = SellerPage(
                    sellerId: listing.sellerId!,
                    listingId: listing.id,
                    repository: widget.sellers!,
                    launcher: widget.contactLauncher!,
                    chats: widget.chats,
                  );
                  return auth == null
                      ? page
                      : AuthScope(controller: auth, child: page);
                },
              ),
            );
          },
        ),
      ],
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 320 &&
                MediaQuery.textScalerOf(context).scale(14) <= 18) {
              return Row(
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: actions[i]),
                  ],
                ],
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  actions[i],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
