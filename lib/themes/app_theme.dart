import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Светлая тема
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFF7e61f3),
  scaffoldBackgroundColor: const Color(0xFFeef4ff),
  textTheme: TextTheme(
    bodyMedium: GoogleFonts.poppins(
      fontSize: 16,
      color: const Color(0xFF000000),
      fontWeight: FontWeight.normal,
    ),
    headlineSmall: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF000000),
    ),
    headlineMedium: GoogleFonts.poppins( 
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF000000),
    ),
    headlineLarge: GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF7e61f3),
    ),
    bodySmall: GoogleFonts.poppins(
      fontSize: 14,
      color: Colors.black54,
      fontWeight: FontWeight.normal,
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    titleTextStyle: GoogleFonts.poppins(
      fontSize: 30,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF7e61f3),
    ),
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF7e61f3),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
    ).copyWith(
      textStyle: MaterialStateProperty.all(
        GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFFeef4ff),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: const Color(0xFFeef4ff),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    textStyle: GoogleFonts.poppins(
      fontSize: 16,
      color: const Color(0xFF000000),
      fontWeight: FontWeight.normal,
    ),
    elevation: 8,
  ),
  useMaterial3: true,
);

// Тёмная тема
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF7e61f3),
  scaffoldBackgroundColor: Colors.grey[900],
  textTheme: TextTheme(
    bodyMedium: GoogleFonts.poppins(
      fontSize: 16,
      color: const Color(0xFFFFFFFF),
      fontWeight: FontWeight.normal,
    ),
    headlineSmall: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFFFFFF),
    ),
    headlineMedium: GoogleFonts.poppins( 
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFFFFFF),
    ),
    headlineLarge: GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFFFFFFF),
    ),
    bodySmall: GoogleFonts.poppins(
      fontSize: 14,
      color: Colors.white70,
      fontWeight: FontWeight.normal,
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    titleTextStyle: GoogleFonts.poppins(
      fontSize: 30,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF7e61f3),
    ),
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF7e61f3),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
    ).copyWith(
      textStyle: MaterialStateProperty.all(
        GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF1C2526),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: const Color(0xFF1C2526),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    textStyle: GoogleFonts.poppins(
      fontSize: 16,
      color: const Color(0xFF000000),
      fontWeight: FontWeight.normal,
    ),
    elevation: 8,
  ),
  useMaterial3: true,
);