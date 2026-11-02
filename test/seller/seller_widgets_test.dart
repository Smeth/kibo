import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/auth/auth_repository.dart';
import 'package:kibo/features/seller/seller_repository.dart';
import 'package:kibo/features/seller/seller_page.dart';
import 'package:kibo/features/seller/contact_preferences_page.dart';
import 'package:kibo/features/listings/listing_detail_page.dart';
import 'package:kibo/features/listings/listing_models.dart';
import '../support/auth_fake.dart';
import '../support/listing_fake.dart';

class _Seller extends Fake implements SellerRepository {
  @override
  String? userId = FakeAuthRepository.user.id;
  Object? failure;
  int contacts = 0, saves = 0;
  Completer<SellerContact>? pendingContact;
  Completer<void>? pendingSave;
  ContactPreferences prefs = const ContactPreferences();
  @override
  Future<PublicSeller?> profile(String id) async {
    if (failure != null) throw failure!;
    return PublicSeller(id: id, name: 'Vendeur fictif', city: 'Brazzaville');
  }

  @override
  Future<ContactPreferences> preferences(String expectedUserId) async {
    if (failure != null) throw failure!;
    return prefs;
  }

  @override
  Future<void> save(
    ContactPreferences value, {
    required String expectedUserId,
  }) async {
    saves++;
    await pendingSave?.future;
    if (failure != null) throw failure!;
    prefs = value;
  }

  @override
  Future<SellerContact> contact(
    String listingId, {
    required String expectedUserId,
  }) async {
    contacts++;
    if (failure != null) throw failure!;
    return pendingContact == null
        ? const SellerContact(phone: '+9991234567', whatsapp: '+9997654321')
        : pendingContact!.future;
  }
}

class _Launcher implements ContactLauncher {
  final opened = <Uri>[];
  bool result = true;
  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return result;
  }
}

void main() {
  late FakeAuthRepository auth;
  late _Seller repository;
  late _Launcher launcher;
  setUp(() {
    auth = FakeAuthRepository()..identity = FakeAuthRepository.user;
    repository = _Seller();
    launcher = _Launcher();
  });
  tearDown(() => auth.dispose());
  Future<void> openSeller(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthSession(
          repository: auth,
          child: SellerPage(
            sellerId: 'seller',
            listingId: 'listing-a',
            repository: repository,
            launcher: launcher,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openPreferences(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthSession(
          repository: auth,
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Coordonnées'),
                onPressed: () {
                  final controller = AuthScope.maybeOf(context)!;
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AuthScope(
                        controller: controller,
                        child: ContactPreferencesPage(
                          ownerId: FakeAuthRepository.user.id,
                          repository: repository,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coordonnées'));
    await tester.pumpAndSettle();
  }

  testWidgets('visiteur voit le profil, aucun numero ni RPC ni application', (
    tester,
  ) async {
    auth.identity = null;
    repository.userId = null;
    await openSeller(tester);
    expect(find.text('Vendeur fictif'), findsOneWidget);
    expect(find.text('Brazzaville'), findsOneWidget);
    await tester.tap(find.text('Appeler le vendeur'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Connectez-vous'), findsOneWidget);
    expect(repository.contacts, 0);
    expect(launcher.opened, isEmpty);
    expect(find.textContaining('+999'), findsNothing);
  });
  testWidgets(
    'membre ouvre tel/WhatsApp sur clic explicite avec lecture fraiche',
    (tester) async {
      await openSeller(tester);
      expect(repository.contacts, 0);
      await tester.tap(find.text('Appeler le vendeur'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Contacter sur WhatsApp'));
      await tester.pumpAndSettle();
      expect(repository.contacts, 2);
      expect(launcher.opened.map((uri) => uri.toString()), [
        'tel:+9991234567',
        'https://wa.me/9997654321',
      ]);
    },
  );
  testWidgets('application absente et erreur ne donnent pas de faux succes', (
    tester,
  ) async {
    launcher.result = false;
    await openSeller(tester);
    await tester.tap(find.text('Contacter sur WhatsApp'));
    await tester.pumpAndSettle();
    expect(find.textContaining('application compatible'), findsOneWidget);
    repository.failure = Exception('private');
    await tester.tap(find.text('Appeler le vendeur'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Contact indisponible'), findsOneWidget);
    expect(find.textContaining('private'), findsNothing);
  });
  testWidgets('session changee pendant lecture de contact : aucune ouverture', (
    tester,
  ) async {
    await openSeller(tester);
    repository.pendingContact = Completer<SellerContact>();
    await tester.tap(find.text('Appeler le vendeur'));
    await tester.pump();
    repository.userId = 'user-b';
    auth.emit(const AuthIdentity(id: 'user-b'));
    await tester.pump();
    repository.pendingContact!.complete(
      const SellerContact(phone: '+9991234567'),
    );
    await tester.pumpAndSettle();
    expect(launcher.opened, isEmpty);
  });
  testWidgets(
    'preferences desactivees, validation, consentement explicite et sauvegarde',
    (tester) async {
      await openPreferences(tester);
      expect(
        tester
            .widgetList<SwitchListTile>(find.byType(SwitchListTile))
            .every((s) => !s.value),
        true,
      );
      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pumpAndSettle();
      final save = find.text('Enregistrer mes préférences');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repository.saves, 0);
      await tester.ensureVisible(find.byKey(const ValueKey('contact-phone')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('contact-phone')),
        '+9991234567',
      );
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repository.prefs.callsEnabled, true);
      expect(repository.prefs.whatsappEnabled, false);
      expect(find.text('Coordonnées'), findsOneWidget);
    },
  );
  testWidgets(
    'echec conserve la saisie puis changement A/B/A invalide le formulaire',
    (tester) async {
      await openPreferences(tester);
      await tester.enterText(
        find.byKey(const ValueKey('contact-phone')),
        '+9991234567',
      );
      repository.failure = Exception('offline');
      await tester.ensureVisible(find.text('Enregistrer mes préférences'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer mes préférences'));
      await tester.pumpAndSettle();
      expect(find.textContaining('saisies sont conservées'), findsOneWidget);
      repository.userId = 'user-b';
      auth.emit(const AuthIdentity(id: 'user-b'));
      await tester.pump();
      repository.userId = FakeAuthRepository.user.id;
      auth.emit(FakeAuthRepository.user);
      await tester.pumpAndSettle();
      expect(find.textContaining('Votre session a changé'), findsOneWidget);
      expect(find.byKey(const ValueKey('contact-phone')), findsNothing);
    },
  );
  testWidgets('sauvegarde bloquante : retour et double envoi impossibles', (
    tester,
  ) async {
    await openPreferences(tester);
    repository.pendingSave = Completer<void>();
    await tester.ensureVisible(find.text('Enregistrer mes préférences'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer mes préférences'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Enregistrement…'),
          )
          .onPressed,
      isNull,
    );
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Mes coordonnées de contact'), findsOneWidget);
    expect(repository.saves, 1);
    repository.pendingSave!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Coordonnées'), findsOneWidget);
  });
  testWidgets('detail donne acces au profil public et contact', (tester) async {
    final listings = FakeListingRepository()
      ..listings = const [
        PublicListing(
          id: 'listing-a',
          sellerId: 'seller',
          title: 'Annonce fictive',
          description: 'Description fictive de test',
          price: '1000',
          city: 'Brazzaville',
        ),
      ];
    await tester.pumpWidget(
      MaterialApp(
        home: AuthSession(
          repository: auth,
          child: ListingDetailPage(
            id: 'listing-a',
            repository: listings,
            sellers: repository,
            contactLauncher: launcher,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byTooltip('Voir le vendeur et le contacter'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Voir le vendeur et le contacter'));
    await tester.pumpAndSettle();
    expect(find.text('Vendeur fictif'), findsOneWidget);
    await tester.tap(find.text('Appeler le vendeur'));
    await tester.pumpAndSettle();
    expect(launcher.opened.length, 1);
  });
  testWidgets(
    'echec de lecture des preferences bloque toute ecriture puis reprise',
    (tester) async {
      repository.failure = Exception('offline');
      await openPreferences(tester);
      await tester.ensureVisible(find.text('Enregistrer mes préférences'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Enregistrer mes préférences'),
            )
            .onPressed,
        isNull,
      );
      expect(repository.saves, 0);
      repository.failure = null;
      await tester.ensureVisible(find.text('Actualiser les coordonnées'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Actualiser les coordonnées'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Enregistrer mes préférences'),
            )
            .onPressed,
        isNotNull,
      );
    },
  );
  testWidgets('consentement absent : aucun numero ni application ouverte', (
    tester,
  ) async {
    repository.pendingContact = Completer<SellerContact>()
      ..complete(const SellerContact());
    await openSeller(tester);
    await tester.tap(find.text('Appeler le vendeur'));
    await tester.pumpAndSettle();
    expect(find.textContaining('n’a pas activé'), findsOneWidget);
    expect(launcher.opened, isEmpty);
  });
  testWidgets('preferences sur 320 px et texte 150 % restent accessibles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openPreferences(tester);
    await tester.ensureVisible(find.text('Enregistrer mes préférences'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
