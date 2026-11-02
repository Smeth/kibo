import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/features/trust/report_target_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../support/listing_session.dart';

class _Auth extends Fake implements GoTrueClient {
  final events = StreamController<AuthState>.broadcast(sync: true);
  @override
  User? currentUser = User.fromJson(
    jsonDecode(jsonEncode(listingTestSession()['user']))
        as Map<String, dynamic>,
  );
  @override
  Stream<AuthState> get onAuthStateChange => events.stream;
}

class _Client extends Fake implements SupabaseClient {
  _Client(this.auth);
  @override
  final GoTrueClient auth;
}

void main() {
  testWidgets(
    'changement de session efface les précisions et interdit toute ancienne réponse',
    (tester) async {
      final auth = _Auth();
      addTearDown(auth.events.close);
      await tester.pumpWidget(
        MaterialApp(
          home: ReportTargetPage(
            client: _Client(auth),
            kind: 'profile',
            target: 'fixture-target',
          ),
        ),
      );
      await tester.enterText(
        find.byType(TextFormField),
        'Précisions privées du compte A',
      );
      auth.currentUser = null;
      auth.events.add(const AuthState(AuthChangeEvent.signedOut, null));
      await tester.pump();
      expect(find.textContaining('Session modifiée'), findsOneWidget);
      expect(find.text('Précisions privées du compte A'), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
