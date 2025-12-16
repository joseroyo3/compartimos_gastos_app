import 'package:flutter/material.dart';

import '../../controllers/themes_controller.dart';
import '../../widgets/appbar_custom.dart';

class GroupScreen extends StatefulWidget { //Stateful porque ahora es dinámica
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {

  Color _selectedColor = ThemeController.groupColors[0]['color'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Grupos'),
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

            // dropdown
            DropdownButton<Color>(
              value: _selectedColor,
              // Mapeamos tu lista del ThemeController a opciones del menú
              items: ThemeController.groupColors.map((item) {
                return DropdownMenuItem<Color>(
                  value: item['color'], // El valor que se guardará
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: item['color'], size: 16),
                      const SizedBox(width: 10),
                      Text(item['name']),
                    ],
                  ),
                );
              }).toList(),
              // Cuando cambias la opción, actualizamos la variable y redibujamos
              onChanged: (Color? newColor) {
                if (newColor != null) {
                  setState(() {
                    _selectedColor = newColor;
                  });
                }
              },
            ),

            const SizedBox(height: 20),
            // Botón
            ElevatedButton(
              onPressed: () {
                print("Nada inegrado aún");
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
