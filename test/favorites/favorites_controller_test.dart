import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/features/favorites/favorites_controller.dart';
import '../support/listing_fake.dart';

void main() {
  late FakeFavoritesRepository repository;
  late FavoritesController controller;
  Future<void> flush() => Future<void>.delayed(Duration.zero);
  setUp(() {
    repository = FakeFavoritesRepository();
    controller = FavoritesController(repository);
  });
  tearDown(() {
    controller.dispose();
  });
  test(
    'session expirée sans événement immédiat : chargement libéré et données effacées',
    () async {
      repository.pendingIds = Completer<Set<String>>();
      controller.bindUser('test-user-a');
      repository.userId = null;
      repository.pendingIds!.complete({'listing-a'});
      await flush();
      expect(controller.owner, isNull);
      expect(controller.ids, isEmpty);
      expect(controller.busy, isFalse);
    },
  );
  test(
    'visiteur sans lecture/écriture, puis ajout retrait et liste cohérents',
    () async {
      expect(await controller.toggle('listing-a'), isFalse);
      expect(repository.adds, 0);
      controller.bindUser('test-user-a');
      await flush();
      expect(await controller.toggle('listing-a'), isTrue);
      expect(controller.ids, {'listing-a'});
      expect(controller.items.single.id, 'listing-a');
      expect(await controller.toggle('listing-a'), isTrue);
      expect(controller.ids, isEmpty);
      expect(controller.items, isEmpty);
    },
  );
  test('double action bloquée et erreur masquée sans faux succès', () async {
    controller.bindUser('test-user-a');
    await flush();
    repository.pending = Completer<void>();
    final operation = controller.toggle('listing-a');
    expect(await controller.toggle('listing-a'), isFalse);
    expect(repository.adds, 1);
    repository.failure = StateError('détail privé');
    repository.pending!.complete();
    expect(await operation, isFalse);
    expect(controller.ids, isEmpty);
    expect(controller.error, isNot(contains('privé')));
    expect(controller.busy, isFalse);
    repository.failure = null;
    repository.pending = null;
    await controller.refresh();
    expect(await controller.toggle('listing-a'), isTrue);
  });
  test(
    'résultat de lecture ancien ignoré après changement de compte',
    () async {
      final pending = Completer<Set<String>>();
      repository.pendingIds = pending;
      controller.bindUser('test-user-a');
      repository.pendingIds = null;
      repository.userId = 'user-b';
      repository.saved = {'listing-b'};
      controller.bindUser('user-b');
      await flush();
      pending.complete({'listing-a'});
      await flush();
      expect(controller.ids, {'listing-b'});
      expect(controller.items.single.id, 'listing-b');
    },
  );
  test(
    'déconnexion pendant écriture : aucun favori privé réintroduit',
    () async {
      controller.bindUser('test-user-a');
      await flush();
      repository.pending = Completer<void>();
      final operation = controller.toggle('listing-a');
      repository.userId = null;
      controller.bindUser(null);
      repository.pending!.complete();
      expect(await operation, isFalse);
      expect(controller.ids, isEmpty);
      expect(controller.items, isEmpty);
      expect(controller.owner, isNull);
    },
  );
  test(
    'erreur de chargement, retry, et annonce retirée sans suppression du favori',
    () async {
      repository.failure = StateError('privé');
      controller.bindUser('test-user-a');
      await flush();
      expect(controller.loaded, isFalse);
      expect(controller.error, contains('Impossible'));
      repository.failure = null;
      repository.saved = {'hidden-listing'};
      await controller.refresh();
      expect(controller.loaded, isTrue);
      expect(controller.items, isEmpty);
      expect(controller.ids, {'hidden-listing'});
      expect(repository.removes, 0);
    },
  );
}
