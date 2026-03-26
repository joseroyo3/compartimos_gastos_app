import 'package:flutter/material.dart';
import '../../controllers/group_controller.dart';
import '../../controllers/gruop_navigator_controller.dart';
import '../../models/group_model.dart';
import '../../widgets/appbar_custom.dart';
import '../../widgets/group_screen/floating_button.dart';
import '../../widgets/responsive_list_container.dart';

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
          return ResponsiveListContainer(
            child: ListView.builder(
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
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              GroupNavigatorScreen(groupModel: grupo),
                        ),
                      );
                    },
                    onLongPress: () => _mostrarDialogoEliminar(context, grupo),
                    child: Text(
                      grupo.nombre,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
  // Función para mostrar el aviso de borrar
  void _mostrarDialogoEliminar(BuildContext context, GroupModel grupo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar Grupo"),
        content: Text("¿Seguro que quieres borrar el grupo '${grupo.nombre}'? Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(), // Cancelar
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              try {
                Navigator.of(ctx).pop(); // Cerrar diálogo primero
                await _groupController.eliminarGrupo(grupo.id);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Grupo eliminado correctamente"))
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
                  );
                }
              }
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

