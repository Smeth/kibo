import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image/image.dart' as image;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../../core/diagnostics/photo_upload_diagnostics.dart';
import 'listing_photo_cache.dart';

const listingPhotosEnabled = bool.fromEnvironment(
  'KIBO_LISTING_PHOTOS_ENABLED',
);
const listingPhotoBucket = 'kibo-listing-photos';
const maxListingPhotos = 3;
const maxPhotoBytes = 4 * 1024 * 1024;
const maxSourcePhotoBytes = 20 * 1024 * 1024;
const mediaManagementEnabled = bool.fromEnvironment(
  'KIBO_MEDIA_MANAGEMENT_ENABLED',
);

class GalleryState {
  const GalleryState(
    this.paths,
    this.revision,
    this.updatedAt,
    this.editable, {
    this.baseUpdatedAt,
  });
  final String? baseUpdatedAt;
  final List<String> paths;
  final int revision;
  final String updatedAt;
  final bool editable;
  factory GalleryState.fromJson(Map data) => GalleryState(
    List<String>.from(data['paths'] as List),
    (data['revision'] as num).toInt(),
    data['updated_at'] as String,
    data['editable'] == true,
  );
}

class GalleryPhoto {
  const GalleryPhoto.existing(String value) : path = value, draft = null;
  const GalleryPhoto.added(ListingPhotoDraft value)
    : draft = value,
      path = null;
  final String? path;
  final ListingPhotoDraft? draft;
}

abstract interface class ListingGalleryRepository {
  bool get galleryEnabled;
  Future<GalleryState> gallery(String listing, String owner);
  Future<GalleryState> saveGallery(
    String listing,
    String owner,
    int revision,
    String operation,
    List<GalleryPhoto> photos,
  );
}

class PhotoValidationException implements Exception {
  const PhotoValidationException(this.message);
  final String message;
}

class ListingPhotoDraft {
  ListingPhotoDraft(Uint8List bytes)
    : bytes = Uint8List.fromList(bytes),
      digest = sha256.convert(bytes).toString();
  final Uint8List bytes;
  final String digest;
}

/// Décodage complet, orientation, retrait des métadonnées et réencodage JPEG.
/// Exécuté dans un isolate ; aucun fichier temporaire créé par KIBO.
Uint8List compressListingPhoto(Uint8List bytes) {
  try {
    return _compressListingPhoto(bytes);
  } on PhotoValidationException {
    rethrow;
  } catch (_) {
    throw const PhotoValidationException('Image illisible.');
  }
}

Uint8List _compressListingPhoto(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > maxSourcePhotoBytes) {
    throw const PhotoValidationException('Image source limitée à 20 Mo.');
  }
  final decoder = image.findDecoderForData(bytes);
  if (decoder is! image.JpegDecoder &&
      decoder is! image.PngDecoder &&
      decoder is! image.WebPDecoder) {
    throw const PhotoValidationException(
      'Formats acceptés : JPEG, PNG et WebP.',
    );
  }
  final info = decoder!.startDecode(bytes);
  if (info == null || info.width * info.height > 24000000) {
    throw const PhotoValidationException(
      'Image invalide ou supérieure à 24 mégapixels.',
    );
  }
  final decoded = decoder.decodeFrame(0);
  if (decoded == null) throw const PhotoValidationException('Image illisible.');
  var normalized = image.bakeOrientation(decoded);
  if (normalized.width > 1600 || normalized.height > 1600) {
    normalized = image.copyResize(
      normalized,
      width: normalized.width >= normalized.height ? 1600 : null,
      height: normalized.height > normalized.width ? 1600 : null,
    );
  }
  // Copie des pixels uniquement : ni GPS, ni EXIF, ni commentaire conservé.
  final clean = image.Image(width: normalized.width, height: normalized.height);
  clean.clear(image.ColorRgb8(255, 255, 255));
  image.compositeImage(clean, normalized);
  final result = image.encodeJpg(clean, quality: 82);
  if (result.length > maxPhotoBytes) {
    throw const PhotoValidationException('Photo compressée limitée à 4 Mo.');
  }
  return result;
}

abstract interface class ListingPhotoPicker {
  Future<List<ListingPhotoDraft>> pick(String owner);
  Future<List<ListingPhotoDraft>> recover(String owner);
}

class DeviceListingPhotoPicker implements ListingPhotoPicker {
  final ImagePicker _picker = ImagePicker();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _ownerKey = 'kibo_listing_photo_picker_owner';
  Future<void> _clearMarker(String? marker) async {
    if (marker != null && await _storage.read(key: _ownerKey) == marker) {
      await _storage.delete(key: _ownerKey);
    }
  }

  Future<List<ListingPhotoDraft>> _read(List<XFile> files) async {
    if (files.length > maxListingPhotos) {
      throw const PhotoValidationException('Choisissez au maximum 3 photos.');
    }
    final result = <ListingPhotoDraft>[];
    for (final file in files) {
      if (await file.length() > maxSourcePhotoBytes) {
        throw const PhotoValidationException('Image source limitée à 20 Mo.');
      }
      final bytes = await compute(
        compressListingPhoto,
        await file.readAsBytes(),
      );
      final photo = ListingPhotoDraft(bytes);
      if (!result.any((p) => p.digest == photo.digest)) result.add(photo);
    }
    return result;
  }

  @override
  Future<List<ListingPhotoDraft>> pick(String owner) async {
    final marker = '$owner:${DateTime.now().microsecondsSinceEpoch}';
    await _storage.write(key: _ownerKey, value: marker);
    try {
      return await _read(await _picker.pickMultiImage(limit: 3));
    } finally {
      await _clearMarker(marker);
    }
  }

  @override
  Future<List<ListingPhotoDraft>> recover(String owner) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return [];
    final marker = await _storage.read(key: _ownerKey);
    try {
      final response = await _picker.retrieveLostData();
      // Les données récupérées d'un ancien compte ne doivent jamais apparaître
      // dans le formulaire du compte maintenant connecté.
      if (marker == null || !marker.startsWith('$owner:')) return [];
      if (response.exception != null) {
        throw const PhotoValidationException(
          'Sélection interrompue. Sélectionnez à nouveau vos photos.',
        );
      }
      return await _read(response.files ?? []);
    } finally {
      await _clearMarker(marker);
    }
  }
}

abstract interface class ListingPhotoRepository {
  bool get enabled;
  Future<void> attach(
    String listingId,
    List<ListingPhotoDraft> photos,
    String owner,
  );
  Future<String> signedUrl(String path);
}

abstract interface class CachedListingPhotoRepository {
  int get photoCacheRevision;
  Future<Uint8List> photoBytes(String path, {bool force = false});
}

class PhotoBackendUnavailable implements Exception {
  const PhotoBackendUnavailable();
}

abstract interface class PhotoPublicationPreflight {
  Future<void> checkPublicationAvailability();
}

class SupabaseListingPhotoRepository
    implements
        ListingPhotoRepository,
        PhotoPublicationPreflight,
        ListingGalleryRepository,
        CachedListingPhotoRepository {
  SupabaseListingPhotoRepository(
    this.client, {
    this.enabled = listingPhotosEnabled,
    PhotoUploadDiagnostics? diagnostics,
  }) : diagnostics = diagnostics ?? PhotoUploadDiagnostics();
  final SupabaseClient client;
  Future<T> _galleryRun<T>(
    String owner,
    Future<T> Function(VoidCallback check) action,
  ) async {
    var invalid = false;
    final subscription = client.auth.onAuthStateChange.listen((event) {
      if (event.session?.user.id != owner) invalid = true;
    });
    void check() {
      _check(owner);
      if (invalid) throw StateError('Session modifiée.');
    }

    try {
      check();
      final result = await action(check);
      check();
      return result;
    } finally {
      await subscription.cancel();
    }
  }

  @override
  bool get galleryEnabled => enabled && mediaManagementEnabled;
  @override
  Future<GalleryState> gallery(String listing, String owner) =>
      _galleryRun(owner, (check) async {
        check();
        // Reclaim expired abandoned uploads and retry pending Storage cleanup.
        // Failure here must not prevent opening the gallery.
        try {
          await client.functions.invoke(
            'kibo-manage-listing-photos',
            body: {'action': 'cleanup'},
          );
        } catch (_) {}
        check();
        final data = await client.rpc(
          'kibo_photo_edit_state',
          params: {'p_listing': listing},
        );
        check();
        return GalleryState.fromJson(data as Map);
      });

  @override
  Future<GalleryState> saveGallery(
    String listing,
    String owner,
    int revision,
    String operation,
    List<GalleryPhoto> photos,
  ) => _galleryRun(owner, (check) async {
    if (!galleryEnabled || photos.length > 3) {
      throw const PhotoBackendUnavailable();
    }
    check();
    final prepared =
        await client.rpc(
              'kibo_prepare_photo_edit',
              params: {
                'p_listing': listing,
                'p_operation': operation,
                'p_revision': revision,
                'p_digests': photos
                    .where((p) => p.draft != null)
                    .map((p) => p.draft!.digest)
                    .toList(),
              },
            )
            as Map;
    final paths = <String>[];
    for (var i = 0; i < photos.length; i++) {
      check();
      final photo = photos[i];
      if (photo.path != null) {
        paths.add(photo.path!);
        continue;
      }
      final draft = photo.draft!;
      final expected = '$owner/$listing/edit-$operation-${draft.digest}.jpg';
      if (prepared['applied'] != true) {
        final uploaded = await client.functions.invoke(
          'kibo-upload-listing-photo',
          body: {
            'listingId': listing,
            'position': i,
            'operationId': operation,
            'digest': draft.digest,
            'base64': base64Encode(draft.bytes),
          },
        );
        if (uploaded.data is! Map ||
            uploaded.data['ok'] != true ||
            uploaded.data['path'] != expected) {
          throw StateError('Envoi non confirmé.');
        }
      }
      paths.add(expected);
    }
    check();
    final response = await client.functions.invoke(
      'kibo-manage-listing-photos',
      body: {
        'listingId': listing,
        'operationId': operation,
        'revision': revision,
        'paths': paths,
      },
    );
    if (response.data is! Map || response.data['ok'] != true) {
      throw StateError('Galerie non confirmée.');
    }
    check();
    return gallery(listing, owner);
  });

  final PhotoUploadDiagnostics diagnostics;
  late final _photoCache = ListingPhotoCache(
    scope: () => client.auth.currentSession?.accessToken,
    download: (path) => client.storage.from(listingPhotoBucket).download(path),
  );
  @override
  int get photoCacheRevision => _photoCache.revision;
  @override
  Future<Uint8List> photoBytes(String path, {bool force = false}) =>
      _photoCache.read(path, force: force);
  @override
  final bool enabled;

  @override
  Future<void> checkPublicationAvailability() async {
    if (!enabled) throw const PhotoBackendUnavailable();
    try {
      // Lecture sans lignes : ne réserve aucune photo et ne crée aucune annonce.
      await client.from('kibo_listing_photos').select('listing_id').limit(0);
      final transport = client.rest.httpClient;
      if (transport == null) throw const PhotoBackendUnavailable();
      final endpoint = Uri.parse(client.rest.url).replace(
        path: '/functions/v1/kibo-upload-listing-photo',
        query: null,
        fragment: null,
      );
      final request = http.Request('OPTIONS', endpoint)
        ..headers.addAll(client.rest.headers);
      final response = await transport
          .send(request)
          .timeout(const Duration(seconds: 10));
      await response.stream.drain<void>().timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const PhotoBackendUnavailable();
      }
    } catch (_) {
      throw const PhotoBackendUnavailable();
    }
  }

  void _check(String owner) {
    final session = client.auth.currentSession;
    if (session == null || session.isExpired || session.user.id != owner) {
      throw StateError('Session modifiée.');
    }
  }

  @override
  Future<void> attach(
    String listingId,
    List<ListingPhotoDraft> photos,
    String owner,
  ) => diagnostics.trace((attempt) async {
    if (!enabled) throw StateError('Photos non configurées sur ce serveur.');
    if (photos.length > maxListingPhotos ||
        photos.map((p) => p.digest).toSet().length != photos.length) {
      throw const PhotoValidationException('Trois photos distinctes maximum.');
    }
    for (var position = 0; position < photos.length; position++) {
      attempt.stage('session');
      _check(owner);
      attempt.stage('validation');
      final photo = photos[position];
      if (photo.bytes.isEmpty || photo.bytes.length > maxPhotoBytes) {
        throw const PhotoValidationException('Photo limitée à 4 Mo.');
      }
      final path = '$owner/$listingId/$position-${photo.digest}.jpg';
      // Réservation idempotente avec PK (listing_id, position) : pas de doublon
      // lors d'une reprise après réponse perdue, et au plus trois emplacements.
      final row = {'listing_id': listingId, 'position': position, 'path': path};
      attempt.stage('reservation_insert');
      try {
        await client.from('kibo_listing_photos').insert(row);
      } on PostgrestException catch (error) {
        if (error.code != '23505') rethrow;
        attempt.stage('reservation_lookup');
        final existing = await client
            .from('kibo_listing_photos')
            .select('path')
            .eq('listing_id', listingId)
            .eq('position', position)
            .single();
        if (existing['path'] != path) {
          throw StateError('Emplacement photo déjà occupé.');
        }
      }
      attempt.stage('session');
      _check(owner);
      attempt.stage('edge_invoke');
      final response = await client.functions.invoke(
        'kibo-upload-listing-photo',
        body: {
          'listingId': listingId,
          'position': position,
          'digest': photo.digest,
          'base64': base64Encode(photo.bytes),
        },
      );
      attempt.stage('response_confirmation', keepResponse: true);
      if (response.data is! Map ||
          response.data['path'] != path ||
          response.data['ok'] != true) {
        throw StateError('Téléversement non confirmé.');
      }
      attempt.stage('session');
      _check(owner);
    }
  });

  @override
  Future<String> signedUrl(String path) =>
      client.storage.from(listingPhotoBucket).createSignedUrl(path, 60);
}
