import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../listings/listing_models.dart';
import '../listings/listing_repository.dart';

abstract interface class GuestFavoritesStore {
  Future<Set<String>> read();
  Future<void> write(Set<String> ids);
}

class SecureGuestFavoritesStore implements GuestFavoritesStore {
  SecureGuestFavoritesStore({
    required String projectHost,
    FlutterSecureStorage? storage,
  }) : _key = 'kibo.guestFavorites.v1.$projectHost',
       _storage = storage ?? const FlutterSecureStorage();
  final String _key;
  final FlutterSecureStorage _storage;

  @override
  Future<Set<String>> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return {};
    final value = jsonDecode(raw);
    if (value is! Map || value['version'] != 1 || value['ids'] is! List) {
      throw const FormatException('Favoris locaux illisibles.');
    }
    final ids = value['ids'] as List;
    if (ids.any((id) => id is! String || id.isEmpty || id.length > 128)) {
      throw const FormatException('Identifiant local invalide.');
    }
    return ids.cast<String>().toSet();
  }

  @override
  Future<void> write(Set<String> ids) => _storage.write(
    key: _key,
    value: jsonEncode({'version': 1, 'ids': ids.toList()}),
  );
}

class GuestFavoritesController extends ChangeNotifier {
  GuestFavoritesController(this.store, this.listings);
  final GuestFavoritesStore store;
  final ListingRepository listings;
  Set<String> _ids = {};
  Set<String> get ids => Set.unmodifiable(_ids);
  List<PublicListing> items = [];
  bool ready = false, loading = false, saving = false, transferring = false;
  bool hasMore = false;
  String? error;
  int _offset = 0, _request = 0;
  bool _disposed = false;
  bool get busy => loading || saving || transferring;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    if (ready || busy || _disposed) return;
    loading = true;
    error = null;
    _notify();
    try {
      final saved = await store.read();
      if (_disposed) return;
      _ids = {...saved};
      ready = true;
    } catch (_) {
      if (!_disposed) {
        error =
            'Impossible de lire les favoris de ce téléphone. Réessayez sans effacer les données.';
      }
    } finally {
      loading = false;
      _notify();
    }
    if (ready && !_disposed) await refresh();
  }

  Future<bool> toggle(String id) async {
    if (!ready || busy || _disposed) return false;
    final next = {..._ids};
    if (!next.remove(id)) next.add(id);
    return _save(next);
  }

  Future<bool> _save(Set<String> next) async {
    saving = true;
    error = null;
    _notify();
    try {
      await store.write(next);
      if (_disposed) return false;
      _request++;
      _offset -= _ids.take(_offset).where((id) => !next.contains(id)).length;
      _ids = next;
      items = items.where((row) => next.contains(row.id)).toList();
      hasMore = _offset < _ids.length;
      return true;
    } catch (_) {
      if (!_disposed) {
        error =
            'Enregistrement local non confirmé. Vos favoris précédents sont conservés.';
      }
      return false;
    } finally {
      saving = false;
      _notify();
    }
  }

  bool beginTransfer() {
    if (!ready || busy || _disposed) return false;
    transferring = true;
    _notify();
    return true;
  }

  Future<bool> removeTransferred(Set<String> confirmed) =>
      _save(_ids.difference(confirmed));

  void endTransfer() {
    transferring = false;
    _notify();
  }

  Future<void> refresh({bool append = false}) async {
    if (_disposed || busy) return;
    if (!ready) {
      await initialize();
      return;
    }
    if (!ready || _disposed || busy) return;
    final request = ++_request;
    loading = true;
    error = null;
    if (!append) {
      items = [];
      _offset = 0;
      hasMore = false;
    }
    final page = _ids.toList().skip(_offset).take(20).toList();
    _notify();
    try {
      // detail filtre published même si un propriétaire est maintenant connecté.
      final rows = await Future.wait(page.map(listings.detail));
      if (_disposed || request != _request) return;
      items = [...items, ...rows.whereType<PublicListing>()];
      _offset += page.length;
      hasMore = _offset < _ids.length;
    } catch (_) {
      if (!_disposed && request == _request) {
        error =
            'Favoris enregistrés sur ce téléphone. Impossible de charger les annonces ; vérifiez votre connexion.';
      }
    } finally {
      if (request == _request) loading = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _request++;
    super.dispose();
  }
}
