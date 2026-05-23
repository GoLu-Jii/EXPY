import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kBgColor = Color(0xFF000000);
const kWhite = Color(0xFFFFFFFF);
const kAsh = Color(0xFF888888);
const kGreen = Color(0xFF00FF41);
const kRed = Color(0xFFFF4444);
const kBorder = Color(0xFF444444);

ThemeData buildAppTheme() {
  final mono = GoogleFonts.robotoMonoTextTheme().apply(
    bodyColor: kWhite,
    displayColor: kWhite,
  );

  return ThemeData(
    scaffoldBackgroundColor: kBgColor,
    colorScheme: const ColorScheme.dark(
      surface: kBgColor,
      primary: kGreen,
      secondary: kAsh,
      error: kRed,
    ),
    textTheme: mono,
    appBarTheme: AppBarTheme(
      backgroundColor: kBgColor,
      elevation: 0,
      titleTextStyle: GoogleFonts.robotoMono(
        color: kWhite,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
      iconTheme: const IconThemeData(color: kWhite),
    ),
    dialogTheme: const DialogTheme(
      backgroundColor: kBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: kBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kBgColor,
      labelStyle: GoogleFonts.robotoMono(color: kAsh, fontSize: 12),
      hintStyle: GoogleFonts.robotoMono(color: kAsh, fontSize: 12),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: kWhite, width: 1),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: kGreen, width: 1),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: kRed, width: 1),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: kRed, width: 1),
      ),
      cursorColor: kWhite,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kWhite,
        backgroundColor: kBgColor,
        side: const BorderSide(color: kBorder, width: 1),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: GoogleFonts.robotoMono(fontSize: 12, letterSpacing: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kWhite,
        textStyle: GoogleFonts.robotoMono(fontSize: 12, letterSpacing: 1),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    ),
    dividerTheme: const DividerThemeData(color: kBorder, thickness: 1),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _NoTransitionBuilder(),
        TargetPlatform.iOS: _NoTransitionBuilder(),
        TargetPlatform.linux: _NoTransitionBuilder(),
        TargetPlatform.macOS: _NoTransitionBuilder(),
        TargetPlatform.windows: _NoTransitionBuilder(),
      },
    ),
  );
}

class _NoTransitionBuilder extends PageTransitionsBuilder {
  const _NoTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
