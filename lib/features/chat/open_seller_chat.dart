import 'package:flutter/material.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_page.dart';
import 'chat_page.dart';
import 'chat_repository.dart';

Future<void> openSellerChat(
  BuildContext context, {
  required ChatRepository repository,
  required String listingId,
  required String sellerId,
}) async {
  final auth = AuthScope.maybeOf(context);
  if (auth == null) return;
  if (auth.identity == null) {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => AuthPage(controller: auth)));
  }
  if (!context.mounted) return;
  final owner = auth.identity?.id;
  if (owner == null || owner == sellerId || repository.userId != owner) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => AuthScope(
        controller: auth,
        child: ChatPage(
          repository: repository,
          ownerId: owner,
          listingId: listingId,
          sellerId: sellerId,
        ),
      ),
    ),
  );
}
