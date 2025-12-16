import 'package:flutter/material.dart';

// Encargado de controlar el tema principal de la app
class ThemeController {
  // Especifico el verde del logo como color principal
  static const Color primaryColor = Color(0xFF30CBA1);

  //LISTA DE COLORES DISPONIBLES PARA GRUPOS
  static final List<Map<String, dynamic>> groupColors = [
    {'color': Colors.blue, 'name': 'Azul'}, //1
    {'color': Colors.red, 'name': 'Rojo'}, //2
    {'color': Colors.green, 'name': 'Verde'}, //3
    {'color': Colors.orange, 'name': 'Naranja'}, //4
    {'color': Colors.purple, 'name': 'Morado'}, //5
    {'color': Colors.teal, 'name': 'Verde azulado'}, //6
    {'color': Colors.pink, 'name': 'Rosa'}, //7
    {'color': Colors.indigo, 'name': 'Índigo'}, //8
    {'color': Colors.amber, 'name': 'Ámbar'}, //9
    {'color': Colors.cyan, 'name': 'Cian'}, //10
    {'color': Colors.deepOrange, 'name': 'Naranja oscuro'}, //11
    {'color': Colors.lightBlue, 'name': 'Azul claro'}, //12
  ];

  // Creamos el Tema Global
  static final ThemeData tema = ThemeData(
    useMaterial3: true,

    // definimos la paleta principal en verde
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
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
  );
}