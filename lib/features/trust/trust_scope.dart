import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrustScope extends InheritedWidget {
  const TrustScope({
    super.key,
    required this.clientProvider,
    required super.child,
  });
  final SupabaseClient Function() clientProvider;
  static SupabaseClient? maybeClient(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<TrustScope>()
      ?.clientProvider();
  @override
  bool updateShouldNotify(TrustScope oldWidget) =>
      clientProvider != oldWidget.clientProvider;
}
