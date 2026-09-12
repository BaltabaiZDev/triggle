import 'package:flutter/material.dart';

abstract final class TriGridTheme {
  static const ink = Color(0xFFF3F1E8);
  static const forest = Color(0xFF72C36B);
  static const forestDeep = Color(0xFF3E8B58);
  static const coral = Color(0xFFD86686);
  static const gold = Color(0xFFD6D56A);
  static const sand = Color(0xFF252826);
  static const parchment = Color(0xFF3A3E3B);

  static ThemeData get light => lightWith();

  static ThemeData lightWith({bool highContrast = false}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: forest,
      brightness: Brightness.dark,
      primary: highContrast ? const Color(0xFF91F287) : forest,
      secondary: highContrast ? const Color(0xFFFF87A7) : coral,
      tertiary: gold,
      surface: highContrast ? const Color(0xFF242624) : parchment,
      onSurface: Colors.white,
    );

    return _baseTheme(
      colorScheme: scheme,
      scaffoldBackgroundColor: highContrast ? Colors.black : sand,
      borderColor: Colors.black,
      displayColor: highContrast ? Colors.white : ink,
    );
  }

  static ThemeData darkWith({bool highContrast = false}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: highContrast ? const Color(0xFF78F0B1) : forest,
      brightness: Brightness.dark,
      primary: highContrast ? const Color(0xFF8CFFC2) : const Color(0xFF83CBA5),
      secondary: highContrast
          ? const Color(0xFFFF9B83)
          : const Color(0xFFF39A82),
      surface: highContrast ? const Color(0xFF111311) : const Color(0xFF323633),
      onSurface: Colors.white,
    );
    return _baseTheme(
      colorScheme: scheme,
      scaffoldBackgroundColor: highContrast
          ? Colors.black
          : const Color(0xFF1C1F1D),
      borderColor: Colors.black,
      displayColor: Colors.white,
    );
  }

  static ThemeData _baseTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
    required Color borderColor,
    required Color displayColor,
  }) {
    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      useMaterial3: true,
      fontFamily: 'Roboto',
      splashFactory: InkSplash.splashFactory,
      visualDensity: VisualDensity.compact,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(height: 1.35),
        bodyMedium: TextStyle(height: 1.3),
      ).apply(bodyColor: displayColor, displayColor: displayColor),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: displayColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: 44,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          color: displayColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.35,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface.withValues(alpha: 0.94),
        elevation: 3,
        shadowColor: Colors.black54,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: borderColor.withValues(alpha: 0.88),
            width: 2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 3,
          shadowColor: Colors.black54,
          minimumSize: const Size(44, 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: borderColor, width: 2),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          side: BorderSide(color: borderColor.withValues(alpha: 0.9), width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        fillColor: colorScheme.surface.withValues(alpha: 0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: borderColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: borderColor, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.48),
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        minVerticalPadding: 3,
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
    );
  }
}
