import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../../core/widgets/congo_city_field.dart';
import '../../core/widgets/kibo_search_field_theme.dart';
import '../../core/widgets/kibo_form_layout.dart';
import 'listing_models.dart';
import 'listing_query.dart';
import 'listing_repository.dart';

class CatalogueSearchForm extends StatefulWidget {
  const CatalogueSearchForm({
    super.key,
    required this.repository,
    required this.onApply,
    this.initialQuery = const ListingQuery(),
  });
  final ListingRepository repository;
  final ValueChanged<ListingQuery> onApply;
  final ListingQuery initialQuery;
  @override
  State<CatalogueSearchForm> createState() => _CatalogueSearchFormState();
}

class _CatalogueSearchFormState extends State<CatalogueSearchForm> {
  Timer? _typing;
  List<SearchSuggestion> _suggestions = [];
  int _suggestionRequest = 0;
  final _filters = ExpansibleController();
  final _text = TextEditingController(),
      _city = TextEditingController(),
      _min = TextEditingController(),
      _max = TextEditingController();
  List<ListingCategory> _categories = [];
  String? _category, _error, _categoryError;
  bool _loading = true;
  ListingSort _sort = ListingSort.relevance;
  ListingQuery _active = const ListingQuery();
  final _cityScroll = ScrollController(keepScrollOffset: false),
      _minScroll = ScrollController(keepScrollOffset: false),
      _maxScroll = ScrollController(keepScrollOffset: false);
  @override
  void initState() {
    super.initState();
    _restore(widget.initialQuery);
    _loadCategories();
  }

  void _restore(ListingQuery query) {
    // La recherche progressive conserve le curseur et la composition clavier.
    if (_text.text.trim() != query.text) _text.text = query.text;
    _city.text = query.city;
    _min.text = query.minPrice;
    _max.text = query.maxPrice;
    _category = query.categoryId;
    _sort = query.sort;
    _active = query;
  }

  @override
  void didUpdateWidget(CatalogueSearchForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.initialQuery, widget.initialQuery)) {
      _restore(widget.initialQuery);
    }
  }

  Widget _chip(String label, VoidCallback clear) => InputChip(
    label: Text(label),
    onDeleted: () {
      clear();
      _apply();
    },
  );

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _categoryError = null;
    });
    try {
      final categories = await widget.repository.categories();
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _categoryError = 'Catégories indisponibles.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _suggestionRequest++;
    _typing?.cancel();
    _filters.dispose();
    for (final scroll in [_cityScroll, _minScroll, _maxScroll]) {
      scroll.dispose();
    }
    for (final field in [_text, _city, _min, _max]) {
      field.dispose();
    }
    super.dispose();
  }

  void _apply({bool dismissKeyboard = true}) {
    _typing?.cancel();
    final query = ListingQuery(
      text: _text.text.trim(),
      city: _city.text.trim(),
      categoryId: _category,
      minPrice: _min.text.trim(),
      maxPrice: _max.text.trim(),
      sort: _sort,
    );
    setState(() {
      _error = query.validationError;
    });
    if (_error == null) {
      setState(() => _active = query);
      if (dismissKeyboard) FocusScope.of(context).unfocus();
      widget.onApply(query);
      _loadSuggestions(query);
    }
  }

  Future<void> _loadSuggestions(ListingQuery query) async {
    final request = ++_suggestionRequest;
    final repository = widget.repository;
    if (repository is! CatalogueDiscoveryRepository ||
        query.text.trim().runes.length < 3) {
      if (mounted) setState(() => _suggestions = []);
      return;
    }
    try {
      final values = await (repository as CatalogueDiscoveryRepository)
          .suggestions(query);
      if (mounted && request == _suggestionRequest) {
        setState(() => _suggestions = values.take(5).toList());
      }
    } catch (_) {
      if (mounted && request == _suggestionRequest) {
        setState(() => _suggestions = []);
      }
    }
  }

  void _clear() {
    _typing?.cancel();
    for (final field in [_text, _city, _min, _max]) {
      field.clear();
    }
    setState(() {
      _category = null;
      _sort = ListingSort.relevance;
      _suggestions = [];
      _suggestionRequest++;
      _error = null;
      _active = const ListingQuery();
    });
    FocusScope.of(context).unfocus();
    widget.onApply(const ListingQuery());
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: KiboFormColumn(
      children: [
        KiboSearchFieldTheme(
          child: SearchBar(
            key: const ValueKey('catalogue-search'),
            controller: _text,
            onChanged: (_) {
              final limited = LengthLimitingTextInputFormatter(
                120,
              ).formatEditUpdate(TextEditingValue.empty, _text.value);
              if (limited != _text.value) _text.value = limited;
              _typing?.cancel();
              _suggestionRequest++;
              setState(() => _suggestions = []);
              final length = _text.text.trim().runes.length;
              if (length == 0 || length >= 3) {
                _typing = Timer(const Duration(milliseconds: 350), () {
                  if (mounted) _apply(dismissKeyboard: false);
                });
              }
            },
            hintText: 'Rechercher une annonce',
            leading: const Icon(Icons.search),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _apply(),
            trailing: [
              IconButton(
                tooltip: 'Lancer la recherche',
                onPressed: _apply,
                icon: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ),
        if (_suggestions.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final suggestion in _suggestions)
                ActionChip(
                  avatar: Icon(
                    suggestion.correction ? Icons.spellcheck : Icons.search,
                    size: 18,
                  ),
                  label: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Text(
                      suggestion.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  tooltip: suggestion.correction
                      ? 'Suggestion avec correction'
                      : 'Suggestion de recherche',
                  onPressed: () {
                    _text.value = TextEditingValue(
                      text: suggestion.text,
                      selection: TextSelection.collapsed(
                        offset: suggestion.text.length,
                      ),
                    );
                    _apply();
                  },
                ),
            ],
          ),
        const SizedBox(height: 12),
        Expansible(
          controller: _filters,
          key: const PageStorageKey('catalogue-expanded-filters'),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          headerBuilder: (context, animation) => ListenableBuilder(
            listenable: _filters,
            builder: (context, _) => Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                avatar: const Icon(Icons.tune_rounded),
                label: const Text('Filtres et tri'),
                selected: _filters.isExpanded,
                onSelected: (selected) =>
                    selected ? _filters.expand() : _filters.collapse(),
              ),
            ),
          ),
          bodyBuilder: (context, animation) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_loading)
                  const LinearProgressIndicator(
                    semanticsLabel: 'Chargement des catégories',
                  ),
                if (_categoryError != null)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(_categoryError!),
                      TextButton(
                        onPressed: _loadCategories,
                        child: const Text('Réessayer les catégories'),
                      ),
                    ],
                  ),
                DropdownButtonFormField<String>(
                  key: ValueKey(_category),
                  initialValue: _category,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Toutes les catégories'),
                    ),
                    if (_category != null &&
                        !_categories.any(
                          (category) => category.id == _category,
                        ))
                      DropdownMenuItem(
                        value: _category,
                        child: const Text('Catégorie sélectionnée'),
                      ),
                    for (final category in _categories)
                      DropdownMenuItem(
                        value: category.id,
                        child: Text(
                          category.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _category = value;
                  }),
                ),
                const SizedBox(height: 12),
                CongoCityField(
                  selectionOnly: true,
                  fieldKey: const ValueKey('catalogue-city'),
                  controller: _city,
                  scrollController: _cityScroll,
                  allowAll: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('catalogue-min'),
                  controller: _min,
                  scrollController: _minScroll,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Prix minimum (XAF)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('catalogue-max'),
                  controller: _max,
                  scrollController: _maxScroll,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Prix maximum (XAF)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ListingSort>(
                  key: ValueKey(_sort),
                  initialValue: _sort,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Trier par'),
                  items: const [
                    DropdownMenuItem(
                      value: ListingSort.relevance,
                      child: Text('Pertinence'),
                    ),
                    DropdownMenuItem(
                      value: ListingSort.newest,
                      child: Text('Plus récentes'),
                    ),
                    DropdownMenuItem(
                      value: ListingSort.priceAscending,
                      child: Text('Prix croissant'),
                    ),
                    DropdownMenuItem(
                      value: ListingSort.priceDescending,
                      child: Text('Prix décroissant'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _sort = value!;
                  }),
                ),
              ],
            ),
          ),
        ),
        if (!_active.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (_active.text.isNotEmpty)
                  _chip('Recherche : ${_active.text}', () => _text.clear()),
                if (_active.city.isNotEmpty)
                  _chip('Ville : ${_active.city}', () => _city.clear()),
                if (_active.categoryId != null)
                  _chip('Catégorie', () => _category = null),
                if (_active.minPrice.isNotEmpty)
                  _chip('Dès ${_active.minPrice} XAF', () => _min.clear()),
                if (_active.maxPrice.isNotEmpty)
                  _chip('Jusqu’à ${_active.maxPrice} XAF', () => _max.clear()),
                if (_active.sort != ListingSort.relevance)
                  _chip(
                    _active.sort == ListingSort.newest
                        ? 'Plus récentes'
                        : _active.sort == ListingSort.priceAscending
                        ? 'Prix croissant'
                        : 'Prix décroissant',
                    () => _sort = ListingSort.relevance,
                  ),
              ],
            ),
          ),
        if (_error != null) Semantics(liveRegion: true, child: Text(_error!)),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton(onPressed: _apply, child: const Text('Rechercher')),
            TextButton(
              onPressed: _clear,
              child: const Text('Effacer les critères'),
            ),
          ],
        ),
      ],
    ),
  );
}
