import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/features/seller/seller_repository.dart';
import 'package:kibo/features/comments/comments_repository.dart';
import '../test/support/auth_fake.dart';

class PreviewSeller extends Fake implements SellerRepository {
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

class PreviewLauncher implements ContactLauncher {
  final opened = <Uri>[];
  bool result = true;
  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return result;
  }
}

class PreviewComments extends Fake implements CommentsRepository {
  @override
  String? userId = FakeAuthRepository.user.id;
  Object? failure;
  Completer<void>? pending;
  int creates = 0;
  String? sentParent;
  List<ListingComment> rows = [];
  @override
  Future<List<ListingComment>> read(
    String listingId, {
    String? parentId,
    int offset = 0,
  }) async {
    if (failure != null) throw failure!;
    return rows
        .where((r) => r.parentId == parentId)
        .skip(offset)
        .take(20)
        .toList();
  }

  @override
  Future<void> create(
    String listingId,
    String content, {
    required String expectedUserId,
    String? parentId,
  }) async {
    creates++;
    sentParent = parentId;
    await pending?.future;
    if (failure != null) throw failure!;
    rows.add(
      ListingComment(
        id: 'comment-$creates',
        userId: expectedUserId,
        content: content.trim(),
        parentId: parentId,
        createdAt: DateTime(2026, 11, 1),
      ),
    );
  }
}
