import 'package:flutter/services.dart';

Future<void> loadManropeFonts() async {
  final loader = FontLoader('Manrope');
  for (final name in ['regular', 'semibold', 'extrabold']) {
    loader.addFont(rootBundle.load('assets/fonts/manrope/manrope-$name.ttf'));
  }
  await loader.load();
}
