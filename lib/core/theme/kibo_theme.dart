import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'kibo_colors.dart';
import 'kibo_tokens.dart';

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
    LicenseRegistry.addLicense(() async* {
      final text = await rootBundle.loadString(
        'assets/data/GEONAMES-LICENSE.txt',
      );
      yield LicenseEntryWithLineBreaks(const [
        'GeoNames — villes du Congo',
      ], text);
    });
  }

  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final lightScheme =
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
          secondaryContainer: KiboColors.primaryContainer,
          onSecondaryContainer: KiboColors.primaryDark,
          tertiary: KiboColors.primaryDark,
          onTertiary: KiboColors.surface,
          tertiaryContainer: KiboColors.primaryContainer,
          onTertiaryContainer: KiboColors.primaryDark,
          surface: KiboColors.surface,
          surfaceDim: KiboColors.border,
          surfaceBright: KiboColors.surface,
          surfaceContainerLowest: KiboColors.surface,
          surfaceContainerLow: KiboColors.background,
          surfaceContainer: KiboColors.background,
          surfaceContainerHigh: KiboColors.border,
          surfaceContainerHighest: KiboColors.border,
          inverseSurface: KiboColors.textPrimary,
          onInverseSurface: KiboColors.surface,
          inversePrimary: KiboColors.primaryContainer,
          surfaceTint: Colors.transparent,
          onSurface: KiboColors.textPrimary,
          onSurfaceVariant: KiboColors.textSecondary,
          outline: KiboColors.textSecondary,
          outlineVariant: KiboColors.border,
          error: KiboColors.error,
          onError: KiboColors.textPrimary,
          errorContainer: KiboColors.border,
          onErrorContainer: KiboColors.textPrimary,
        );
    final scheme = isDark
        ? ColorScheme.fromSeed(
            seedColor: KiboColors.primary,
            brightness: Brightness.dark,
          ).copyWith(
            primary: const Color(0xFF6DDCB2),
            onPrimary: const Color(0xFF003827),
            primaryContainer: const Color(0xFF173F30),
            onPrimaryContainer: const Color(0xFFA8F2CF),
            secondary: const Color(0xFF6DDCB2),
            onSecondary: const Color(0xFF003827),
            secondaryContainer: const Color(0xFF244B3C),
            onSecondaryContainer: const Color(0xFFD2F4E3),
            tertiary: const Color(0xFFA8F2CF),
            onTertiary: const Color(0xFF003827),
            tertiaryContainer: const Color(0xFF173F30),
            onTertiaryContainer: const Color(0xFFD2F4E3),
            surface: const Color(0xFF18251F),
            onSurface: const Color(0xFFE7F0EB),
            onSurfaceVariant: const Color(0xFFB0C0B6),
            surfaceDim: const Color(0xFF101A16),
            surfaceBright: const Color(0xFF2B3A32),
            surfaceContainerLowest: const Color(0xFF101A16),
            surfaceContainerLow: const Color(0xFF142019),
            surfaceContainer: const Color(0xFF1D2C24),
            surfaceContainerHigh: const Color(0xFF24352B),
            surfaceContainerHighest: const Color(0xFF2B3A32),
            outline: const Color(0xFF8B9F93),
            outlineVariant: const Color(0xFF3A4E43),
            inverseSurface: const Color(0xFFE7F0EB),
            onInverseSurface: const Color(0xFF18251F),
            inversePrimary: KiboColors.primaryDark,
            error: const Color(0xFFFFB4AB),
            onError: const Color(0xFF690005),
            errorContainer: const Color(0xFF50231F),
            onErrorContainer: const Color(0xFFFFDAD6),
            surfaceTint: Colors.transparent,
          )
        : lightScheme;
    final background = isDark ? const Color(0xFF101A16) : KiboColors.background;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
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
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(KiboTokens.fieldRadius),
    );
    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 24,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        disabledColor: scheme.outlineVariant,
        labelStyle: text.labelMedium,
        secondaryLabelStyle: text.labelMedium?.copyWith(
          color: scheme.onPrimaryContainer,
        ),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KiboTokens.fieldRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(scheme.surface),
        elevation: WidgetStatePropertyAll(0),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KiboTokens.fieldRadius),
          ),
        ),
        constraints: const BoxConstraints(minHeight: 56),
        textStyle: WidgetStatePropertyAll(text.bodyLarge),
        hintStyle: WidgetStatePropertyAll(
          text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: scheme.primary,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
        circularTrackColor: scheme.primaryContainer,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KiboTokens.sheetRadius),
        ),
        titleTextStyle: text.titleLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(KiboTokens.sheetRadius),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KiboTokens.fieldRadius),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        textColor: scheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KiboTokens.cardRadius),
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: scheme.primary,
        textColor: scheme.onSurface,
        collapsedIconColor: scheme.primary,
        childrenPadding: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      iconTheme: IconThemeData(size: 24, color: scheme.onSurface),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // Laisser M3 distinguer FilledButton et FilledButton.tonal.
          minimumSize: const Size(0, 52),
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: buttonShape,
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        constraints: const BoxConstraints(minHeight: 56),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.onSurfaceVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.onSurfaceVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        errorStyle: text.bodySmall?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        errorMaxLines: 4,
      ),
      navigationBarTheme: NavigationBarThemeData(
        // Laisse deux lignes aux libellés, y compris à l’échelle Material maximale.
        height: 96,
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall!.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
