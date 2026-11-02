import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/features/listings/listing_draft_store.dart';
import 'package:kibo/features/listings/publish_listing_page.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import '../support/auth_fake.dart';
import '../support/listing_fake.dart';

class DraftMemory implements ListingDraftStore {
  Object? readError;
  final values = <String, ListingDraftSnapshot>{};
  @override
  Future<ListingDraftSnapshot?> read(String owner) async {
    if (readError != null) throw readError!;
    return values[owner];
  }

  @override
  Future<void> write(String owner, ListingDraftSnapshot value) async {
    values[owner] = value;
  }

  @override
  Future<void> clear(String owner) async {
    values.remove(owner);
  }
}

void main() {
  testWidgets('lecture du brouillon echouee bloque publication et ecrasement', (
    tester,
  ) async {
    final store = DraftMemory()..readError = Exception('fixture disque');
    final repo = FakeListingRepository();
    final auth = FakeAuthRepository()..identity = FakeAuthRepository.user;
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        home: Scaffold(
          body: AuthSession(
            repository: auth,
            child: PublishListingPage(repository: repo, draftStore: store),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Publier l’annonce'));
    await tester.tap(find.text('Publier l’annonce'));
    await tester.pumpAndSettle();
    expect(repo.creates, 0);
    expect(store.values, isEmpty);
    expect(
      find.textContaining('restauré ou effacé explicitement'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });
  test('codec conserve le texte et ID confirme sans photos ni secret', () {
    const value = ListingDraftSnapshot({
      'title': 'Titre fictif',
      'city': 'Brazzaville',
    }, createdId: 'listing');
    final restored = ListingDraftSnapshot.decode(value.encode());
    expect(restored.fields['title'], 'Titre fictif');
    expect(restored.createdId, 'listing');
    expect(value.encode(), isNot(contains('token')));
  });
  test('codec refuse versions et champs inconnus sans ecraser', () {
    expect(
      () => ListingDraftSnapshot.decode('{"version":2,"fields":{}}'),
      throwsFormatException,
    );
    expect(
      () => ListingDraftSnapshot.decode('{"version":1,"fields":{"token":"x"}}'),
      throwsFormatException,
    );
  });
  testWidgets('restaure sauvegarde et isole les brouillons par compte', (
    tester,
  ) async {
    final store = DraftMemory()
      ..values['test-user-a'] = const ListingDraftSnapshot({
        'title': 'Titre restauré',
        'description': 'Une description restaurée',
        'price': '1000',
        'city': 'Brazzaville',
        'type': 'product',
        'category': 'category-a',
      });
    final auth = FakeAuthRepository()..identity = FakeAuthRepository.user;
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        home: Scaffold(
          body: AuthSession(
            repository: auth,
            child: PublishListingPage(
              repository: FakeListingRepository(),
              draftStore: store,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('listing-title')))
          .controller!
          .text,
      'Titre restauré',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('listing-title')));
    await tester.enterText(
      find.byKey(const ValueKey('listing-title')),
      'Titre modifié',
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(store.values['test-user-a']!.fields['title'], 'Titre modifié');
    expect(await store.read('autre-compte'), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
