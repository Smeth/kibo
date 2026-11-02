import 'package:flutter/foundation.dart';

class _PhotoEntry {
  _PhotoEntry(this.expires);
  final DateTime expires;
  Uint8List? bytes;
  Future<Uint8List>? pending;
}

/// Cache de session uniquement : pas de fichier privé persistant sur disque.
class ListingPhotoCache {
  ListingPhotoCache({
    required this.scope,
    required this.download,
    DateTime Function()? now,
    this.maxBytes = 24 * 1024 * 1024,
    this.maxEntries = 100,
    this.ttl = const Duration(seconds: 45),
  }) : _now = now ?? DateTime.now;
  final Object? Function() scope;
  final Future<Uint8List> Function(String) download;
  final DateTime Function() _now;
  final int maxBytes, maxEntries;
  final Duration ttl;
  final _entries = <String, _PhotoEntry>{};
  Object? _scope;
  int _revision = 0, _bytes = 0;
  int get byteCount => _bytes;
  int get entryCount => _entries.length;
  int get revision {
    _checkScope();
    return _revision;
  }

  void _checkScope() {
    final current = scope();
    if (_scope != current) {
      _scope = current;
      clear();
    }
  }

  void clear() {
    _entries.clear();
    _bytes = 0;
    _revision++;
  }

  void evict(String path) {
    final entry = _entries.remove(path);
    _bytes -= entry?.bytes?.lengthInBytes ?? 0;
  }

  Future<Uint8List> read(String path, {bool force = false}) {
    _checkScope();
    if (force) evict(path);
    for (final key in _entries.keys.toList()) {
      if (!_now().isBefore(_entries[key]!.expires)) evict(key);
    }
    final cached = _entries.remove(path);
    if (cached != null) {
      _entries[path] = cached; // Plus récemment consultée.
      if (cached.bytes != null) return SynchronousFuture(cached.bytes!);
      return cached.pending!;
    }
    final revision = _revision;
    final entry = _PhotoEntry(_now().add(ttl));
    _entries[path] = entry;
    while (_entries.length > maxEntries) {
      evict(_entries.keys.first);
    }
    return entry.pending = Future<Uint8List>.sync(() => download(path))
        .then((bytes) {
          _checkScope();
          if (revision != _revision) throw StateError('Session photo modifiée');
          if (identical(_entries[path], entry)) {
            if (bytes.lengthInBytes <= maxBytes) {
              entry.bytes = bytes;
              _bytes += bytes.lengthInBytes;
              while (_bytes > maxBytes && _entries.isNotEmpty) {
                evict(_entries.keys.first);
              }
            } else {
              evict(path);
            }
          }
          return bytes;
        })
        .catchError((Object error, StackTrace stack) {
          if (identical(_entries[path], entry)) evict(path);
          Error.throwWithStackTrace(error, stack);
        });
  }
}
