// Rendering tool, run explicitly with flutter test tool/generate_launcher_icons_test.dart.
// It is outside test/ so CI tests never rewrite source assets.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('render KIBO launcher resources from the vector geometry', () async {
    const densities = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    for (final entry in densities.entries) {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)..scale(entry.value / 108);
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          const ui.Rect.fromLTWH(0, 0, 108, 108),
          const ui.Radius.circular(24),
        ),
        ui.Paint()..color = const ui.Color(0xFF087F5B),
      );
      final path = ui.Path()
        ..moveTo(32, 30)
        ..lineTo(42, 30)
        ..lineTo(42, 49)
        ..lineTo(61, 30)
        ..lineTo(74, 30)
        ..lineTo(51, 54)
        ..lineTo(76, 78)
        ..lineTo(62, 78)
        ..lineTo(42, 58)
        ..lineTo(42, 78)
        ..lineTo(32, 78)
        ..close();
      canvas.drawPath(path, ui.Paint()..color = const ui.Color(0xFFFFFFFF));
      final picture = recorder.endRecording();
      final image = await picture.toImage(entry.value, entry.value);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
      ).writeAsBytes(png!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }
  });
}
