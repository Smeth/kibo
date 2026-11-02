import 'package:flutter/material.dart';
import 'listing_models.dart';
import 'listing_repository.dart';

/// Catégories réelles du repository public, jamais une liste de maquette figée.
class CategoryShortcuts extends StatefulWidget {
  const CategoryShortcuts({
    super.key,
    required this.repository,
    required this.onSelected,
  });
  final ListingRepository repository;
  final ValueChanged<ListingCategory?> onSelected;
  @override
  State<CategoryShortcuts> createState() => _CategoryShortcutsState();
}

class _CategoryShortcutsState extends State<CategoryShortcuts> {
  (String, IconData) _style(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('informatique') || lower.contains('téléphone')) {
      return ('Tech', Icons.devices_outlined);
    }
    if (lower.contains('véhicule') || lower.contains('moto')) {
      return ('Véhicules', Icons.directions_car_outlined);
    }
    if (lower.contains('immobilier')) {
      return ('Immobilier', Icons.apartment_outlined);
    }
    if (lower.contains('maison')) return ('Maison', Icons.chair_outlined);
    if (lower.contains('mode')) return ('Mode', Icons.checkroom_outlined);
    if (lower.contains('service')) return ('Services', Icons.handyman_outlined);
    if (lower.contains('alimentation')) {
      return ('Alimentation', Icons.restaurant_outlined);
    }
    if (lower.contains('emploi')) return ('Emploi', Icons.school_outlined);
    if (lower.contains('loisir')) {
      return ('Loisirs', Icons.sports_esports_outlined);
    }
    return (name, Icons.category_outlined);
  }

  Widget _tile(BuildContext context, String name, ListingCategory? category) {
    final (label, icon) = category == null
        ? ('Tout', Icons.grid_view_rounded)
        : _style(name);
    final selected = category == null;
    final colors = Theme.of(context).colorScheme;
    final width =
        (label.runes.length *
                    7 *
                    MediaQuery.textScalerOf(context).scale(12) /
                    12 +
                24)
            .clamp(80.0, 220.0)
            .toDouble();
    return Tooltip(
      message: name,
      child: Semantics(
        selected: selected,
        button: true,
        child: SizedBox(
          width: width,
          child: Material(
            color: selected ? colors.primary : colors.surface,
            elevation: selected ? 1 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: selected ? colors.primary : colors.outlineVariant,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => widget.onSelected(category),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 24,
                      color: selected ? colors.onPrimary : colors.onSurface,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected ? colors.onPrimary : colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  late Future<List<ListingCategory>> _categories;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CategoryShortcuts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) _load();
  }

  void _load() {
    _categories = Future.sync(widget.repository.categories);
    _categories.ignore();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ListingCategory>>(
    future: _categories,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextButton.icon(
            onPressed: () => setState(_load),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer les catégories'),
          ),
        );
      }
      const order = [
        'Tech',
        'Mode',
        'Maison',
        'Véhicules',
        'Immobilier',
        'Services',
        'Alimentation',
        'Emploi',
        'Loisirs',
      ];
      int rank(ListingCategory category) {
        final value = order.indexOf(_style(category.name).$1);
        return value < 0 ? 999 : value;
      }

      final categories = [...?snapshot.data]
        ..sort((a, b) {
          final comparison = rank(a).compareTo(rank(b));
          return comparison == 0 ? a.name.compareTo(b.name) : comparison;
        });
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            spacing: 8,
            children: [
              _tile(context, 'Toutes les catégories', null),
              for (final category in categories)
                _tile(context, category.name, category),
            ],
          ),
        ),
      );
    },
  );
}
