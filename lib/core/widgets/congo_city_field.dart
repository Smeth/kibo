import 'kibo_modal.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'kibo_search_field_theme.dart';

String citySearchKey(String value) {
  const accents = 'àáâãäåèéêëìíîïòóôõöùúûüçñ';
  const plain = 'aaaaaaeeeeiiiiooooouuuucn';
  var normalized = value.toLowerCase().trim();
  for (var i = 0; i < accents.length; i++) {
    normalized = normalized.replaceAll(accents[i], plain[i]);
  }
  return normalized.replaceAll(RegExp(r"[\s’'\-]+"), '');
}

class CongoPlace {
  CongoPlace(this.name, List<String> aliases)
    : search = citySearchKey([name, ...aliases].join(' '));
  final String name, search;
}

abstract final class CongoPlaces {
  static List<CongoPlace>? _loaded;
  static Future<List<CongoPlace>>? _cache;
  static Future<List<CongoPlace>> load() => _loaded != null
      ? SynchronousFuture(_loaded!)
      : _cache ??= _read()
            .then((rows) {
              _loaded = rows;
              return rows;
            })
            .catchError((Object error) {
              _cache = null;
              throw error;
            });
  static Future<List<CongoPlace>> _read() async {
    final data =
        jsonDecode(await rootBundle.loadString('assets/data/congo_places.json'))
            as Map<String, dynamic>;
    if (data['country'] != 'CG') {
      throw const FormatException('Catalogue hors Congo-Brazzaville');
    }
    final places = (data['places'] as List)
        .map(
          (row) => CongoPlace(
            row['name'] as String,
            List<String>.from(row['aliases'] as List),
          ),
        )
        .toList();
    const popular = [
      'Brazzaville',
      'Pointe-Noire',
      'Dolisie',
      'Nkayi',
      'Ouesso',
      'Owando',
      'Oyo',
      'Impfondo',
      'Sibiti',
      'Madingou',
      'Kinkala',
      'Djambala',
      'Ewo',
      'Gamboma',
      'Mossendjo',
    ];
    places.sort((a, b) {
      final x = popular.indexOf(a.name), y = popular.indexOf(b.name);
      if (x >= 0 || y >= 0) return (x < 0 ? 999 : x).compareTo(y < 0 ? 999 : y);
      return citySearchKey(a.name).compareTo(citySearchKey(b.name));
    });
    return List.unmodifiable(places);
  }
}

Future<String?> pickCongoCity(
  BuildContext context, {
  String? current,
  bool allowAll = false,
}) => showKiboModalSheet<String>(
  context: context,
  builder: (_) => _CityPicker(current: current, allowAll: allowAll),
);

class CongoCityField extends StatelessWidget {
  const CongoCityField({
    super.key,
    this.fieldKey,
    required this.controller,
    this.enabled = true,
    this.allowAll = false,
    this.selectionOnly = false,
    this.validator,
    this.scrollController,
    this.onFieldSubmitted,
    this.textInputAction = TextInputAction.next,
  });
  final Key? fieldKey;
  final TextEditingController controller;
  final bool enabled, allowAll;
  final bool selectionOnly;
  Future<void> _pick(BuildContext context) async {
    final city = await pickCongoCity(
      context,
      current: controller.text,
      allowAll: allowAll,
    );
    if (city != null && context.mounted) controller.text = city;
  }

  final FormFieldValidator<String>? validator;
  final ScrollController? scrollController;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction textInputAction;
  @override
  Widget build(BuildContext context) => TextFormField(
    key: fieldKey,
    controller: controller,
    enabled: enabled,
    readOnly: selectionOnly,
    onTap: enabled && selectionOnly ? () => _pick(context) : null,
    validator: validator,
    scrollController: scrollController,
    textInputAction: textInputAction,
    onFieldSubmitted: onFieldSubmitted,
    maxLength: 120,
    decoration: InputDecoration(
      labelText: 'Ville',
      counterText: '',
      hintText: allowAll ? 'Toutes les villes' : 'Choisir une ville',
      prefixIcon: const Icon(Icons.location_on_outlined),
      suffixIcon: IconButton(
        tooltip: 'Choisir une ville du Congo',
        onPressed: !enabled ? null : () => _pick(context),
        icon: const Icon(Icons.expand_more),
      ),
    ),
  );
}

class _CityPicker extends StatefulWidget {
  const _CityPicker({this.current, required this.allowAll});
  final String? current;
  final bool allowAll;
  @override
  State<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<_CityPicker> {
  late Future<List<CongoPlace>> _places = CongoPlaces.load();
  String _query = '';
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height:
        (MediaQuery.sizeOf(context).height -
            MediaQuery.viewInsetsOf(context).bottom) *
        .88,
    child: FutureBuilder<List<CongoPlace>>(
      future: _places,
      builder: (context, snapshot) {
        final rows = (snapshot.data ?? <CongoPlace>[])
            .where((place) => _query.isEmpty || place.search.contains(_query))
            .toList();
        return CustomScrollView(
          key: const ValueKey('congo-city-options'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Villes du Congo',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Source des villes',
                      onPressed: () => showLicensePage(
                        context: context,
                        applicationName: 'KIBO',
                      ),
                      icon: const Icon(Icons.info_outline),
                    ),
                    IconButton(
                      tooltip: 'Fermer les villes',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: KiboSearchFieldTheme(
                  child: SearchBar(
                    controller: _search,
                    hintText: 'Rechercher une ville ou une localité',
                    leading: const Icon(Icons.search),
                    onChanged: (value) =>
                        setState(() => _query = citySearchKey(value)),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            if (snapshot.hasError)
              SliverToBoxAdapter(
                child: Center(
                  child: TextButton(
                    onPressed: () =>
                        setState(() => _places = CongoPlaces.load()),
                    child: const Text('Réessayer la liste des villes'),
                  ),
                ),
              )
            else if (!snapshot.hasData)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else ...[
              if (widget.allowAll)
                SliverToBoxAdapter(
                  child: ListTile(
                    title: const Text('Toutes les villes'),
                    leading: const Icon(Icons.public),
                    onTap: () => Navigator.pop(context, ''),
                  ),
                ),
              if (rows.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Aucune ville ou localité du Congo-Brazzaville trouvée.',
                    ),
                  ),
                ),
              SliverList.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final name = rows[index].name;
                  final selected =
                      citySearchKey(name) ==
                      citySearchKey(widget.current ?? '');
                  return ListTile(
                    title: Text(name),
                    selected: selected,
                    trailing: selected ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.pop(context, name),
                  );
                },
              ),
            ],
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Villes et localités · GeoNames · CC BY 4.0'),
              ),
            ),
          ],
        );
      },
    ),
  );
}
