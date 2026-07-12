import 'package:flutter/material.dart';

abstract final class UnfoldColors {
  static const ink = Color(0xff09090b);
  static const surface = Color(0xff18181b);
  static const mint = Color(0xfffafafa);
  static const cyan = Color(0xff9bbcff);
  static const amber = Color(0xffffc66b);
  static const muted = Color(0xffa1a1aa);
}

abstract final class UnfoldTheme {
  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: UnfoldColors.cyan,
      brightness: Brightness.dark,
      surface: UnfoldColors.surface,
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: UnfoldColors.ink,
      useMaterial3: true,
      fontFamily: 'PlusJakartaSans',
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 38,
          height: 1.02,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45),
      ),
    );
  }
}
