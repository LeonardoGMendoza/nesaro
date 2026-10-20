import 'package:flutter/material.dart';

/// Cores da marca AliceFlow: azul-noite, azul elétrico, roxo e magenta.
///
/// Os nomes antigos (ink, paper, sakura, seal) foram mantidos para não quebrar
/// as telas; só os valores mudaram para a paleta nova.
class NesaroColors {
  const NesaroColors._();

  // Marca
  static const night = Color(0xFF0B0A24);
  static const blue = Color(0xFF3B6CFF);
  static const violet = Color(0xFF8B3DFF);
  static const magenta = Color(0xFFE03CF0);

  // Papéis usados nas telas
  static const ink = Color(0xFF14123A);
  static const inkSoft = Color(0xFF2E2A6B);
  static const paper = Color(0xFFF6F5FF);
  static const paperDeep = Color(0xFFEAE8FB);
  static const sakura = violet;
  static const sakuraLight = Color(0xFFB66BFF);
  static const sakuraMist = Color(0xFFEFE6FF);
  static const seal = Color(0xFFC62E4A);
  static const muted = Color(0xFF5C5980);
  static const line = Color(0x1F14123A);
  static const success = Color(0xFF1A7F4E);
  static const successMist = Color(0xFFE3F3EA);

  /// Gradiente do logo: azul → roxo → magenta.
  static const brandGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [blue, violet, magenta],
  );

  /// Cartão de destaque do painel e lateral do login: noite → índigo → roxo.
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [night, Color(0xFF2A1F8F), Color(0xFF8B3DFF)],
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
    borderSide: const BorderSide(color: Color(0x2614123A)),
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
