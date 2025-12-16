import 'package:flutter/material.dart';

// Encargado de controlar el tema principal de la app
class ThemeController {
  // Especifico el verde del logo como color principal
  static const Color primaryColor = Color(0xFF30CBA1);

  // Creamos el Tema Global
  static final ThemeData tema = ThemeData(
    useMaterial3: true,

    // definimos la paleta principal en verde, a futuro pasaremos otros colores (segun grupo)
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
    ),

    // --- BARRA SUPERIOR (APPBAR) ---
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor, // Fondo Verde
      foregroundColor: Colors.white, // Texto Blanco
      centerTitle: true,
      elevation: 0,
    ),

    // --- BOTONES (ELEVATED BUTTON) ---
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor, // Fondo Verde
        foregroundColor: Colors.white, // Texto Blanco
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),

    // --- BOTÓN FLOTANTE ---
    // Lo he puesto también en Verde (primaryColor) para que no dé error
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
  );
}
