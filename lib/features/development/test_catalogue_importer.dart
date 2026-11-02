import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../listings/listing_models.dart';
import '../listings/listing_photos.dart';
import '../listings/listing_repository.dart';
import '../../core/diagnostics/operation_id.dart';

const testCatalogueBatch = 'kibo-demo-20261102-v1';

List<Map<String, dynamic>> parseTestCatalogue(String raw) {
  final data = jsonDecode(raw) as Map<String, dynamic>;
  const counts = {testCatalogueBatch: 108, 'kibo-stress-20261102-v1': 1080};
  final expected = counts[data['batch']];
  if (expected == null ||
      data['fixture'] != true ||
      data['country'] != 'CG' ||
      data['currency'] != 'XAF') {
    throw const FormatException('Jeu de test inattendu');
  }
  final rows = (data['listings'] as List).cast<Map<String, dynamic>>();
  if (rows.length != expected ||
      rows.map((r) => r['id']).toSet().length != expected) {
    throw const FormatException('Nombre d’annonces distinctes inattendu');
  }
  for (final row in rows) {
    if (!isOperationId(row['id'] as String) ||
        !(row['title'] as String).startsWith('[TEST ') ||
        !(row['description'] as String).contains(data['batch'] as String) ||
        !(row['image_asset'] as String).startsWith(
          'assets/test_catalogue/images/',
        ) ||
        (row['image_asset'] as String).contains('..')) {
      throw const FormatException('Annonce non identifiée comme test');
    }
    validateDraft(
      ListingDraft(
        title: row['title'] as String,
        description: row['description'] as String,
        price: row['price'] as String,
        city: row['city'] as String,
        categoryId: row['category'] as String,
        type: row['listing_type'] as String,
      ),
    );
  }
  return rows;
}

abstract interface class TestCatalogueGateway {
  String? get userId;
  Future<void> preflight();
  Future<void> publish(Map<String, dynamic> row);
  Future<void> attach(String id, Uint8List jpeg);
}

class SupabaseTestCatalogueGateway implements TestCatalogueGateway {
  SupabaseTestCatalogueGateway(this.client, this.owner)
    : listings = SupabaseListingRepository(client),
      photos = SupabaseListingPhotoRepository(client, enabled: true);
  final SupabaseClient client;
  final String owner;
  final SupabaseListingRepository listings;
  final SupabaseListingPhotoRepository photos;
  final Map<String, String> _categories = {};
  @override
  String? get userId => listings.userId;
  void _check() {
    if (owner.isEmpty || userId != owner) {
      throw StateError('Compte de test vendeur requis');
    }
  }

  @override
  Future<void> preflight() async {
    _check();
    _categories.addEntries(
      (await listings.categories()).map((c) => MapEntry(c.name, c.id)),
    );
    await photos.checkPublicationAvailability();
    _check();
  }

  @override
  Future<void> publish(Map<String, dynamic> row) async {
    _check();
    final category = _categories[row['category']];
    if (category == null) throw StateError('Catégorie absente');
    await listings.createOnce(
      ListingDraft(
        title: row['title'] as String,
        description: row['description'] as String,
        price: row['price'] as String,
        categoryId: category,
        city: row['city'] as String,
        neighborhood: row['neighborhood'] as String,
        type: row['listing_type'] as String,
      ),
      expectedUserId: owner,
      operationId: row['id'] as String,
    );
    _check();
  }

  @override
  Future<void> attach(String id, Uint8List jpeg) async {
    _check();
    await photos.attach(id, [ListingPhotoDraft(jpeg)], owner);
    _check();
  }
}

class TestCatalogueImporter {
  TestCatalogueImporter({
    required this.gateway,
    required this.owner,
    this.loadAsset,
    this.parallelism = 1,
  });
  final TestCatalogueGateway gateway;
  final String owner;
  final Future<Uint8List> Function(String)? loadAsset;
  final int parallelism;
  bool _running = false;
  Future<void> run(
    List<Map<String, dynamic>> rows, {
    void Function(int done, int total)? onProgress,
  }) async {
    if (_running) throw StateError('Import déjà en cours');
    if (parallelism < 1 || parallelism > 3) {
      throw ArgumentError('Concurrence limitée à 1–3');
    }
    void check() {
      if (owner.isEmpty || gateway.userId != owner) {
        throw StateError('Session de test modifiée');
      }
    }

    check();
    _running = true;
    try {
      // Toutes les images sont décodées/validées avant la première écriture.
      final prepared = <Uint8List>[];
      final sources = <String, Uint8List>{};
      for (final row in rows) {
        check();
        final path = row['image_asset'] as String;
        if (!sources.containsKey(path)) {
          final bytes = loadAsset == null
              ? (await rootBundle.load(path)).buffer.asUint8List()
              : await loadAsset!(path);
          sources[path] = await compute(compressListingPhoto, bytes);
        }
        prepared.add(sources[path]!);
      }
      await gateway.preflight();
      var done = 0;
      Future<void> one(int i) async {
        check();
        await gateway.publish(rows[i]);
        check();
        await gateway.attach(rows[i]['id'] as String, prepared[i]);
        check();
        done++;
        onProgress?.call(done, rows.length);
      }

      for (var start = 0; start < rows.length; start += parallelism) {
        await Future.wait([
          for (var i = start; i < rows.length && i < start + parallelism; i++)
            one(i),
        ]);
      }
    } finally {
      _running = false;
    }
  }
}
