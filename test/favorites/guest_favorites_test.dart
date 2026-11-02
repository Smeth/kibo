import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/supabase/secure_session_storage.dart';
import 'package:kibo/features/favorites/guest_favorites.dart';
import 'package:kibo/features/favorites/favorites_controller.dart';
import '../support/guest_favorites_fake.dart';
import '../support/listing_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemoryGuestFavoritesStore store;
  late FakeListingRepository listings;
  late GuestFavoritesController guest;
  setUp(() {
    store = MemoryGuestFavoritesStore();
    listings = FakeListingRepository();
    guest = GuestFavoritesController(store, listings);
    FlutterSecureStorage.setMockInitialValues({});
  });
  tearDown(() => guest.dispose());

  test(
    'ajout/retrait local et restauration par un nouveau contrôleur',
    () async {
      await guest.initialize();
      expect(await guest.toggle('listing-a'), true);
      final restarted = GuestFavoritesController(store, listings);
      addTearDown(restarted.dispose);
      await restarted.initialize();
      expect(restarted.ids, {'listing-a'});
      expect(restarted.items.single.id, 'listing-a');
      expect(await restarted.toggle('listing-a'), true);
      expect(store.saved, isEmpty);
    },
  );
  test(
    'API stockage simulée : redémarrage, projet distinct et logout isolés',
    () async {
      final first = SecureGuestFavoritesStore(projectHost: 'a.invalid');
      await first.write({'listing-a'});
      final session = SecureSessionStorage(projectHost: 'a.invalid');
      await session.persistSession('session-fictive');
      await session.removePersistedSession();
      expect(await SecureGuestFavoritesStore(projectHost: 'a.invalid').read(), {
        'listing-a',
      });
      expect(
        await SecureGuestFavoritesStore(projectHost: 'b.invalid').read(),
        isEmpty,
      );
    },
  );
  test('stockage corrompu conservé sans écriture automatique', () async {
    FlutterSecureStorage.setMockInitialValues({
      'kibo.guestFavorites.v1.a.invalid': '{broken',
    });
    final storage = SecureGuestFavoritesStore(projectHost: 'a.invalid');
    await expectLater(storage.read(), throwsFormatException);
    expect(
      await const FlutterSecureStorage().read(
        key: 'kibo.guestFavorites.v1.a.invalid',
      ),
      '{broken',
    );
  });
  test('échec lecture : aucun ajout écrasant la sélection existante', () async {
    store.readError = Exception('private');
    await guest.initialize();
    expect(guest.ready, false);
    expect(await guest.toggle('listing-a'), false);
    expect(store.writes, 0);
    expect(guest.error, isNot(contains('private')));
    store.readError = null;
    await guest.initialize();
    expect(await guest.toggle('listing-a'), true);
  });
  test('écriture échouée et double pression : pas de faux succès', () async {
    await guest.initialize();
    store.pendingWrite = Completer<void>();
    final operation = guest.toggle('listing-a');
    expect(await guest.toggle('listing-b'), false);
    store.writeError = Exception('private');
    store.pendingWrite!.complete();
    expect(await operation, false);
    expect(guest.ids, isEmpty);
    expect(guest.error, isNot(contains('private')));
  });
  test(
    'annonce retirée masquée, identifiant conservé ; hors réseau sans perte',
    () async {
      store.saved = {'listing-a', 'hidden'};
      await guest.initialize();
      expect(guest.items.map((r) => r.id), ['listing-a']);
      expect(guest.ids, {'listing-a', 'hidden'});
      listings.readError = Exception('offline');
      await guest.refresh();
      expect(guest.items, isEmpty);
      expect(guest.ids, {'listing-a', 'hidden'});
      expect(guest.error, contains('connexion'));
      listings.readError = null;
      await guest.refresh();
      expect(guest.items.length, 1);
    },
  );
  test(
    'pagination avance même quand les vingt premiers favoris sont masqués',
    () async {
      store.saved = {...List.generate(20, (i) => 'hidden-$i'), 'listing-a'};
      await guest.initialize();
      expect(guest.items, isEmpty);
      expect(guest.hasMore, true);
      await guest.refresh(append: true);
      expect(guest.items.single.id, 'listing-a');
      expect(guest.hasMore, false);
    },
  );

  test(
    'ajout hors réseau persistant, retrait sans décaler la pagination',
    () async {
      store.saved = {...List.generate(20, (i) => 'hidden-$i'), 'listing-a'};
      await guest.initialize();
      listings.readError = Exception('offline');
      expect(await guest.toggle('listing-b'), true);
      expect(store.saved.contains('listing-b'), true);
      expect(await guest.toggle('hidden-0'), true);
      listings.readError = null;
      await guest.refresh(append: true);
      expect(guest.items.map((r) => r.id), ['listing-a', 'listing-b']);
      expect(guest.hasMore, false);
    },
  );

  Future<FavoritesController> connected() async {
    await guest.initialize();
    final repository = FakeFavoritesRepository(listings: listings);
    final account = FavoritesController(repository, guest: guest);
    addTearDown(account.dispose);
    account.bindUser(repository.userId);
    await Future<void>.delayed(Duration.zero);
    return account;
  }

  test(
    'connexion ne transfère rien ; refus et mauvais compte sans écriture',
    () async {
      store.saved = {'listing-a'};
      final account = await connected();
      final remote = account.repository as FakeFavoritesRepository;
      expect(account.offersTransfer, true);
      expect(remote.adds, 0);
      account.dismissTransfer();
      expect(account.offersTransfer, false);
      await account.importGuestFavorites(
        expectedOwner: 'other',
        expectedRevision: account.sessionRevision,
      );
      expect(remote.adds, 0);
      expect(store.saved, {'listing-a'});
    },
  );
  test('transfert confirmé dédupliqué ; favoris du compte conservés', () async {
    store.saved = {'listing-a', 'listing-b'};
    final account = await connected();
    final remote = account.repository as FakeFavoritesRepository;
    remote.saved = {'listing-a', 'listing-c'};
    await account.importGuestFavorites(
      expectedOwner: remote.userId!,
      expectedRevision: account.sessionRevision,
    );
    expect(remote.adds, 1);
    expect(remote.saved, {'listing-a', 'listing-b', 'listing-c'});
    expect(store.saved, isEmpty);
    expect(account.ids, remote.saved);
  });
  test(
    'transfert partiel : seul le favori confirmé quitte le stockage local',
    () async {
      store.saved = {'listing-a', 'hidden'};
      await guest.initialize();
      final remote = _SelectiveFavorites(listings: listings);
      final account = FavoritesController(remote, guest: guest);
      addTearDown(account.dispose);
      account.bindUser(remote.userId);
      await Future<void>.delayed(Duration.zero);
      await account.importGuestFavorites(
        expectedOwner: remote.userId!,
        expectedRevision: account.sessionRevision,
      );
      expect(remote.saved, {'listing-a'});
      expect(store.saved, {'hidden'});
      expect(account.error, contains('incomplet'));
    },
  );
  test(
    'écriture locale échouée après transfert : sélection conservée, reprise sans doublon',
    () async {
      store.saved = {'listing-a'};
      final account = await connected();
      final remote = account.repository as FakeFavoritesRepository;
      store.writeError = Exception('disk');
      await account.importGuestFavorites(
        expectedOwner: remote.userId!,
        expectedRevision: account.sessionRevision,
      );
      expect(store.saved, {'listing-a'});
      expect(remote.saved, {'listing-a'});
      expect(account.error, contains('incomplet'));
      store.writeError = null;
      await account.importGuestFavorites(
        expectedOwner: remote.userId!,
        expectedRevision: account.sessionRevision,
      );
      expect(store.saved, isEmpty);
      expect(remote.adds, 1);
    },
  );
  test('accord périmé après aller-retour A/B/A : aucune écriture', () async {
    store.saved = {'listing-a'};
    final account = await connected();
    final remote = account.repository as FakeFavoritesRepository;
    final original = account.sessionRevision;
    remote.userId = 'user-b';
    account.bindUser('user-b');
    remote.userId = 'test-user-a';
    account.bindUser('test-user-a');
    await Future<void>.delayed(Duration.zero);
    await account.importGuestFavorites(
      expectedOwner: remote.userId!,
      expectedRevision: original,
    );
    expect(remote.adds, 0);
    expect(store.saved, {'listing-a'});
  });
  test(
    'transfert échoué conserve la sélection locale sans effacer le compte',
    () async {
      store.saved = {'listing-a'};
      final account = await connected();
      final remote = account.repository as FakeFavoritesRepository;
      remote.failure = Exception('private');
      await account.importGuestFavorites(
        expectedOwner: remote.userId!,
        expectedRevision: account.sessionRevision,
      );
      expect(store.saved, {'listing-a'});
      expect(account.error, contains('conservés'));
    },
  );
  test(
    'changement de compte pendant transfert : aucune écriture dans B',
    () async {
      store.saved = {'listing-a', 'listing-b'};
      final account = await connected();
      final remote = account.repository as FakeFavoritesRepository;
      remote.pending = Completer<void>();
      final operation = account.importGuestFavorites(
        expectedOwner: remote.userId!,
        expectedRevision: account.sessionRevision,
      );
      await Future<void>.delayed(Duration.zero);
      expect(remote.adds, 1);
      // Le fake capture ici le compte A comme le vrai repository capture user_id.
      remote.failure = Exception('session changed');
      remote.userId = 'user-b';
      account.bindUser('user-b');
      remote.pending!.complete();
      await operation;
      expect(remote.adds, 1);
      expect(store.saved, {'listing-a', 'listing-b'});
      expect(remote.saved, isEmpty);
    },
  );
}

class _SelectiveFavorites extends FakeFavoritesRepository {
  _SelectiveFavorites({required super.listings});
  @override
  Future<void> add(String id, String expectedUserId) async {
    if (id == 'hidden') throw StateError('Annonce non publique');
    await super.add(id, expectedUserId);
  }
}
