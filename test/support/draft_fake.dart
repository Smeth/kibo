import 'package:kibo/features/listings/listing_draft_store.dart';

class MemoryListingDraftStore implements ListingDraftStore {
  final values = <String, ListingDraftSnapshot>{};
  @override
  Future<ListingDraftSnapshot?> read(String owner) async => values[owner];
  @override
  Future<void> write(String owner, ListingDraftSnapshot value) async {
    values[owner] = value;
  }

  @override
  Future<void> clear(String owner) async {
    values.remove(owner);
  }
}
