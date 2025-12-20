import 'package:flutter/material.dart';
import '../../controllers/group_controller.dart';
import '../../models/group_model.dart'; // Asegúrate de importar tu modelo
import '../../widgets/appbar_custom.dart';
import '../../widgets/group_screen/floating_button.dart';
import 'group_screens/group_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GroupController _groupController = GroupController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Mis Grupos'),
      floatingActionButton: const FloattingButton(),

      body: StreamBuilder<List<GroupModel>>(
        stream: _groupController.obtenerGruposStream(),
        builder: (context, snapshot) {
          // CARGAMOS
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          //NO GRUPOS
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tienes grupos todavía'));
          }

          var grupos = snapshot.data!;

          // GRUPOSTOTALES
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: grupos.length,
            itemBuilder: (context, index) {
              final grupo = grupos[index];

              Color colorGrupo = Color(grupo.colorValue);

              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorGrupo, // El color del grupos
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SimpleGroupScreen(colorGrupo: colorGrupo),
                      ),
                    );
                  },
                  child: Text(
                    grupo.nombre,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}