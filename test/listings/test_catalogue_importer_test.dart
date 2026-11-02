import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/features/development/test_catalogue_importer.dart';
import 'package:kibo/features/listings/listing_photos.dart';
import 'package:kibo/core/diagnostics/operation_id.dart';

class Gateway implements TestCatalogueGateway {
  @override
  String? userId = 'dedicated-owner';
  int preflights = 0, publishes = 0, uploads = 0;
  bool switchAfterPublish = false;
  final ids = <String>{}, photos = <String>{};
  @override
  Future<void> preflight() async {
    preflights++;
  }

  @override
  Future<void> publish(Map<String, dynamic> row) async {
    publishes++;
    ids.add(row['id'] as String);
    if (switchAfterPublish) userId = 'other';
  }

  @override
  Future<void> attach(String id, Uint8List jpeg) async {
    expect(jpeg[0], 0xff);
    expect(jpeg[1], 0xd8);
    uploads++;
    photos.add(id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Map<String, dynamic>> rows;
  setUpAll(() async {
    rows = parseTestCatalogue(
      await rootBundle.loadString('assets/test_catalogue/catalogue.json'),
    );
  });

  test('108 annonces, neuf catégories, 432 commentaires liés et marqués', () {
    expect(rows, hasLength(108));
    expect(rows.map((r) => r['category']).toSet(), hasLength(9));
    final ids = <String>{};
    for (final row in rows) {
      expect(isOperationId(row['id'] as String), isTrue);
      final comments = (row['comments'] as List).cast<Map<String, dynamic>>();
      expect(comments, hasLength(4));
      final roots = comments
          .where((c) => c['parent_id'] == null)
          .map((c) => c['id'])
          .toSet();
      expect(roots, hasLength(2));
      for (final c in comments) {
        expect(ids.add(c['id'] as String), isTrue);
        expect((c['content'] as String).startsWith('[TEST '), isTrue);
        expect(['seller', 'buyer'], contains(c['author_role']));
        if (c['parent_id'] != null) expect(roots, contains(c['parent_id']));
      }
    }
    expect(ids, hasLength(432));
  });

  test(
    'chaque image existe, empreinte vérifiée et compression JPEG acceptée',
    () async {
      for (final row in rows) {
        final source = (await rootBundle.load(
          row['image_asset'] as String,
        )).buffer.asUint8List();
        expect(sha256.convert(source).toString(), row['image_sha256']);
        final compressed = compressListingPhoto(source);
        expect(compressed.lengthInBytes, inInclusiveRange(1, maxPhotoBytes));
        expect(compressed[0], 0xff);
        expect(compressed[1], 0xd8);
      }
    },
  );

  test('autre compte : aucune préparation et aucune écriture', () async {
    final gateway = Gateway()..userId = 'other';
    var loads = 0;
    final importer = TestCatalogueImporter(
      gateway: gateway,
      owner: 'dedicated-owner',
      loadAsset: (_) async {
        loads++;
        return Uint8List(0);
      },
    );
    await expectLater(importer.run(rows.take(2).toList()), throwsStateError);
    expect(loads, 0);
    expect(gateway.publishes, 0);
    expect(gateway.uploads, 0);
  });

  test('dernière image invalide : aucune annonce créée', () async {
    final gateway = Gateway();
    var loads = 0;
    final importer = TestCatalogueImporter(
      gateway: gateway,
      owner: 'dedicated-owner',
      loadAsset: (path) async => ++loads == 2
          ? Uint8List(3)
          : (await rootBundle.load(path)).buffer.asUint8List(),
    );
    await expectLater(
      importer.run(rows.take(2).toList()),
      throwsA(isA<PhotoValidationException>()),
    );
    expect(gateway.preflights, 0);
    expect(gateway.publishes, 0);
  });

  test(
    'changement de compte après création : upload et suite refusés',
    () async {
      final gateway = Gateway()..switchAfterPublish = true;
      final importer = TestCatalogueImporter(
        gateway: gateway,
        owner: 'dedicated-owner',
      );
      await expectLater(importer.run(rows.take(2).toList()), throwsStateError);
      expect(gateway.publishes, 1);
      expect(gateway.uploads, 0);
    },
  );

  test(
    'reprise : mêmes identifiants, une seule annonce et une photo par entrée',
    () async {
      final gateway = Gateway();
      final importer = TestCatalogueImporter(
        gateway: gateway,
        owner: 'dedicated-owner',
      );
      final sample = rows.take(2).toList();
      final progress = <int>[];
      await importer.run(
        sample,
        onProgress: (done, total) => progress.add(done),
      );
      await importer.run(sample);
      expect(gateway.ids, hasLength(2));
      expect(gateway.photos, hasLength(2));
      expect(progress, [1, 2]);
    },
  );

  test('fichier d’un autre lot rejeté', () {
    expect(
      () => parseTestCatalogue(jsonEncode({'batch': 'other'})),
      throwsFormatException,
    );
  });

  test(
    'lot de charge : 1080 annonces distinctes, 4320 commentaires et aucun chevauchement',
    () async {
      final stress = parseTestCatalogue(
        await rootBundle.loadString(
          'assets/test_catalogue/stress_catalogue.json',
        ),
      );
      expect(stress, hasLength(1080));
      final originalIds = rows.map((r) => r['id']).toSet();
      final comments = <String>{};
      for (final row in stress) {
        expect(originalIds, isNot(contains(row['id'])));
        expect(isOperationId(row['id'] as String), isTrue);
        for (final comment
            in (row['comments'] as List).cast<Map<String, dynamic>>()) {
          expect(comments.add(comment['id'] as String), isTrue);
        }
      }
      expect(comments, hasLength(4320));
      expect(stress.map((r) => r['image_asset']).toSet(), hasLength(108));
    },
  );

  test(
    'sources photo répétées décodées une seule fois et concurrence bornée',
    () async {
      final gateway = Gateway();
      var loads = 0;
      final sample = [
        rows[0],
        Map<String, dynamic>.from(rows[0])..['id'] = rows[1]['id'],
      ];
      final importer = TestCatalogueImporter(
        gateway: gateway,
        owner: 'dedicated-owner',
        parallelism: 3,
        loadAsset: (path) async {
          loads++;
          return (await rootBundle.load(path)).buffer.asUint8List();
        },
      );
      await importer.run(sample);
      expect(loads, 1);
      expect(gateway.photos, hasLength(2));
      await expectLater(
        TestCatalogueImporter(
          gateway: gateway,
          owner: 'dedicated-owner',
          parallelism: 4,
        ).run(sample),
        throwsArgumentError,
      );
    },
  );
}
