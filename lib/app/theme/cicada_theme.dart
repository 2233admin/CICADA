import 'package:flutter/material.dart';
import 'cicada_colors.dart';

class CicadaTheme {
  CicadaTheme._();

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: CicadaColors.background,
    colorSchemeSeed: CicadaColors.data,
    useMaterial3: true,
    fontFamily: 'Segoe UI',
    cardTheme: CardThemeData(
      color: CicadaColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: CicadaColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CicadaColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: CicadaColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: CicadaColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: CicadaColors.energy),
      ),
      labelStyle: const TextStyle(color: CicadaColors.textSecondary),
      hintStyle: const TextStyle(color: CicadaColors.textTertiary),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CicadaColors.data,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: CicadaColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: CicadaColors.border),
    chipTheme: ChipThemeData(
      backgroundColor: CicadaColors.surface,
      side: const BorderSide(color: CicadaColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  );
}
