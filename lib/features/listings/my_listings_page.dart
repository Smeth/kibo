import '../../core/widgets/kibo_modal.dart';
import '../../core/widgets/kibo_app_bar.dart';
import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import '../favorites/favorites_controller.dart';
import 'listing_repository.dart';
import 'owned_listing_repository.dart';
import 'owned_listing_query.dart';
import 'edit_listing_page.dart';
import 'listing_photo_widgets.dart';
import '../../core/widgets/kibo_state_panel.dart';
import '../../core/widgets/kibo_form_layout.dart';

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({
    super.key,
    required this.repository,
    required this.listings,
  });
  final OwnedListingRepository repository;
  final ListingRepository listings;
  @override
  Widget build(BuildContext context) {
    final owner = AuthScope.maybeOf(context)?.identity?.id;
    return Scaffold(
      appBar: KiboAppBar(context, title: const Text('Mes annonces')),
      body: owner == null
          ? const Center(child: Text('Connectez-vous pour gérer vos annonces.'))
          : _OwnedFeed(
              key: ValueKey(owner),
              owner: owner,
              repository: repository,
              listings: listings,
            ),
    );
  }
}

class _OwnedFeed extends StatefulWidget {
  const _OwnedFeed({
    super.key,
    required this.owner,
    required this.repository,
    required this.listings,
  });
  final String owner;
  final OwnedListingRepository repository;
  final ListingRepository listings;
  @override
  State<_OwnedFeed> createState() => _OwnedFeedState();
}

class _OwnedFeedState extends State<_OwnedFeed> {
  List<OwnedListing> _rows = [];
  bool _loading = true, _more = true, _busy = false, _confirming = false;
  String? _error, _message;
  int _request = 0;
  OwnedListingQuery _query = const OwnedListingQuery();
  final _search = TextEditingController();
  final _searchForm = GlobalKey<FormState>();
  final _selected = <String>{};
  AuthController? _auth;
  bool _invalidated = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.maybeOf(context);
    if (!identical(auth, _auth)) {
      _auth?.removeListener(_sessionChanged);
      _auth = auth;
      _auth?.addListener(_sessionChanged);
    }
  }

  void _sessionChanged() {
    if (_auth?.identity?.id != widget.owner) {
      _invalidated = true;
      _selected.clear();
      _request++;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _auth?.removeListener(_sessionChanged);
    _search.dispose();
    super.dispose();
  }

  void _searchListings() {
    if (_busy || _confirming || !_current) return;
    final query = OwnedListingQuery(
      status: _query.status,
      text: _search.text.trim(),
    );
    final form = _searchForm.currentState;
    if (form != null && !form.validate()) return;
    // Le formulaire peut être hors de l'arbre après une longue pagination.
    if (query.validationError != null) {
      setState(() => _message = query.validationError);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _query = query;
      _selected.clear();
      _message = null;
    });
    _load(reset: true);
  }

  void _resetCriteria() {
    if (_busy || _confirming || !_current) return;
    _searchForm.currentState?.reset();
    _search.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _query = const OwnedListingQuery();
      _selected.clear();
      _message = null;
    });
    _load(reset: true);
  }

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  bool get _current =>
      mounted && !_invalidated && widget.repository.userId == widget.owner;

  Future<void> _bulk(String target) async {
    if (_busy || _loading || _confirming || !_current) return;
    final selected = _rows.where((r) => _selected.contains(r.id)).toList();
    if (selected.isEmpty ||
        selected.any((r) => target == 'sold' ? !r.canSell : !r.canArchive)) {
      return;
    }
    setState(() => _confirming = true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => KiboDialog(
        destructive: target == 'archived',
        title: Text(
          target == 'archived'
              ? 'Retirer ${selected.length == 1 ? "cette annonce" : "${selected.length} annonces"} du catalogue ?'
              : 'Marquer ${selected.length == 1 ? "cette annonce vendue" : "${selected.length} annonces vendues"} ?',
        ),
        content: Text(
          target == 'archived'
              ? 'Les annonces seront archivées et retirées du catalogue public. Leurs photos, favoris et conversations seront conservés. Un bilan indiquera les éventuels échecs ; aucun effacement définitif.'
              : 'Les annonces seront marquées vendues et quitteront le catalogue public. Leurs photos, favoris et conversations seront conservés. Un bilan indiquera les éventuels échecs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer la sélection'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _confirming = false);
    if (confirmed != true || !_current) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    var succeeded = 0, failed = 0;
    try {
      for (final listing in selected) {
        if (!_current) return;
        try {
          await widget.repository.transition(listing, target);
          if (!_current) return;
          succeeded++;
          _selected.remove(listing.id);
        } catch (_) {
          if (!_current) return;
          failed++;
        }
      }
      if (!_current) return;
      if (!mounted) return;
      FavoritesScope.maybeOf(context)?.refresh();
      setState(
        () => _message =
            '$succeeded annonce(s) traitée(s), $failed échec(s).${failed > 0 ? ' Les échecs sont conservés dans la sélection si les annonces sont encore affichées. Actualisez avant de réessayer.' : ''}',
      );
      await _load(reset: true, keepRows: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _load({required bool reset, bool keepRows = false}) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      if (reset && !keepRows) _rows = [];
    });
    try {
      final page = await widget.repository.mine(
        widget.owner,
        offset: reset ? 0 : _rows.length,
        query: _query,
      );
      if (!_current || request != _request) return;
      if (page.any((row) => row.sellerId != widget.owner)) {
        throw StateError('Propriétaire inattendu.');
      }
      setState(() {
        _rows = reset ? page : [..._rows, ...page];
        if (reset) {
          _selected.retainAll(
            _rows.where((r) => r.canArchive).map((r) => r.id),
          );
        }
        _more = page.length == 20;
      });
    } catch (error) {
      if (_current && request == _request) {
        setState(() => _error = listingManagementError(error));
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _transition(
    OwnedListing listing,
    String target, {
    bool remove = false,
  }) async {
    if (_busy || _confirming || !_current) return;
    _confirming = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => KiboDialog(
        destructive: remove || target == 'archived',
        icon: Icon(remove ? Icons.delete_outline : Icons.inventory_2_outlined),
        title: Text(
          remove
              ? 'Supprimer du catalogue ?'
              : target == 'sold'
              ? 'Marquer comme vendue ?'
              : 'Archiver cette annonce ?',
        ),
        content: Text(
          remove
              ? 'Votre annonce sera archivée et ne sera plus visible dans le catalogue. Les photos, favoris et conversations restent conservés. Il ne s’agit pas d’un effacement définitif.'
              : 'L’annonce quittera le catalogue public. Les photos et les favoris seront conservés. Cette action ne republie pas l’annonce.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(remove ? 'Retirer du catalogue' : 'Confirmer'),
          ),
        ],
      ),
    );
    _confirming = false;
    if (confirmed != true || !_current) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.repository.transition(listing, target);
      if (!mounted || !_current) return;
      FavoritesScope.maybeOf(context)?.refresh();
      setState(
        () => _message = remove
            ? 'Annonce retirée du catalogue et archivée.'
            : target == 'sold'
            ? 'Annonce marquée vendue.'
            : 'Annonce archivée.',
      );
      await _load(reset: true);
    } catch (error) {
      if (_current) setState(() => _message = listingManagementError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(OwnedListing listing) async {
    final auth = AuthScope.maybeOf(context)!;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) {
          Widget page = EditListingPage(
            listing: listing,
            repository: widget.repository,
            listings: widget.listings,
          );
          final photos = ListingPhotoScope.maybeOf(context);
          if (photos != null) {
            page = ListingPhotoScope(
              repository: photos.repository,
              picker: photos.picker,
              child: page,
            );
          }
          return AuthScope(controller: auth, child: page);
        },
      ),
    );
    if (mounted && _current) {
      if (changed == true) FavoritesScope.maybeOf(context)?.refresh();
      await _load(reset: true);
    }
  }

  void _toggleSelection(OwnedListing row) {
    if (_busy || _loading || _confirming || !_current || !row.canArchive) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      if (!_selected.remove(row.id)) _selected.add(row.id);
    });
  }

  Future<void> _selectionActions() async {
    if (_busy || _loading || _confirming || !_current) return;
    final canSell = _rows
        .where((r) => _selected.contains(r.id))
        .every((r) => r.canSell);
    final action = await showKiboModalSheet<String>(
      context: context,
      builder: (context) => KiboSheet(
        title: 'Gérer la sélection',
        subtitle:
            '${_selected.length} annonce${_selected.length > 1 ? "s" : ""} sélectionnée${_selected.length > 1 ? "s" : ""}',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KiboSheetAction(
              label: 'Marquer la sélection vendue',
              icon: Icons.check_circle_outline,
              onTap: canSell ? () => Navigator.pop(context, 'sold') : null,
            ),
            KiboSheetAction(
              label: 'Supprimer la sélection',
              icon: Icons.inventory_2_outlined,
              destructive: true,
              onTap: () => Navigator.pop(context, 'archived'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || !_current || action == null) return;
    await _bulk(action);
  }

  Widget _selectionBar(double availableHeight) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Material(
        key: const ValueKey('owned-selection-bar'),
        color: Theme.of(context).colorScheme.surface,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: .12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: availableHeight * .4),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        '${_selected.length} annonce${_selected.length > 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Actions de la sélection',
                    onPressed: _busy || _loading || _confirming
                        ? null
                        : _selectionActions,
                    icon: const Icon(Icons.more_horiz_rounded),
                  ),
                  IconButton(
                    tooltip: 'Tout désélectionner',
                    onPressed: _busy || _loading || _confirming
                        ? null
                        : () => setState(_selected.clear),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => _invalidated
      ? const Center(child: Text('Session modifiée. Revenez depuis Profil.'))
      : LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              Expanded(child: _feed()),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: _selected.isNotEmpty
                    ? _selectionBar(constraints.maxHeight)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );

  Widget _feed() => RefreshIndicator(
    onRefresh: () async {
      if (!_busy && !_loading && !_confirming && _current) {
        await _load(reset: true, keepRows: true);
      }
    },
    child: ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _rows.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return KiboFormColumn(
            children: [
              Form(
                key: _searchForm,
                child: TextFormField(
                  key: const ValueKey('owned-search'),
                  controller: _search,
                  enabled: !_busy && !_confirming,
                  decoration: const InputDecoration(
                    labelText: 'Rechercher dans mes annonces',
                    hintText: 'Titre ou description',
                    prefixIcon: Icon(Icons.search),
                  ),
                  textInputAction: TextInputAction.search,
                  validator: (value) =>
                      OwnedListingQuery(text: value ?? '').validationError,
                  onFieldSubmitted: (_) => _searchListings(),
                ),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Statut'),
                child: DropdownButton<OwnedListingStatus>(
                  key: const ValueKey('owned-status'),
                  value: _query.status,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final status in OwnedListingStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                  ],
                  onChanged: _busy || _confirming
                      ? null
                      : (status) {
                          if (status == null || status == _query.status) {
                            return;
                          }
                          setState(() {
                            _query = OwnedListingQuery(
                              status: status,
                              text: _query.text,
                            );
                            _message = null;
                            _selected.clear();
                          });
                          _load(reset: true);
                        },
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 12,
                children: [
                  FilledButton.tonal(
                    onPressed: _busy ? null : _searchListings,
                    child: const Text('Rechercher'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _resetCriteria,
                    child: const Text('Réinitialiser'),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: _busy || _loading || _confirming
                        ? null
                        : () => setState(() {
                            _selected.addAll(
                              _rows.where((r) => r.canArchive).map((r) => r.id),
                            );
                          }),
                    icon: const Icon(Icons.select_all),
                    label: const Text('Sélectionner les annonces chargées'),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _busy || _loading
                      ? null
                      : () => _load(reset: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualiser'),
                ),
              ),
              if (_message != null)
                Semantics(liveRegion: true, child: Text(_message!)),
              if (!_loading && _error == null && _rows.isEmpty)
                KiboStatePanel(
                  icon: Icons.storefront_outlined,
                  title: _query.isEmpty
                      ? 'Vous n’avez pas encore d’annonce.'
                      : 'Aucune annonce ne correspond à ces critères.',
                  message: _query.isEmpty
                      ? 'Vos annonces apparaîtront ici après publication.'
                      : 'Essayez un autre statut ou modifiez votre recherche.',
                ),
            ],
          );
        }
        if (index <= _rows.length) {
          final row = _rows[index - 1];
          final selected = _selected.contains(row.id);
          return Semantics(
            selected: selected,
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: selected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  width: selected ? 2 : 1,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: ValueKey('owned-card-${row.id}'),
                onTap: _busy || _loading || _confirming || !row.canArchive
                    ? null
                    : () => _toggleSelection(row),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (row.canArchive)
                        CheckboxListTile(
                          key: ValueKey('select-owned-${row.id}'),
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Sélectionner cette annonce'),
                          value: _selected.contains(row.id),
                          onChanged: _busy || _loading || _confirming
                              ? null
                              : (_) => _toggleSelection(row),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: 80,
                              height: 88,
                              child: row.photoPaths.isEmpty
                                  ? ColoredBox(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                      child: const Icon(
                                        Icons.photo_outlined,
                                        size: 32,
                                      ),
                                    )
                                  : ListingPhotoView(
                                      path: row.photoPaths.first,
                                      label: row.draft.title,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row.draft.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  row.priceLabel,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                Text(
                                  row.draft.city,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          avatar: Icon(
                            row.status == 'published'
                                ? Icons.visibility_outlined
                                : row.status == 'sold'
                                ? Icons.check_circle_outline
                                : Icons.inventory_2_outlined,
                            size: 18,
                          ),
                          label: Text(row.statusLabel),
                        ),
                      ),
                      const Divider(),
                      Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        children: [
                          if (row.canEdit)
                            TextButton(
                              onPressed: _busy || _loading
                                  ? null
                                  : () => _edit(row),
                              child: const Text('Modifier'),
                            ),
                          if (row.canSell)
                            TextButton(
                              onPressed: _busy || _loading
                                  ? null
                                  : () => _transition(row, 'sold'),
                              child: const Text('Marquer vendue'),
                            ),
                          if (row.canArchive)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                              onPressed: _busy || _loading
                                  ? null
                                  : () => _transition(
                                      row,
                                      'archived',
                                      remove: true,
                                    ),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Supprimer du catalogue'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_loading || _busy)
              const Center(child: CircularProgressIndicator()),
            if (_error != null) ...[
              Semantics(liveRegion: true, child: Text(_error!)),
              TextButton(
                onPressed: _busy ? null : () => _load(reset: _rows.isEmpty),
                child: const Text('Réessayer'),
              ),
            ],
            if (!_loading && _error == null && _more)
              TextButton(
                onPressed: _busy ? null : () => _load(reset: false),
                child: const Text('Charger la suite'),
              ),
          ],
        );
      },
    ),
  );
}
