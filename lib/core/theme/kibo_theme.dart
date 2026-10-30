import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'kibo_colors.dart';

abstract final class KiboTheme {
  static const fontFamily = 'Manrope';
  static bool _licenseRegistered = false;

  static void registerFontLicense() {
    if (_licenseRegistered) return;
    _licenseRegistered = true;
    LicenseRegistry.addLicense(() async* {
      final text = await rootBundle.loadString('assets/fonts/manrope/OFL.txt');
      yield LicenseEntryWithLineBreaks(const ['Manrope'], text);
    });
  }

  static final ThemeData light = _buildLight();

  static ThemeData _buildLight() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: KiboColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: KiboColors.primary,
          onPrimary: KiboColors.surface,
          primaryContainer: KiboColors.primaryContainer,
          onPrimaryContainer: KiboColors.primaryDark,
          secondary: KiboColors.accent,
          onSecondary: KiboColors.textPrimary,
          surface: KiboColors.surface,
          onSurface: KiboColors.textPrimary,
          onSurfaceVariant: KiboColors.textSecondary,
          outline: KiboColors.border,
          outlineVariant: KiboColors.border,
          error: KiboColors.error,
          onError: KiboColors.textPrimary,
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: KiboColors.background,
    );
    final text = base.textTheme
        .copyWith(
          displayLarge: const TextStyle(
            fontSize: 48,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
          displayMedium: const TextStyle(
            fontSize: 36,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
          displaySmall: const TextStyle(
            fontSize: 28,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
          headlineLarge: const TextStyle(
            fontSize: 28,
            height: 1.3,
            fontWeight: FontWeight.w800,
          ),
          headlineMedium: const TextStyle(
            fontSize: 24,
            height: 1.3,
            fontWeight: FontWeight.w800,
          ),
          headlineSmall: const TextStyle(
            fontSize: 22,
            height: 1.3,
            fontWeight: FontWeight.w800,
          ),
          titleLarge: const TextStyle(
            fontSize: 20,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: const TextStyle(
            fontSize: 18,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: const TextStyle(
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: const TextStyle(
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: const TextStyle(
            fontSize: 12,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
          labelLarge: const TextStyle(
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
          labelMedium: const TextStyle(
            fontSize: 12,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
          labelSmall: const TextStyle(
            fontSize: 12,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        )
        .apply(
          fontFamily: fontFamily,
          bodyColor: KiboColors.textPrimary,
          displayColor: KiboColors.textPrimary,
        );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return base.copyWith(
      textTheme: text,
      iconTheme: const IconThemeData(size: 24, color: KiboColors.textPrimary),
      cardTheme: CardThemeData(
        color: KiboColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: KiboColors.border),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KiboColors.primary,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: KiboColors.primary,
          foregroundColor: KiboColors.surface,
          minimumSize: const Size(0, 52),
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: KiboColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        constraints: const BoxConstraints(minHeight: 56),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KiboColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KiboColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KiboColors.primary, width: 2),
        ),
        hintStyle: text.bodyMedium?.copyWith(color: KiboColors.textSecondary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        // Laisse deux lignes aux libellés, y compris à l’échelle Material maximale.
        height: 96,
        elevation: 0,
        backgroundColor: KiboColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: KiboColors.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall!.copyWith(
            color: states.contains(WidgetState.selected)
                ? KiboColors.primary
                : KiboColors.textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? KiboColors.primary
                : KiboColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
