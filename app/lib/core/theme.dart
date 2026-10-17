import 'package:flutter/material.dart';

/// Cores do logotipo: tinta (sumi), papel (washi), sakura e o vermelho do carimbo (hanko).
class NesaroColors {
  const NesaroColors._();

  static const ink = Color(0xFF1F1B16);
  static const paper = Color(0xFFF5EFE3);
  static const sakura = Color(0xFFD45A73);
  static const sakuraLight = Color(0xFFE07088);
  static const seal = Color(0xFFB83A2A);
  static const muted = Color(0xFF5A5249);
  static const success = Color(0xFF1A7F4E);
}

ThemeData buildNesaroTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: NesaroColors.sakura,
    surface: NesaroColors.paper,
  ).copyWith(
    primary: NesaroColors.ink,
    onPrimary: NesaroColors.paper,
    secondary: NesaroColors.sakura,
    onSecondary: Colors.white,
    error: NesaroColors.seal,
  );

  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0x331F1B16)),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: NesaroColors.paper,
    appBarTheme: const AppBarTheme(
      backgroundColor: NesaroColors.paper,
      foregroundColor: NesaroColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x1F1F1B16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: NesaroColors.ink, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Color(0x33D45A73),
    ),
  );
}
