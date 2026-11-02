import 'dart:async';
import 'package:flutter/widgets.dart';
import '../auth/auth_controller.dart';
import '../listings/listing_models.dart';
import 'favorites_repository.dart';
import 'guest_favorites.dart';
import '../listings/listing_repository.dart';

class FavoritesController extends ChangeNotifier {
  FavoritesController(this.repository, {this.guest}) {
    guest?.addListener(_notify);
  }
  final FavoritesRepository repository;
  final GuestFavoritesController? guest;
  bool importing = false, _transferDismissed = false;
  int get sessionRevision => _epoch;
  bool get offersTransfer =>
      owner != null &&
      !_transferDismissed &&
      guest?.ready == true &&
      guest!.ids.isNotEmpty;
  void dismissTransfer() {
    _transferDismissed = true;
    _notify();
  }

  String? owner, pendingId, error;
  Set<String> ids = {};
  List<PublicListing> items = [];
  bool loading = false, loaded = false, moreLoading = false, hasMore = false;
  int _epoch = 0;
  bool _disposed = false;
  bool get busy => loading || moreLoading || pendingId != null || importing;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _current(String user, int epoch) =>
      !_disposed &&
      owner == user &&
      repository.userId == user &&
      epoch == _epoch;
  void _finish(String user, int epoch, VoidCallback finish) {
    if (_disposed || owner != user || epoch != _epoch) return;
    if (repository.userId != user) {
      bindUser(null);
      return;
    }
    finish();
    _notify();
  }

  void bindUser(String? user) {
    if (owner == user) return;
    _epoch++;
    owner = user;
    _transferDismissed = false;
    ids = {};
    items = [];
    error = null;
    loading = false;
    loaded = false;
    hasMore = false;
    moreLoading = false;
    pendingId = null;
    _notify();
    if (user != null) unawaited(refresh());
  }

  Future<void> importGuestFavorites({
    required String expectedOwner,
    required int expectedRevision,
  }) async {
    final local = guest;
    if (busy ||
        local == null ||
        !_current(expectedOwner, expectedRevision) ||
        !local.beginTransfer()) {
      return;
    }
    importing = true;
    error = null;
    _notify();
    final selection = local.ids;
    try {
      final existing = await repository.ids(expectedOwner);
      for (final id in selection.difference(existing)) {
        if (!_current(expectedOwner, expectedRevision)) return;
        try {
          await repository.add(id, expectedOwner);
        } catch (_) {
          // Un élément refusé reste local ; les autres peuvent être confirmés.
        }
      }
      if (!_current(expectedOwner, expectedRevision)) return;
      final confirmed = await repository.ids(expectedOwner);
      if (!_current(expectedOwner, expectedRevision)) return;
      final transferred = selection.intersection(confirmed);
      final saved =
          transferred.isEmpty || await local.removeTransferred(transferred);
      if (!_current(expectedOwner, expectedRevision)) return;
      await _reload(expectedOwner, expectedRevision);
      if (!_current(expectedOwner, expectedRevision)) return;
      if (!saved || transferred.length != selection.length) {
        error =
            'Transfert incomplet. Les favoris non confirmés restent sur ce téléphone ; vous pouvez réessayer.';
      }
    } catch (_) {
      if (_current(expectedOwner, expectedRevision)) {
        error = 'Transfert non confirmé. Vos favoris locaux sont conservés.';
      }
    } finally {
      importing = false;
      local.endTransfer();
      _notify();
      if (!_disposed && _epoch != expectedRevision && owner != null) {
        unawaited(refresh());
      }
    }
  }

  Future<void> refresh() async {
    if (busy || owner == null) return;
    await _reload(owner!, _epoch);
  }

  Future<void> _reload(String user, int epoch) async {
    loading = true;
    error = null;
    _notify();
    try {
      final results = await Future.wait<Object>([
        repository.ids(user),
        repository.visible(user),
      ]);
      if (_current(user, epoch)) {
        ids = results[0] as Set<String>;
        items = results[1] as List<PublicListing>;
        loaded = true;
        hasMore = items.length == 20;
      }
    } catch (_) {
      if (_current(user, epoch)) {
        error = 'Impossible de charger vos favoris.';
        items = [];
        loaded = false;
      }
    } finally {
      _finish(user, epoch, () {
        loading = false;
      });
    }
  }

  Future<void> loadMore() async {
    if (busy || !hasMore || owner == null) return;
    final user = owner!, epoch = _epoch;
    moreLoading = true;
    error = null;
    _notify();
    try {
      final rows = await repository.visible(user, offset: items.length);
      if (_current(user, epoch)) {
        items = [...items, ...rows];
        hasMore = rows.length == 20;
      }
    } catch (_) {
      if (_current(user, epoch)) {
        error = 'Impossible de charger la suite des favoris.';
      }
    } finally {
      _finish(user, epoch, () {
        moreLoading = false;
      });
    }
  }

  Future<bool> toggle(String id) async {
    if (owner == null || busy || !loaded) return false;
    final user = owner!, epoch = _epoch, removing = ids.contains(id);
    pendingId = id;
    error = null;
    _notify();
    try {
      if (removing) {
        await repository.remove(id, user);
      } else {
        await repository.add(id, user);
      }
      if (!_current(user, epoch)) return false;
      ids = {...ids};
      if (removing) {
        ids.remove(id);
      } else {
        ids.add(id);
      }
      await _reload(user, epoch);
      return _current(user, epoch);
    } catch (_) {
      if (_current(user, epoch)) {
        error =
            'Action non confirmée. Actualisez vos favoris avant de réessayer.';
      }
      return false;
    } finally {
      _finish(user, epoch, () {
        pendingId = null;
      });
    }
  }

  @override
  void dispose() {
    guest?.removeListener(_notify);
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}

class FavoritesScope extends InheritedNotifier<FavoritesController> {
  const FavoritesScope({
    super.key,
    required FavoritesController controller,
    required super.child,
  }) : super(notifier: controller);
  static FavoritesController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FavoritesScope>()?.notifier;
}

class FavoritesSession extends StatefulWidget {
  const FavoritesSession({
    super.key,
    required this.repository,
    required this.child,
    this.guestStore,
    this.listings,
  });
  final FavoritesRepository repository;
  final Widget child;
  final GuestFavoritesStore? guestStore;
  final ListingRepository? listings;
  @override
  State<FavoritesSession> createState() => _FavoritesSessionState();
}

class _FavoritesSessionState extends State<FavoritesSession> {
  late final _guest = widget.guestStore == null || widget.listings == null
      ? null
      : GuestFavoritesController(widget.guestStore!, widget.listings!);
  late final _controller = FavoritesController(
    widget.repository,
    guest: _guest,
  );
  @override
  void initState() {
    super.initState();
    _guest?.initialize();
  }

  AuthController? _auth;
  void _sessionChanged() {
    final user = _auth?.identity?.id;
    _controller.bindUser(user == widget.repository.userId ? user : null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.maybeOf(context);
    if (!identical(auth, _auth)) {
      _auth?.removeListener(_sessionChanged);
      _auth = auth;
      _auth?.addListener(_sessionChanged);
      _sessionChanged();
    }
  }

  @override
  void dispose() {
    _auth?.removeListener(_sessionChanged);
    _controller.dispose();
    _guest?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FavoritesScope(controller: _controller, child: widget.child);
}
