import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/auth/auth_repository.dart';
import 'package:kibo/features/listings/listing_models.dart';
import 'package:kibo/features/listings/my_listings_page.dart';
import 'package:kibo/features/listings/owned_listing_repository.dart';
import 'package:kibo/features/listings/owned_listing_query.dart';
import 'package:kibo/core/supabase/supabase_service.dart';
import 'package:kibo/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as image;
import 'package:kibo/features/listings/edit_listing_page.dart';
import 'package:kibo/features/listings/listing_photos.dart';
import 'package:kibo/features/listings/listing_photo_widgets.dart';
import 'photo_publication_test.dart' show Photos, Picker;

import '../support/auth_fake.dart';
import '../support/listing_fake.dart';
import '../support/manrope_fonts.dart';
import '../support/supabase_fakes.dart';

class _OwnedFake implements OwnedListingRepository {
  @override
  String? userId = FakeAuthRepository.user.id;
  Object? failure;
  Completer<List<OwnedListing>>? load;
  Completer<void>? save;
  int edits = 0, transitions = 0;
  final offsets = <int>[];
  final queries = <OwnedListingQuery>[];
  final pendingLoads = <Completer<List<OwnedListing>>>[];
  List<OwnedListing> rows = [_row()];
  ListingDraft? saved;
  @override
  Future<List<OwnedListing>> mine(
    String owner, {
    int offset = 0,
    OwnedListingQuery query = const OwnedListingQuery(),
  }) async {
    offsets.add(offset);
    queries.add(query);
    if (pendingLoads.isNotEmpty) return pendingLoads.removeAt(0).future;
    if (load != null) return load!.future;
    if (failure != null) throw failure!;
    return rows
        .where((r) => r.sellerId == owner)
        .where(
          (r) =>
              query.status == OwnedListingStatus.all ||
              r.status == query.status.name,
        )
        .where(
          (r) => '${r.draft.title} ${r.draft.description}'
              .toLowerCase()
              .contains(query.text.trim().toLowerCase()),
        )
        .skip(offset)
        .take(20)
        .toList();
  }

  @override
  Future<void> edit(OwnedListing listing, ListingDraft draft) async {
    edits++;
    await save?.future;
    if (failure != null) throw failure!;
    saved = draft;
    rows = [
      OwnedListing(
        id: listing.id,
        sellerId: listing.sellerId,
        status: listing.status,
        updatedAt: 'new',
        draft: draft,
      ),
    ];
  }

  @override
  Future<void> transition(OwnedListing listing, String status) async {
    transitions++;
    await save?.future;
    if (failure != null) throw failure!;
    rows = [
      OwnedListing(
        id: listing.id,
        sellerId: listing.sellerId,
        status: status,
        updatedAt: 'new',
        draft: listing.draft,
      ),
    ];
  }
}

OwnedListing _row({String id = 'listing-a'}) => OwnedListing(
  id: id,
  sellerId: FakeAuthRepository.user.id,
  status: 'published',
  updatedAt: 'old',
  draft: const ListingDraft(
    title: 'Produit de test',
    description: 'Description du produit de test',
    price: '1000',
    categoryId: 'category-a',
    city: 'Brazzaville',
  ),
);

void main() {
  setUpAll(loadManropeFonts);
  late _OwnedFake repository;
  late FakeAuthRepository auth;
  setUp(() {
    repository = _OwnedFake();
    auth = FakeAuthRepository()..identity = FakeAuthRepository.user;
  });
  tearDown(() => auth.dispose());
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthSession(
          repository: auth,
          child: MyListingsPage(
            repository: repository,
            listings: FakeListingRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> edit(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Modifier').hitTestable(),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    final button = find.text('Enregistrer les modifications');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
  }

  testWidgets('annonce sans photo : sélection, échec et reprise idempotente', (
    tester,
  ) async {
    final photos = Photos();
    final picker = Picker()
      ..rows = [
        ListingPhotoDraft(image.encodeJpg(image.Image(width: 2, height: 2))),
      ];
    await tester.pumpWidget(
      MaterialApp(
        home: ListingPhotoScope(
          repository: photos,
          picker: picker,
          child: AuthSession(
            repository: auth,
            child: EditListingPage(
              listing: _row(),
              repository: repository,
              listings: FakeListingRepository(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aucune photo pour le moment'), findsOneWidget);
    await tester.tap(find.text('Ajouter jusqu’à 3 photos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer les photos'));
    await tester.pumpAndSettle();
    expect(photos.calls, 1);
    expect(
      find.textContaining('Ajout des photos non confirmé'),
      findsOneWidget,
    );
    expect(find.text('Annuler la sélection'), findsNothing);
    photos.fail = false;
    await tester.ensureVisible(find.text('Enregistrer les photos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer les photos'));
    await tester.pumpAndSettle();
    expect(photos.calls, 2);
    expect(photos.sent.single.digest, picker.rows.single.digest);
    expect(find.textContaining('Photos ajoutées.'), findsOneWidget);
    expect(repository.edits, 0);
  });
  testWidgets(
    'modifier avec photos existantes conserve la galerie et évite un nouvel ajout',
    (tester) async {
      final base = _row();
      final row = OwnedListing(
        id: base.id,
        sellerId: base.sellerId,
        status: base.status,
        updatedAt: base.updatedAt,
        draft: base.draft,
        photoPaths: const ['fixture-photo'],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: AuthSession(
            repository: auth,
            child: EditListingPage(
              listing: row,
              repository: repository,
              listings: FakeListingRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ListingPhotoGallery), findsOneWidget);
      expect(find.text('Ajouter jusqu’à 3 photos'), findsNothing);
      expect(find.text('Aucune photo pour le moment'), findsNothing);
    },
  );

  testWidgets(
    'suppression du catalogue explicitement archivée après confirmation',
    (tester) async {
      await open(tester);
      await tester.ensureVisible(find.text('Supprimer du catalogue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer du catalogue'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Il ne s’agit pas d’un effacement définitif'),
        findsOneWidget,
      );
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(repository.transitions, 0);
      await tester.tap(find.text('Supprimer du catalogue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retirer du catalogue'));
      await tester.pumpAndSettle();
      expect(repository.transitions, 1);
      expect(repository.rows.single.status, 'archived');
      expect(
        find.text('Annonce retirée du catalogue et archivée.'),
        findsOneWidget,
      );
    },
  );
  testWidgets('Profil ouvre Mes annonces avec la session existante', (
    tester,
  ) async {
    final client = createTestClient();
    addTearDown(client.dispose);
    await tester.pumpWidget(
      KiboApp(
        supabase: SupabaseService(
          config: testConfig,
          initializer: (_) async => client,
        ),
        authRepository: auth,
        listingRepository: FakeListingRepository(),
        ownedListingRepository: repository,
        favoritesRepository: FakeFavoritesRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mes annonces'));
    await tester.pumpAndSettle();
    expect(find.text('Produit de test'), findsOneWidget);
    expect(repository.offsets, [0]);
  });

  testWidgets('sauvegarde en cours : retour et double envoi bloqués', (
    tester,
  ) async {
    await open(tester);
    await edit(tester);
    repository.save = Completer<void>();
    await tapSave(tester);
    await tester.pump();
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Enregistrement…'),
    );
    expect(button.onPressed, isNull);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Modifier mon annonce'), findsOneWidget);
    expect(repository.edits, 1);
    repository.save!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Mes annonces'), findsOneWidget);
  });

  testWidgets('invité : aucune lecture privée', (tester) async {
    auth.identity = null;
    await open(tester);
    expect(
      find.text('Connectez-vous pour gérer vos annonces.'),
      findsOneWidget,
    );
    expect(repository.offsets, isEmpty);
  });
  testWidgets('états vide et erreur puis reprise', (tester) async {
    repository.failure = Exception('offline');
    await open(tester);
    expect(find.text('Réessayer'), findsOneWidget);
    repository.failure = null;
    repository.rows = [];
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Vous n’avez pas encore d’annonce.'), findsOneWidget);
  });
  testWidgets('pagination côté serveur par pages de vingt et actualisation', (
    tester,
  ) async {
    repository.rows = List.generate(21, (i) => _row(id: 'listing-$i'));
    await open(tester);
    await tester.scrollUntilVisible(
      find.text('Charger la suite'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Charger la suite'));
    await tester.pumpAndSettle();
    expect(repository.offsets, [0, 20]);
    expect(find.text('Charger la suite'), findsNothing);
  });

  testWidgets('filtre statut repart à zéro, état vide puis réinitialisation', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('owned-status')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archivée').last);
    await tester.pumpAndSettle();
    expect(repository.queries.last.status, OwnedListingStatus.archived);
    expect(repository.offsets, [0, 0]);
    expect(find.text('Produit de test'), findsNothing);
    expect(
      find.text('Aucune annonce ne correspond à ces critères.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('owned-status')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tous les statuts').last);
    await tester.pumpAndSettle();
    expect(find.text('Produit de test'), findsOneWidget);
  });
  testWidgets(
    'formulaire prérempli, validation, sauvegarde et liste actualisée',
    (tester) async {
      await open(tester);
      await edit(tester);
      expect(find.text('Produit de test'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('edit-listing-title')),
        '',
      );
      await tapSave(tester);
      await tester.pumpAndSettle();
      expect(repository.edits, 0);
      await tester.ensureVisible(
        find.byKey(const ValueKey('edit-listing-title')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('edit-listing-title')),
        'Produit modifié',
      );
      await tapSave(tester);
      await tester.pumpAndSettle();
      expect(repository.saved!.title, 'Produit modifié');
      expect(find.text('Mes annonces'), findsOneWidget);
      expect(find.text('Produit modifié'), findsOneWidget);
    },
  );

  testWidgets(
    'recherche et statut combinés restent actifs sur la page suivante et se réinitialisent',
    (tester) async {
      repository.rows = List.generate(21, (i) => _row(id: 'listing-$i'));
      await open(tester);
      await tester.enterText(
        find.byKey(const ValueKey('owned-search')),
        'produit',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('owned-status')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publiée').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Charger la suite'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Charger la suite'));
      await tester.pumpAndSettle();
      expect(repository.offsets, [0, 0, 0, 20]);
      expect(repository.queries.last.text, 'produit');
      expect(repository.queries.last.status, OwnedListingStatus.published);
      await tester.scrollUntilVisible(
        find.text('Rechercher'),
        -500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rechercher'));
      await tester.pumpAndSettle();
      expect(repository.offsets.last, 0);
      expect(repository.queries.last.text, 'produit');
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Réinitialiser'),
        -500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Réinitialiser'));
      await tester.pumpAndSettle();
      expect(repository.queries.last.isEmpty, true);
      expect(repository.offsets.last, 0);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('owned-search')),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final search = tester.widget<TextFormField>(
        find.byKey(const ValueKey('owned-search')),
      );
      expect(search.controller!.text, '');
      final status = tester.widget<DropdownButton<OwnedListingStatus>>(
        find.byKey(const ValueKey('owned-status')),
      );
      expect(status.value, OwnedListingStatus.all);
    },
  );

  testWidgets('une ancienne recherche ne remplace pas le dernier résultat', (
    tester,
  ) async {
    await open(tester);
    final old = Completer<List<OwnedListing>>();
    final latest = Completer<List<OwnedListing>>();
    repository.pendingLoads.addAll([old, latest]);
    await tester.enterText(
      find.byKey(const ValueKey('owned-search')),
      'ancien',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('owned-search')),
      'nouveau',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    latest.complete([]);
    await tester.pumpAndSettle();
    expect(
      find.text('Aucune annonce ne correspond à ces critères.'),
      findsOneWidget,
    );
    old.complete([_row()]);
    await tester.pumpAndSettle();
    expect(find.text('Produit de test'), findsNothing);
    expect(repository.queries.last.text, 'nouveau');
  });

  testWidgets('erreur de recherche puis reprise conserve les critères', (
    tester,
  ) async {
    await open(tester);
    repository.failure = Exception('offline');
    await tester.enterText(
      find.byKey(const ValueKey('owned-search')),
      'introuvable',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Réessayer'), findsOneWidget);
    repository.failure = null;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(repository.queries.last.text, 'introuvable');
    expect(
      find.text('Aucune annonce ne correspond à ces critères.'),
      findsOneWidget,
    );
  });

  testWidgets('recherche trop longue : validation avant toute lecture', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(
      find.byKey(const ValueKey('owned-search')),
      'a' * 121,
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(
      find.text('La recherche est limitée à 120 caractères.'),
      findsOneWidget,
    );
    expect(repository.offsets, [0]);
  });
  testWidgets(
    'erreur de sauvegarde conserve le texte sans confirmer un succès',
    (tester) async {
      await open(tester);
      await edit(tester);
      await tester.enterText(
        find.byKey(const ValueKey('edit-listing-title')),
        'Texte conservé',
      );
      repository.failure = Exception('offline');
      await tapSave(tester);
      await tester.pumpAndSettle();
      expect(find.text('Texte conservé'), findsOneWidget);
      expect(find.textContaining('Impossible d’enregistrer'), findsOneWidget);
      expect(find.text('Modifier mon annonce'), findsOneWidget);
    },
  );
  testWidgets('annulation puis vente confirmée et archivage sur le même ID', (
    tester,
  ) async {
    await open(tester);
    await tester.ensureVisible(find.text('Marquer vendue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marquer vendue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(repository.transitions, 0);
    await tester.tap(find.text('Marquer vendue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(find.text('Vendue'), findsOneWidget);
    expect(find.text('Modifier'), findsNothing);
    await tester.ensureVisible(find.text('Supprimer du catalogue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer du catalogue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retirer du catalogue'));
    await tester.pumpAndSettle();
    expect(find.text('Archivée'), findsOneWidget);
    expect(repository.rows.single.id, 'listing-a');
    expect(repository.transitions, 2);
  });
  testWidgets('refus RLS : annonce toujours publiée et aucun faux succès', (
    tester,
  ) async {
    await open(tester);
    repository.failure = const PostgrestException(
      message: 'Protected',
      code: '42501',
    );
    await tester.ensureVisible(find.text('Supprimer du catalogue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer du catalogue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retirer du catalogue'));
    await tester.pumpAndSettle();
    expect(find.text('Publiée'), findsOneWidget);
    expect(find.text('Annonce archivée.'), findsNothing);
    expect(find.textContaining('refusée par le serveur'), findsOneWidget);
  });
  testWidgets('changement de compte pendant la lecture : pas de fuite de A', (
    tester,
  ) async {
    repository.load = Completer<List<OwnedListing>>();
    await tester.pumpWidget(
      MaterialApp(
        home: AuthSession(
          repository: auth,
          child: MyListingsPage(
            repository: repository,
            listings: FakeListingRepository(),
          ),
        ),
      ),
    );
    await tester.pump();
    repository.userId = 'user-b';
    auth.emit(const AuthIdentity(id: 'user-b'));
    await tester.pump();
    repository.load!.complete([_row()]);
    await tester.pumpAndSettle();
    expect(find.text('Produit de test'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'changement de session pendant une sauvegarde : réponse ignorée',
    (tester) async {
      await open(tester);
      await edit(tester);
      repository.save = Completer<void>();
      await tapSave(tester);
      await tester.pump();
      expect(find.text('Enregistrement…'), findsOneWidget);
      repository.userId = 'user-b';
      auth.emit(const AuthIdentity(id: 'user-b'));
      await tester.pump();
      repository.save!.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('Votre session a changé'), findsOneWidget);
      expect(find.text('Enregistrer les modifications'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'petit écran et texte agrandi : actions accessibles sans débordement',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: AuthSession(
            repository: auth,
            child: MyListingsPage(
              repository: repository,
              listings: FakeListingRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await edit(tester);
      await tester.ensureVisible(find.text('Enregistrer les modifications'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
