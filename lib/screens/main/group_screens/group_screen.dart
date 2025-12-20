import 'package:flutter/material.dart';

import '../../../widgets/appbar_custom.dart';

class SimpleGroupScreen extends StatelessWidget {

  final Color colorGrupo;
  const SimpleGroupScreen({super.key, required this.colorGrupo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Grupo'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Este es el contenido del grupo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print("Sin implementar");
              },
              child: const Text('Acción'),
            ),
          ],
        ),
      ),
    );
  }
}
