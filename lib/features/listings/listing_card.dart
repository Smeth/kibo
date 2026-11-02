import 'package:flutter/material.dart';
import '../../core/widgets/publication_age.dart';
import 'listing_models.dart';
import 'listing_photo_widgets.dart';
import '../favorites/favorite_button.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.imageHeight,
    required this.onOpen,
    this.compact = false,
    this.showCategory = true,
    this.uniform = false,
  });
  final PublicListing listing;
  final double imageHeight;
  final VoidCallback onOpen;
  final bool compact, showCategory;
  final bool uniform;
  Widget _uniformSummary(BuildContext context) {
    final theme = Theme.of(context);
    final title = theme.textTheme.titleSmall!.copyWith(
      fontWeight: FontWeight.w600,
    );
    final price = theme.textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.primary,
    );
    final meta = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    double lineHeight(TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: 'Ag', style: style),
        textScaler: MediaQuery.textScalerOf(context),
        textDirection: Directionality.of(context),
      )..layout();
      final height = painter.height;
      painter.dispose();
      return height;
    }

    Widget slot(String value, TextStyle style, int lines) => SizedBox(
      height: lineHeight(style) * lines,
      width: double.infinity,
      child: Text(
        value,
        style: style,
        maxLines: lines,
        overflow: TextOverflow.ellipsis,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        slot(listing.title, title, 2),
        const SizedBox(height: 4),
        slot(listing.priceLabel, price, 2),
        const SizedBox(height: 6),
        slot(listing.city, meta, 1),
        // Une ligne réservée même pour les anciennes annonces sans date.
        slot(
          publicationAgeLabel(listing.publishedAt, now: DateTime.now()) ?? '',
          meta,
          1,
        ),
      ],
    );
  }

  Widget _photo(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: listing.photoPaths.isNotEmpty
        ? ListingPhotoView(path: listing.photoPaths.first, label: listing.title)
        : Center(
            child: Icon(
              listing.type == 'service'
                  ? Icons.handyman_outlined
                  : Icons.inventory_2_outlined,
              size: compact ? 32 : 56,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .65),
            ),
          ),
  );
  Widget _summary(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showCategory && !compact) ...[
          Text(
            listing.categoryName ??
                (listing.type == 'service' ? 'Service' : 'Produit'),
            style: text.labelMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          listing.title,
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          listing.priceLabel,
          style: (compact ? text.titleSmall : text.titleMedium)?.copyWith(
            fontWeight: FontWeight.w800,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 16,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Wrap(
                spacing: 4,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    listing.city,
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (listing.publishedAt != null) ...[
                    Text('·', style: text.bodySmall),
                    PublicationAge(publishedAt: listing.publishedAt),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (listing.photosUnavailable)
          Text('Photos momentanément indisponibles.', style: text.bodySmall),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: !showCategory && listing.categoryName != null
        ? listing.categoryName
        : null,
    child: Card(
      key: ValueKey('listing-card-${listing.title}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: compact
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        key: ValueKey('listing-image-${listing.title}'),
                        width: 80,
                        height: 88,
                        child: _photo(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _summary(context)),
                    FavoriteButton(listingId: listing.id),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    key: ValueKey('listing-image-${listing.title}'),
                    height: imageHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(child: _photo(context)),
                        if (uniform && listing.photosUnavailable)
                          Positioned(
                            left: 8,
                            right: 8,
                            bottom: 8,
                            child: ColoredBox(
                              color: Theme.of(context).colorScheme.surface,
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Text(
                                  'Photos momentanément indisponibles.',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Material(
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: .96),
                            shape: const CircleBorder(),
                            child: FavoriteButton(listingId: listing.id),
                          ),
                        ),
                        if (listing.photoPaths.isNotEmpty)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surface.withValues(alpha: .96),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Text(
                                  '${listing.photoPaths.length} photo${listing.photoPaths.length > 1 ? 's' : ''}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: uniform
                        ? _uniformSummary(context)
                        : _summary(context),
                  ),
                ],
              ),
      ),
    ),
  );
}
