import 'package:flutter/material.dart';
import '../../../controllers/themes_controller.dart';
import '../../../widgets/appbar_custom.dart';

class GroupScreen extends StatelessWidget {
  final Color colorGrupo;

  const GroupScreen({super.key, required this.colorGrupo});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeController.crearTema(colorGrupo), //fuerza color

      child: Scaffold(
        appBar: const CustomAppBar(title: 'Grupo'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Este es el contenido del grupo',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorGrupo
                ),
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
      ),
    );
  }
}