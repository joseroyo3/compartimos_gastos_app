import 'package:flutter/material.dart';
import '../../../controllers/themes_controller.dart';
import '../../../models/group_model.dart';
import '../../../widgets/appbar_custom.dart';

class SettingsGroupScreen extends StatelessWidget {
  final GroupModel groupModel;

  const SettingsGroupScreen({super.key, required this.groupModel});

  @override
  Widget build(BuildContext context) {
    Color colorGrupo = Color(groupModel.colorValue);

    // Mantenemos el tema del grupo para que se vea consistente
    return Theme(
      data: ThemeController.crearTema(colorGrupo),
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'Ajustes del Grupo',
          showLogout:
              false, // Aquí no mostramos logout, solo la flecha de volver
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.settings,
                  size: 80, color: colorGrupo.withOpacity(0.5)),
              const SizedBox(height: 20),
              Text(
                'Configuración de: ${groupModel.nombre}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text("Aquí podrás editar miembros, cambiar nombre, etc."),
            ],
          ),
        ),
      ),
    );
  }
}
