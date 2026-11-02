import 'package:flutter/material.dart';
import 'listing_models.dart';
import 'listing_repository.dart';
import 'listing_card.dart';
import 'listing_detail_page.dart';
import '../favorites/favorites_controller.dart';
import 'listing_query.dart';
import 'catalogue_search_form.dart';
import 'listing_photo_widgets.dart';
import '../comments/comments_repository.dart';
import '../auth/auth_controller.dart';
import '../seller/seller_repository.dart';
import '../chat/chat_repository.dart';
import '../safety/safety_repository.dart';
import '../../core/widgets/kibo_state_panel.dart';

class ListingFeed extends StatefulWidget {
  const ListingFeed({
    super.key,
    required this.repository,
    this.leading = const [],
    this.searchEnabled = false,
    this.comments,
    this.sellers,
    this.contactLauncher,
    this.chats,
    this.safety,
    this.initialQuery = const ListingQuery(),
    this.onQueryChanged,
  });
  final ListingRepository repository;
  final List<Widget> leading;
  final bool searchEnabled;
  final CommentsRepository? comments;
  final SellerRepository? sellers;
  final ContactLauncher? contactLauncher;
  final ChatRepository? chats;
  final SafetyRepository? safety;
  final ListingQuery initialQuery;
  final ValueChanged<ListingQuery>? onQueryChanged;
  @override
  State<ListingFeed> createState() => _ListingFeedState();
}

class _ListingFeedState extends State<ListingFeed> {
  final _scroll = ScrollController();
  int _nextOffset = 0;
  List<PublicListing> _rows = [];
  bool _loading = true, _more = false, _hasMore = false;
  String? _error;
  int _request = 0;
  ListingQuery _query = const ListingQuery();
  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _scroll.addListener(_maybeLoadMore);
    _load();
  }

  void _maybeLoadMore() {
    if (!mounted ||
        !_scroll.hasClients ||
        !_hasMore ||
        _loading ||
        _more ||
        _error != null ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    if (_scroll.position.extentAfter < 500) _load(append: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool append = false}) async {
    if (append && (_loading || _more)) return;
    final request = ++_request;
    final offset = append ? _nextOffset : 0;
    setState(() {
      if (append) {
        _more = true;
      } else {
        _loading = true;
        _more = false;
        _hasMore = false;
      }
      _error = null;
    });
    try {
      final rows = await widget.repository
          .published(offset: offset, query: _query)
          .timeout(const Duration(seconds: 20));
      if (mounted && request == _request) {
        setState(() {
          _rows = {
            for (final row in [
              ...(append ? _rows : <PublicListing>[]),
              ...rows,
            ])
              row.id: row,
          }.values.toList();
          _nextOffset = offset + rows.length;
          _hasMore = rows.length == 20;
        });
      }
    } catch (error) {
      if (mounted && request == _request) {
        setState(() {
          _error = listingReadError(error);
        });
      }
    } finally {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _more = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore());
      }
    }
  }

  Future<void> _open(PublicListing listing) async {
    final auth = AuthScope.maybeOf(context);
    final favorites = FavoritesScope.maybeOf(context);
    final photos = ListingPhotoScope.maybeOf(context);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          Widget page = ListingDetailPage(
            id: listing.id,
            repository: widget.repository,
            comments: widget.comments,
            sellers: widget.sellers,
            chats: widget.chats,
            safety: widget.safety,
            contactLauncher: widget.contactLauncher,
          );
          if (photos != null) {
            page = ListingPhotoScope(
              repository: photos.repository,
              picker: photos.picker,
              child: page,
            );
          }
          if (auth != null) page = AuthScope(controller: auth, child: page);
          return favorites == null
              ? page
              : FavoritesScope(controller: favorites, child: page);
        },
      ),
    );
    // Conserver résultats et position au retour ; actualisation explicite disponible.
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async {
      if (!_loading && !_more) await _load();
    },
    child: CustomScrollView(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      key: PageStorageKey(
        widget.searchEnabled ? 'catalogue-search-feed' : 'catalogue-home-feed',
      ),
      slivers: [
        for (final widget in widget.leading) SliverToBoxAdapter(child: widget),
        if (widget.searchEnabled)
          SliverToBoxAdapter(
            child: CatalogueSearchForm(
              initialQuery: _query,
              repository: widget.repository,
              onApply: (query) {
                _query = query;
                _rows = [];
                widget.onQueryChanged?.call(query);
                _load();
              },
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      widget.searchEnabled
                          ? 'Résultats de recherche'
                          : 'Annonces récentes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualiser les annonces',
                  onPressed: _loading || _more ? null : () => _load(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ),
        if (_loading && _rows.isNotEmpty)
          const SliverToBoxAdapter(child: LinearProgressIndicator()),
        if (_loading && _rows.isEmpty)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          )
        else if (_error != null && _rows.isEmpty)
          SliverToBoxAdapter(child: _retry())
        else if (_rows.isEmpty)
          SliverToBoxAdapter(
            child: KiboStatePanel(
              title: _query.isEmpty
                  ? 'Aucune annonce publiée pour le moment.'
                  : 'Aucun résultat pour ces critères.',
              message:
                  'Essayez une autre recherche ou revenez consulter les nouvelles annonces.',
              actionLabel: _query.isEmpty
                  ? 'Actualiser'
                  : 'Réinitialiser les filtres',
              onAction: () {
                setState(() => _query = const ListingQuery());
                widget.onQueryChanged?.call(_query);
                _load();
              },
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final scaler = MediaQuery.textScalerOf(context);
                final columns =
                    !widget.searchEnabled &&
                        constraints.crossAxisExtent >=
                            312 * (scaler.scale(14) / 14) + 12
                    ? 2
                    : 1;
                final width =
                    (constraints.crossAxisExtent - (columns - 1) * 12) /
                    columns;
                final height = (width * 0.85).clamp(140.0, 180.0).toDouble();
                return SliverList.builder(
                  itemCount: (_rows.length / columns).ceil(),
                  itemBuilder: (context, index) {
                    final start = index * columns;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var offset = 0; offset < columns; offset++) ...[
                            if (offset > 0) const SizedBox(width: 12),
                            Expanded(
                              child: start + offset < _rows.length
                                  ? ListingCard(
                                      compact: widget.searchEnabled,
                                      uniform: !widget.searchEnabled,
                                      showCategory: false,
                                      listing: _rows[start + offset],
                                      imageHeight: height,
                                      onOpen: () =>
                                          _open(_rows[start + offset]),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        if (_error != null && _rows.isNotEmpty)
          SliverToBoxAdapter(child: _retry(append: true)),
        if (_more)
          SliverToBoxAdapter(
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Chargement des annonces suivantes',
                ),
              ),
            ),
          ),
      ],
    ),
  );
  Widget _retry({bool append = false}) => KiboStatePanel(
    title: _error!,
    icon: Icons.wifi_off_outlined,
    actionLabel: 'Réessayer',
    onAction: () => _load(append: append),
  );
}
