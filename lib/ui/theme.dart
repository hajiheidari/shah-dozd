import 'package:flutter/material.dart';

import '../l10n/strings.dart';

/// Design tokens. See docs/DESIGN.md.
abstract final class C {
  static const night = Color(0xFF0C0F2A); // background
  static const surface = Color(0xFF151942); // cards, panels
  static const surfaceHi = Color(0xFF1E2356);
  static const indigo = Color(0xFF2A2466);
  static const purple = Color(0xFF4A2180);
  static const gold = Color(0xFFD4AE55);
  static const goldLight = Color(0xFFF6E3A6);
  static const goldText = Color(0xFFE9CD86);
  static const ivory = Color(0xFFF6EEDC);
  static const muted = Color(0xFFCFC6B4);
  static const faint = Color(0xFFA9A090);
  static const ruby = Color(0xFFB3243A);
  static const joker = Color(0xFFC2387F);
  static const success = Color(0xFF9FE0B8);
  static const disabled = Color(0xFF232750);
  static const onGold = Color(0xFF1A1530);
  static const line = Color(0x66D4AE55);
  static const lineSoft = Color(0x33D4AE55);

  /// Avatar badge colors (players pick one).
  static const avatars = [
    Color(0xFFB3243A),
    Color(0xFF2F8A84),
    Color(0xFF7B4CB8),
    Color(0xFFD49340),
    Color(0xFF3F6FD1),
    Color(0xFFC2387F),
    Color(0xFF5E8C3A),
    Color(0xFF8A6238),
  ];
}

abstract final class Space {
  static const xs = 4.0, s = 8.0, m = 12.0, l = 16.0, xl = 24.0, xxl = 32.0;
  static const radius = 16.0;
  static const radiusL = 20.0;
}

/// Font stacks. Persian and UI text use Vazirmatn (readable at every size),
/// Hindi falls back to Noto Sans Devanagari, English display titles use
/// Cormorant Garamond.
abstract final class F {
  static const ui = 'Vazirmatn';
  static const deva = 'NotoSansDevanagari';
  static const display = 'CormorantGaramond';
  static const fallback = [deva, ui];

  /// Big titles: Vazirmatn Black in Persian, Cormorant in English,
  /// Noto Devanagari Bold in Hindi.
  static TextStyle title(Lang lang, double size, {Color color = C.goldText}) => switch (lang) {
        Lang.en => TextStyle(fontFamily: display, fontWeight: FontWeight.w700, fontSize: size * 1.12, height: 1.1, color: color, fontFamilyFallback: fallback),
        Lang.hi => TextStyle(fontFamily: deva, fontWeight: FontWeight.w700, fontSize: size * .9, height: 1.35, color: color, fontFamilyFallback: const [ui]),
        Lang.fa => TextStyle(fontFamily: ui, fontWeight: FontWeight.w900, fontSize: size, height: 1.35, color: color, fontFamilyFallback: fallback),
      };
}

ThemeData buildTheme(Lang lang) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: lang == Lang.hi ? F.deva : F.ui,
    fontFamilyFallback: lang == Lang.hi ? const [F.ui] : F.fallback,
    scaffoldBackgroundColor: C.night,
    colorScheme: const ColorScheme.dark(
      primary: C.gold,
      onPrimary: C.onGold,
      secondary: C.goldLight,
      surface: C.surface,
      onSurface: C.ivory,
      error: Color(0xFFFF8A8A),
    ),
    splashFactory: InkSparkle.splashFactory,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: C.ivory, displayColor: C.ivory),
    dialogTheme: const DialogThemeData(
      backgroundColor: C.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(Space.radiusL)), side: BorderSide(color: C.line)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.onGold : C.muted),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.gold : C.disabled),
      trackOutlineColor: const WidgetStatePropertyAll(C.lineSoft),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.lineSoft)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.lineSoft)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.gold, width: 1.6)),
      hintStyle: const TextStyle(color: C.faint),
    ),
    snackBarTheme: const SnackBarThemeData(backgroundColor: C.surfaceHi, contentTextStyle: TextStyle(color: C.ivory, fontFamily: F.ui)),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
    }),
  );
}
