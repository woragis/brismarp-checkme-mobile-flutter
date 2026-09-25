import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

ThemeData checkmeTheme() {
  final base = GoogleFonts.poppinsTextTheme();
  return ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: CheckmeColors.navy,
      secondary: CheckmeColors.care,
      error: CheckmeColors.alerta,
      surface: CheckmeColors.cartao,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: CheckmeColors.texto,
    ),
    scaffoldBackgroundColor: CheckmeColors.fundo,
    textTheme: base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: CheckmeColors.texto,
        fontSize: 28,
        height: 1.2,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: CheckmeColors.texto,
        fontSize: 22,
        height: 1.3,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: CheckmeColors.texto,
        fontSize: 16,
        height: 1.4,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        color: CheckmeColors.textoSecundario,
        fontSize: 14,
        height: 1.55,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: CheckmeColors.cartao,
      indicatorColor: CheckmeColors.azulNeve,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? CheckmeColors.navy : CheckmeColors.textoSecundario,
        );
      }),
    ),
  );
}
