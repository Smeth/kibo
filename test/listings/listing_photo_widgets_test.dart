import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/features/listings/listing_models.dart';
import 'package:kibo/features/listings/listing_feed.dart';
import 'package:kibo/features/listings/listing_photos.dart';
import 'package:kibo/features/listings/listing_photo_widgets.dart';
import '../support/listing_fake.dart';

class Reader implements ListingPhotoRepository {
  final requests = <String>[];
  Completer<String>? pending;
  @override
  bool get enabled => true;
  @override
  Future<void> attach(
    String id,
    List<ListingPhotoDraft> photos,
    String owner,
  ) async {}
  @override
  Future<String> signedUrl(String path) async {
    requests.add(path);
    if (pending != null) return pending!.future;
    throw StateError('fixture inaccessible');
  }
}

class NoPicker implements ListingPhotoPicker {
  @override
  Future<List<ListingPhotoDraft>> pick(String owner) async => [];
  @override
  Future<List<ListingPhotoDraft>> recover(String owner) async => [];
}

void main() {
  test('ordre des chemins relu depuis les métadonnées, sans URL publique', () {
    final listing = PublicListing.fromJson({
      'id': 'a',
      'title': 'Titre',
      'description': 'Description',
      'price': 1000,
      'city': 'Brazzaville',
      'listing_type': 'product',
      'status': 'published',
      'currency': 'XAF',
      'photos': [
        {'position': 1, 'path': 'second.jpg'},
        {'position': 0, 'path': 'first.jpg'},
      ],
    });
    expect(listing.photoPaths, ['first.jpg', 'second.jpg']);
  });
  testWidgets('erreur photo masquée, reprise et chargement distincts', (
    tester,
  ) async {
    final reader = Reader();
    await tester.pumpWidget(
      MaterialApp(
        home: ListingPhotoScope(
          repository: reader,
          picker: NoPicker(),
          child: const Scaffold(
            body: SizedBox(
              height: 150,
              child: ListingPhotoView(path: 'photo.jpg', label: 'Photo'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Recharger la photo'), findsOneWidget);
    expect(find.textContaining('fixture'), findsNothing);
    reader.pending = Completer<String>();
    await tester.tap(find.byTooltip('Recharger la photo'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    reader.pending!.completeError(StateError('fixture'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Recharger la photo'), findsOneWidget);
    expect(reader.requests, ['photo.jpg', 'photo.jpg']);
  });
  testWidgets('la navigation catalogue -> détail conserve le service photos', (
    tester,
  ) async {
    final reader = Reader();
    final listings = FakeListingRepository()
      ..listings = [
        const PublicListing(
          id: 'a',
          title: 'Annonce photographiée',
          description: 'Description photographiée',
          price: '1000',
          city: 'Brazzaville',
          photoPaths: ['first.jpg', 'second.jpg'],
        ),
      ];
    await tester.pumpWidget(
      MaterialApp(
        home: ListingPhotoScope(
          repository: reader,
          picker: NoPicker(),
          child: Scaffold(body: ListingFeed(repository: listings)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(reader.requests, ['first.jpg']);
    await tester.tap(find.text('Annonce photographiée'));
    await tester.pumpAndSettle();
    expect(reader.requests, ['first.jpg', 'first.jpg', 'second.jpg']);
    expect(find.byTooltip('Recharger la photo'), findsOneWidget);
    await tester.tap(find.byTooltip('Photo suivante'));
    await tester.pumpAndSettle();
    expect(find.text('Photo 2 sur 2'), findsOneWidget);
    expect(find.byTooltip('Recharger la photo'), findsOneWidget);
  });
}
