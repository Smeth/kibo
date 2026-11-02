import 'package:flutter/material.dart';
import 'favorites_controller.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.listingId});
  final String listingId;
  @override
  Widget build(BuildContext context) {
    final controller = FavoritesScope.maybeOf(context);
    final guest = controller?.owner == null ? controller?.guest : null;
    final selected =
        guest?.ids.contains(listingId) ??
        controller?.ids.contains(listingId) ??
        false;
    return Semantics(
      toggled: selected,
      child: IconButton(
        tooltip: selected ? 'Retirer des favoris' : 'Ajouter aux favoris',
        isSelected: selected,
        icon: Icon(selected ? Icons.favorite : Icons.favorite_border),
        onPressed: controller?.busy == true || guest?.busy == true
            ? null
            : () async {
                final messenger = ScaffoldMessenger.of(context);
                if (guest != null) {
                  if (!guest.ready) {
                    await guest.initialize();
                  }
                  if (guest.ready) await guest.toggle(listingId);
                  if (context.mounted && guest.error != null) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(guest.error!)),
                    );
                  }
                  return;
                }
                if (controller?.owner == null) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Connectez-vous depuis Profil pour gérer vos favoris.',
                      ),
                    ),
                  );
                  return;
                }
                if (!controller!.loaded) {
                  await controller.refresh();
                } else {
                  await controller.toggle(listingId);
                }
                if (context.mounted && controller.error != null) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(controller.error!)),
                  );
                }
              },
      ),
    );
  }
}
