import 'package:flutter/material.dart';

import '../../widgets/appbar_custom.dart';

class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key});

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

            const SizedBox(height: 20),
            // Botón
            ElevatedButton(
              onPressed: () {
                print("Nada inegrado aún");
              },
              child: const Text('Botón de prueba'),
            ),
          ],
        ),
      ),
    );
  }
}
