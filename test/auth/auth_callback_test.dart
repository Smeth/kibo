import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/config/auth_callback.dart';

void main() {
  test('seul le callback KIBO PKCE ou son erreur sont acceptés', () {
    for (final suffix in [
      '?code=fictif',
      '?error=access_denied',
      '?error_code=otp_expired',
      '#error=access_denied&error_description=expired',
    ]) {
      expect(
        KiboAuthCallback.accepts(
          Uri.parse('${KiboAuthCallback.redirectUrl}$suffix'),
        ),
        isTrue,
      );
    }
    for (final link in [
      KiboAuthCallback.redirectUrl,
      '${KiboAuthCallback.redirectUrl}?code=',
      '${KiboAuthCallback.redirectUrl}?code=a&code=b',
      '${KiboAuthCallback.redirectUrl}?code=a#access_token=fictif',
      '${KiboAuthCallback.redirectUrl}?code=a&access_token=fictif',
      '${KiboAuthCallback.redirectUrl}#access_token=fictif&refresh_token=fictif',
      'https://auth/confirm?code=fictif',
      'com.kibo.kibo://other/confirm?code=fictif',
      'com.kibo.kibo://auth/other?code=fictif',
      'com.kibo.kibo://auth/confirm/extra?code=fictif',
      'com.kibo.kibo://user@auth/confirm?code=fictif',
      'com.kibo.kibo://auth:123/confirm?code=fictif',
    ]) {
      expect(KiboAuthCallback.accepts(Uri.parse(link)), isFalse, reason: link);
    }
  });
}
