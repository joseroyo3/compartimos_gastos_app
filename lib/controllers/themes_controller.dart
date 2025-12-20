import 'package:flutter/material.dart';

class ThemeController {
  // Color principal (Verde)
  static const Color primaryColor = Color(0xFF30CBA1);

  // LISTA DE COLORES
  static final List<Map<String, dynamic>> groupColors = [
    {'color': Colors.blue, 'name': 'Azul'},
    {'color': Colors.red, 'name': 'Rojo'},
    {'color': Colors.green, 'name': 'Verde'},
    {'color': Colors.orange, 'name': 'Naranja'},
    {'color': Colors.purple, 'name': 'Morado'},
    {'color': Colors.teal, 'name': 'Verde azulado'},
    {'color': Colors.pink, 'name': 'Rosa'},
    {'color': Colors.indigo, 'name': 'Índigo'},
    {'color': Colors.amber, 'name': 'Ámbar'},
    {'color': Colors.cyan, 'name': 'Cian'},
    {'color': Colors.deepOrange, 'name': 'Naranja oscuro'},
    {'color': Colors.lightBlue, 'name': 'Azul claro'},
  ];

  // Esto crea un tema completo basándose en CUALQUIER color que le pases
  static ThemeData crearTema(Color colorBase) {
    return ThemeData(
      useMaterial3: true,

      // La paleta basada en el color recibido
      colorScheme: ColorScheme.fromSeed(
        seedColor: colorBase,
        primary: colorBase,
      ),

      // Estilo del AppBar (igual que tu original)
      appBarTheme: AppBarTheme(
        backgroundColor: colorBase,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),

      // Estilo de los Botones (igual que tu original)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorBase,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),

      // Estilo del Botón Flotante
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorBase,
        foregroundColor: Colors.white,
      ),
    );
  }

  static final ThemeData tema = crearTema(primaryColor);
}