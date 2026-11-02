import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

String normalizeContactNumber(String value) =>
    value.trim().replaceAll(RegExp(r'[\s().-]'), '');
String? validateContactNumber(String value, {required bool enabled}) {
  final number = normalizeContactNumber(value);
  if (number.isEmpty && !enabled) return null;
  return RegExp(r'^\+[1-9][0-9]{1,14}$').hasMatch(number)
      ? null
      : 'Utilisez le format international, par exemple +242…';
}

class PublicSeller {
  const PublicSeller({
    required this.id,
    required this.name,
    required this.city,
  });
  final String id, name, city;
}

class ContactPreferences {
  const ContactPreferences({
    this.phone = '',
    this.whatsapp = '',
    this.callsEnabled = false,
    this.whatsappEnabled = false,
    this.updatedAt,
  });
  final String phone, whatsapp;
  final bool callsEnabled, whatsappEnabled;
  final String? updatedAt;
  factory ContactPreferences.fromJson(Map<String, dynamic> row) =>
      ContactPreferences(
        phone: row['phone_e164'] as String? ?? '',
        whatsapp: row['whatsapp_e164'] as String? ?? '',
        callsEnabled: row['calls_enabled'] as bool,
        whatsappEnabled: row['whatsapp_enabled'] as bool,
        updatedAt: row['updated_at'] as String,
      );
}

class SellerContact {
  const SellerContact({this.phone, this.whatsapp});
  final String? phone, whatsapp;
}

abstract interface class SellerRepository {
  String? get userId;
  Future<PublicSeller?> profile(String id);
  Future<ContactPreferences> preferences(String expectedUserId);
  Future<void> save(ContactPreferences value, {required String expectedUserId});
  Future<SellerContact> contact(
    String listingId, {
    required String expectedUserId,
  });
}

abstract interface class ContactLauncher {
  Future<bool> open(Uri uri);
}

class DeviceContactLauncher implements ContactLauncher {
  @override
  Future<bool> open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}

Uri callUri(String number) {
  if (validateContactNumber(number, enabled: true) != null) {
    throw ArgumentError('Numéro invalide.');
  }
  return Uri(scheme: 'tel', path: normalizeContactNumber(number));
}

Uri whatsappUri(String number) {
  if (validateContactNumber(number, enabled: true) != null) {
    throw ArgumentError('Numéro invalide.');
  }
  return Uri.https('wa.me', '/${normalizeContactNumber(number).substring(1)}');
}

class SupabaseSellerRepository implements SellerRepository {
  SupabaseSellerRepository(this.client);
  final SupabaseClient client;
  @override
  String? get userId {
    final session = client.auth.currentSession;
    return session == null || session.isExpired ? null : session.user.id;
  }

  void _check(String expected) {
    if (userId == null || userId != expected) {
      throw StateError('Session modifiée.');
    }
  }

  @override
  Future<PublicSeller?> profile(String id) async {
    final rows = await client
        .from('profiles')
        .select('id,full_name,city')
        .eq('id', id)
        .limit(1);
    if (rows.isEmpty) return null;
    final r = rows.single;
    if (r['id'] != id) throw StateError('Profil inattendu.');
    return PublicSeller(
      id: id,
      name: (r['full_name'] as String?)?.trim().isNotEmpty == true
          ? r['full_name'] as String
          : 'Vendeur KIBO',
      city: r['city'] as String,
    );
  }

  static const _columns =
      'owner_id,phone_e164,whatsapp_e164,calls_enabled,whatsapp_enabled,updated_at';
  @override
  Future<ContactPreferences> preferences(String expectedUserId) async {
    _check(expectedUserId);
    final rows = await client
        .from('kibo_seller_contacts')
        .select(_columns)
        .eq('owner_id', expectedUserId)
        .limit(1);
    _check(expectedUserId);
    if (rows.isEmpty) return const ContactPreferences();
    if (rows.single['owner_id'] != expectedUserId) {
      throw StateError('Propriétaire inattendu.');
    }
    return ContactPreferences.fromJson(rows.single);
  }

  @override
  Future<void> save(
    ContactPreferences value, {
    required String expectedUserId,
  }) async {
    _check(expectedUserId);
    if (validateContactNumber(value.phone, enabled: value.callsEnabled) !=
            null ||
        validateContactNumber(value.whatsapp, enabled: value.whatsappEnabled) !=
            null) {
      throw ArgumentError('Coordonnées invalides.');
    }
    final phone = normalizeContactNumber(value.phone),
        whatsapp = normalizeContactNumber(value.whatsapp);
    final body = <String, dynamic>{
      'phone_e164': phone.isEmpty ? null : phone,
      'whatsapp_e164': whatsapp.isEmpty ? null : whatsapp,
      'calls_enabled': value.callsEnabled,
      'whatsapp_enabled': value.whatsappEnabled,
    };
    final rows = value.updatedAt == null
        ? await client
              .from('kibo_seller_contacts')
              .insert({'owner_id': expectedUserId, ...body})
              .select(_columns)
        : await client
              .from('kibo_seller_contacts')
              .update(body)
              .eq('owner_id', expectedUserId)
              .eq('updated_at', value.updatedAt!)
              .select(_columns);
    _check(expectedUserId);
    if (rows.length != 1 ||
        rows.single['owner_id'] != expectedUserId ||
        body.entries.any((entry) => rows.single[entry.key] != entry.value) ||
        DateTime.tryParse(rows.single['updated_at']?.toString() ?? '') ==
            null) {
      throw StateError('Enregistrement non confirmé.');
    }
  }

  @override
  Future<SellerContact> contact(
    String listingId, {
    required String expectedUserId,
  }) async {
    _check(expectedUserId);
    final rows = await client.rpc(
      'kibo_listing_seller_contact',
      params: {'p_listing_id': listingId},
    );
    _check(expectedUserId);
    if (rows is! List || rows.length > 1) {
      throw StateError('Contact indisponible.');
    }
    if (rows.isEmpty) return const SellerContact();
    final row = rows.single as Map<String, dynamic>;
    final phone = row['phone_e164'] as String?,
        whatsapp = row['whatsapp_e164'] as String?;
    for (final number in [phone, whatsapp]) {
      if (number != null &&
          validateContactNumber(number, enabled: true) != null) {
        throw StateError('Contact invalide.');
      }
    }
    return SellerContact(phone: phone, whatsapp: whatsapp);
  }
}
