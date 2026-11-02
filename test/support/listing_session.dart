import 'dart:convert';

Map<String, dynamic> listingTestSession() {
  String encode(Map<String, dynamic> data) =>
      base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
  final expiry = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
  return {
    'access_token':
        '${encode({'alg': 'HS256'})}.${encode({'exp': expiry})}.fictif',
    'refresh_token': 'fictif',
    'expires_in': 3600,
    'token_type': 'bearer',
    'user': {
      'id': 'user-a',
      'aud': 'authenticated',
      'created_at': '2026-01-01T00:00:00Z',
      'app_metadata': {},
      'user_metadata': {},
    },
  };
}
