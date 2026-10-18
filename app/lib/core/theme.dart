import 'package:flutter/material.dart';

/// Cores do logotipo: tinta (sumi), papel (washi), sakura e o vermelho do carimbo (hanko).
class NesaroColors {
  const NesaroColors._();

  static const ink = Color(0xFF1F1B16);
  static const inkSoft = Color(0xFF3A332B);
  static const paper = Color(0xFFF5EFE3);
  static const paperDeep = Color(0xFFEDE5D6);
  static const sakura = Color(0xFFD45A73);
  static const sakuraLight = Color(0xFFE07088);
  static const sakuraMist = Color(0xFFFBE7EC);
  static const seal = Color(0xFFB83A2A);
  static const muted = Color(0xFF5A5249);
  static const line = Color(0x1F1F1B16);
  static const success = Color(0xFF1A7F4E);
  static const successMist = Color(0xFFE3F3EA);

  /// Cartão de destaque do painel: tinta → vinho → sakura.
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ink, Color(0xFF5B2333), sakura],
    stops: [0, 0.6, 1],
  );

  /// Lembra o Instagram na prévia do Direct e no cartão de conexão.
  static const instagramGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFFEDA75), Color(0xFFFA7E1E), Color(0xFFD62976), Color(0xFF962FBF), Color(0xFF4F5BD5)],
  );
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
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0x261F1B16)),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: NesaroColors.paper,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        // iOS e macOS ficam com a transição padrão da plataforma.
      },
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: NesaroColors.paper,
      surfaceTintColor: Colors.transparent,
      foregroundColor: NesaroColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: NesaroColors.ink),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: NesaroColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: NesaroColors.sakura, width: 1.8),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    chipTheme: const ChipThemeData(
      side: BorderSide(color: NesaroColors.line),
      shape: StadiumBorder(),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: NesaroColors.sakuraMist,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.white,
      indicatorColor: NesaroColors.sakuraMist,
    ),
  );
}
