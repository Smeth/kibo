import 'package:flutter/material.dart';
import '../listings/listing_repository.dart';
import '../listings/listing_card.dart';
import '../listings/listing_detail_page.dart';
import '../listings/listing_photo_widgets.dart';
import 'favorites_controller.dart';
import '../comments/comments_repository.dart';
import '../auth/auth_controller.dart';
import '../seller/seller_repository.dart';
import '../chat/chat_repository.dart';
import '../safety/safety_repository.dart';
import '../../core/widgets/kibo_state_panel.dart';
import '../../core/widgets/kibo_form_layout.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({
    super.key,
    required this.listings,
    this.comments,
    this.sellers,
    this.contactLauncher,
    this.chats,
    this.safety,
  });
  final ListingRepository listings;
  final CommentsRepository? comments;
  final SellerRepository? sellers;
  final ContactLauncher? contactLauncher;
  final ChatRepository? chats;
  final SafetyRepository? safety;
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final controller = FavoritesScope.maybeOf(context);
        if (controller?.owner == null) {
          controller?.guest?.refresh();
        } else {
          controller?.refresh();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = FavoritesScope.maybeOf(context);
    final guest = controller?.owner == null ? controller?.guest : null;
    if (controller == null || (controller.owner == null && guest == null)) {
      return const Center(
        child: Text('Connectez-vous depuis Profil pour retrouver vos favoris.'),
      );
    }
    final items = guest?.items ?? controller.items;
    final error = guest?.error ?? controller.error;
    final busy = guest?.busy ?? controller.busy;
    Future<void> refresh() =>
        guest != null ? guest.refresh() : controller.refresh();
    return RefreshIndicator(
      onRefresh: () async {
        if (!busy) await refresh();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        key: const PageStorageKey('favorites-list'),
        padding: const EdgeInsets.all(16),
        itemCount: items.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: KiboFormColumn(
                children: [
                  if (controller.loading || guest?.loading == true)
                    const LinearProgressIndicator(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          guest == null
                              ? 'Mes favoris'
                              : 'Favoris sur ce téléphone',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Actualiser les favoris',
                        onPressed: busy ? null : refresh,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  if (guest != null)
                    const Text(
                      'Enregistrés sur cet appareil. Connectez-vous depuis Profil pour les transférer vers votre compte.',
                    ),
                  if (controller.offersTransfer)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: KiboFormColumn(
                          children: [
                            Text(
                              '${controller.guest!.ids.length} favori(s) de ce téléphone peuvent être ajoutés à votre compte.',
                            ),
                            FilledButton(
                              onPressed:
                                  controller.busy || controller.guest!.busy
                                  ? null
                                  : () async {
                                      final owner = controller.owner!;
                                      final revision =
                                          controller.sessionRevision;
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                            'Ajouter au compte connecté ?',
                                          ),
                                          content: const Text(
                                            'Les favoris de ce téléphone seront ajoutés à ce compte sans remplacer ses favoris existants. Seuls les éléments confirmés seront retirés de la sélection locale.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Annuler'),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text(
                                                'Confirmer le transfert',
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        await controller.importGuestFavorites(
                                          expectedOwner: owner,
                                          expectedRevision: revision,
                                        );
                                      }
                                    },
                              child: Text(
                                controller.importing
                                    ? 'Transfert…'
                                    : 'Ajouter à mon compte',
                              ),
                            ),
                            TextButton(
                              onPressed: controller.busy
                                  ? null
                                  : controller.dismissTransfer,
                              child: const Text('Plus tard'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (error != null) ...[
                    Text(error),
                    TextButton(
                      onPressed: busy ? null : refresh,
                      child: const Text('Réessayer'),
                    ),
                  ],
                  if (items.isEmpty && error == null)
                    const KiboStatePanel(
                      icon: Icons.favorite_border,
                      title:
                          'Aucun favori disponible. Les annonces retirées du public ne sont pas affichées.',
                      message:
                          'Touchez le cœur d’une annonce pour la retrouver ici.',
                    ),
                ],
              ),
            );
          }
          if (index <= items.length) {
            final listing = items[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ListingCard(
                compact: true,
                listing: listing,
                imageHeight: 160,
                onOpen: () async {
                  final auth = AuthScope.maybeOf(context);
                  final photos = ListingPhotoScope.maybeOf(context);
                  Widget detail = ListingDetailPage(
                    id: listing.id,
                    repository: widget.listings,
                    comments: widget.comments,
                    sellers: widget.sellers,
                    chats: widget.chats,
                    safety: widget.safety,
                    contactLauncher: widget.contactLauncher,
                  );
                  if (photos != null) {
                    detail = ListingPhotoScope(
                      repository: photos.repository,
                      picker: photos.picker,
                      child: detail,
                    );
                  }
                  if (auth != null) {
                    detail = AuthScope(controller: auth, child: detail);
                  }
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          FavoritesScope(controller: controller, child: detail),
                    ),
                  );
                  if (mounted) await refresh();
                },
              ),
            );
          }
          return (guest?.hasMore ?? controller.hasMore)
              ? TextButton(
                  onPressed: busy
                      ? null
                      : guest != null
                      ? () => guest.refresh(append: true)
                      : controller.loadMore,
                  child: Text(
                    controller.moreLoading ? 'Chargement…' : 'Voir plus',
                  ),
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }
}
