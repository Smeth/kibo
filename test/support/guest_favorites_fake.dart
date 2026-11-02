import 'dart:async';
import 'package:kibo/features/favorites/guest_favorites.dart';

class MemoryGuestFavoritesStore implements GuestFavoritesStore {
  Set<String> saved = {};
  Object? readError, writeError;
  Completer<void>? pendingWrite;
  int writes = 0;
  @override
  Future<Set<String>> read() async {
    if (readError != null) throw readError!;
    return {...saved};
  }

  @override
  Future<void> write(Set<String> ids) async {
    writes++;
    await pendingWrite?.future;
    if (writeError != null) throw writeError!;
    saved = {...ids};
  }
}
