import 'package:flutter/material.dart';

import '../../controllers/themes_controller.dart';
import '../../widgets/appbar_custom.dart';
import '../../widgets/group_screen/color_dropdown_widget.dart';
import '../../widgets/group_screen/floating_button.dart';
import 'group_screens/group_screen.dart';

class HomeScreen extends StatefulWidget {
  //Stateful porque ahora es dinámica
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Color _selectedColor = ThemeController.groupColors[0]['color'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Grupos'),

      floatingActionButton: const FloattingButton(),
      // El cuerpo de la página
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centra verticalmente
          children: [
            // Texto
            const Text(
              'Aquí se mostrarán los grupos',
              style: TextStyle(fontSize: 30),
            ),

            ColorDropdownWidget(
              selectedColor: _selectedColor,
              onColorChanged: (newColor) {
                // Actualizamos el estado del HomeScreen
                setState(() {
                  _selectedColor = newColor;
                });
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                // NAVEGACIÓN A SIMPLE GROUP SCREEN
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SimpleGroupScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Botón de prueba'),
            ),
          ],
        ),
      ),
    );
  }
}
