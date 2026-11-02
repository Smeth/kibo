import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'listing_photos.dart';

class ListingDraftSnapshot {
  const ListingDraftSnapshot(
    this.fields, {
    this.createdId,
    this.operationId,
    this.photos = const [],
    this.photoDigests = const [],
  });
  final Map<String, String> fields;
  final String? createdId;
  final String? operationId;
  final List<ListingPhotoDraft> photos;
  final List<String> photoDigests;
  String encode() => jsonEncode({
    'version': 1,
    'fields': fields,
    'created_id': createdId,
    'operation_id': operationId,
    'photos': photos.isEmpty
        ? photoDigests
        : photos.map((photo) => photo.digest).toList(),
  });
  static ListingDraftSnapshot decode(String raw) {
    final value = jsonDecode(raw);
    if (value is! Map || value['version'] != 1 || value['fields'] is! Map) {
      throw const FormatException('Brouillon illisible');
    }
    final fields = Map<String, dynamic>.from(value['fields'] as Map);
    const allowed = {
      'title',
      'description',
      'price',
      'city',
      'neighborhood',
      'category',
      'type',
    };
    if (fields.keys.any((key) => !allowed.contains(key)) ||
        fields.values.any((v) => v is! String || v.length > 20000)) {
      throw const FormatException('Brouillon invalide');
    }
    final id = value['created_id'];
    if (id != null && (id is! String || id.isEmpty || id.length > 128)) {
      throw const FormatException('Identifiant invalide');
    }
    final operation = value['operation_id'];
    if (operation != null && (operation is! String || operation.length > 128)) {
      throw const FormatException('Identifiant invalide');
    }
    final digests = value['photos'] ?? const <String>[];
    if (digests is! List ||
        digests.length > maxListingPhotos ||
        digests.any(
          (d) => d is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(d),
        ) ||
        digests.toSet().length != digests.length) {
      throw const FormatException('Photos invalides');
    }
    return ListingDraftSnapshot(
      fields.cast<String, String>(),
      createdId: id as String?,
      operationId: operation as String?,
      photoDigests: digests.cast<String>(),
    );
  }
}

abstract interface class ListingDraftStore {
  Future<ListingDraftSnapshot?> read(String owner);
  Future<void> write(String owner, ListingDraftSnapshot value);
  Future<void> clear(String owner);
}

class SecureListingDraftStore implements ListingDraftStore {
  SecureListingDraftStore({
    required this.projectHost,
    FlutterSecureStorage? storage,
    Future<Directory> Function()? directory,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _directory = directory ?? getApplicationSupportDirectory;
  final String projectHost;
  final FlutterSecureStorage _storage;
  final Future<Directory> Function() _directory;
  Future<void> _pending = Future.value();
  String _key(String owner) {
    if (owner.isEmpty) throw ArgumentError('Compte requis');
    return 'kibo.draft.v1.$projectHost.$owner';
  }

  Future<T> _queue<T>(Future<T> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<Directory> _photoDirectory(String owner) async {
    _key(owner);
    final base = await _directory();
    final folder = Directory(
      '${base.path}/kibo_drafts_${sha256.convert(utf8.encode('$projectHost|$owner'))}',
    );
    final type = await FileSystemEntity.type(folder.path, followLinks: false);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.directory) {
      throw const FileSystemException('Dossier de brouillon invalide');
    }
    return folder;
  }

  Future<ListingPhotoDraft> _readPhoto(Directory folder, String digest) async {
    final file = File('${folder.path}/$digest.jpg');
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
            FileSystemEntityType.file ||
        await file.length() > maxPhotoBytes) {
      throw const FileSystemException('Photo de brouillon indisponible');
    }
    final bytes = await file.readAsBytes();
    final photo = ListingPhotoDraft(bytes);
    if (bytes.isEmpty || photo.digest != digest) {
      throw const FormatException('Photo de brouillon altérée');
    }
    return photo;
  }

  Future<void> _prune(Directory folder, Set<String> keep) async {
    if (!await folder.exists()) return;
    await for (final entity in folder.list(followLinks: false)) {
      final name = entity.uri.pathSegments.last;
      if (entity is File &&
          RegExp(r'^[a-f0-9]{64}\.jpg(?:\.tmp)?$').hasMatch(name) &&
          (name.endsWith('.tmp') || !keep.contains(name.substring(0, 64)))) {
        await entity.delete();
      }
    }
  }

  @override
  Future<ListingDraftSnapshot?> read(String owner) => _queue(() async {
    final raw = await _storage.read(key: _key(owner));
    if (raw == null) return null;
    final snapshot = ListingDraftSnapshot.decode(raw);
    if (snapshot.photoDigests.isEmpty) return snapshot;
    final folder = await _photoDirectory(owner);
    final photos = <ListingPhotoDraft>[];
    for (final digest in snapshot.photoDigests) {
      photos.add(await _readPhoto(folder, digest));
    }
    return ListingDraftSnapshot(
      snapshot.fields,
      createdId: snapshot.createdId,
      operationId: snapshot.operationId,
      photos: photos,
    );
  });

  @override
  Future<void> write(
    String owner,
    ListingDraftSnapshot value,
  ) => _queue(() async {
    final manifest = ListingDraftSnapshot.decode(value.encode());
    if (value.photos.isEmpty && value.photoDigests.isNotEmpty) {
      throw const FormatException('Photos non restaurées');
    }
    if (value.photos.length > maxListingPhotos ||
        value.photos.any(
          (p) =>
              p.bytes.isEmpty ||
              p.bytes.length > maxPhotoBytes ||
              sha256.convert(p.bytes).toString() != p.digest,
        )) {
      throw const FormatException('Photos invalides');
    }
    final previousRaw = await _storage.read(key: _key(owner));
    final previous = previousRaw == null
        ? null
        : ListingDraftSnapshot.decode(previousRaw);
    // Files precede the manifest: a failed save leaves the previous draft readable.
    Directory? folder;
    if (value.photos.isNotEmpty) {
      folder = await _photoDirectory(owner);
      await folder.create(recursive: true);
      for (final photo in value.photos) {
        final file = File('${folder.path}/${photo.digest}.jpg');
        if (await FileSystemEntity.type(file.path, followLinks: false) ==
            FileSystemEntityType.notFound) {
          final temp = File('${file.path}.tmp');
          final tempType = await FileSystemEntity.type(
            temp.path,
            followLinks: false,
          );
          if (tempType == FileSystemEntityType.file) {
            await temp.delete();
          } else if (tempType != FileSystemEntityType.notFound) {
            throw const FileSystemException('Fichier temporaire invalide');
          }
          await temp.writeAsBytes(photo.bytes, flush: true);
          await temp.rename(file.path);
        } else {
          await _readPhoto(folder, photo.digest);
        }
      }
    }
    await _storage.write(key: _key(owner), value: value.encode());
    // Text-only drafts do not invoke a platform directory channel until needed.
    if (folder != null || previous?.photoDigests.isNotEmpty == true) {
      await _prune(
        folder ?? await _photoDirectory(owner),
        manifest.photoDigests.toSet(),
      );
    }
  });
  @override
  Future<void> clear(String owner) => _queue(() async {
    await _storage.delete(key: _key(owner));
    // Only this account's generated files; never recursive directory deletion.
    await _prune(await _photoDirectory(owner), {});
  });
}
