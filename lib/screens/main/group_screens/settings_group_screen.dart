import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para el Clipboard
import '../../../controllers/pay_controller.dart';
import '../../../controllers/themes_controller.dart';
import '../../../models/group_model.dart';
import '../../../widgets/appbar_custom.dart';

class SettingsGroupScreen extends StatelessWidget {
  final GroupModel groupModel;

  SettingsGroupScreen({super.key, required this.groupModel});

  final PayController _payController = PayController();

  @override
  Widget build(BuildContext context) {
    Color colorGrupo = Color(groupModel.colorValue);

    return Theme(
      data: ThemeController.crearTema(colorGrupo),
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'Ajustes del Grupo',
          showLogout: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // INVITAR GENTE (CÓDIGO UID)
              const Text(
                "Invitar Miembros",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.qr_code_2, size: 50, color: Colors.grey),
                      const SizedBox(height: 10),
                      const Text(
                        "Comparte este código con tus amigos para que se unan al grupo:",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),

                      // CAJA DEL CÓDIGO
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // El ID del grupo (SelectableText permite seleccionar)
                            Expanded(
                              child: SelectableText(
                                groupModel.id,
                                style: const TextStyle(
                                  fontFamily: 'Courier', // Fuente tipo código
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            // Botón copiar
                            IconButton(
                              icon: const Icon(Icons.copy),
                              tooltip: "Copiar código",
                              onPressed: () {
                                _copiarAlPortapapeles(context, groupModel.id);
                              },
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 20),

              // ELIMINAR TO DO -------------------------
              const Text(
                "Eliminar TODOS LOS DATOS DEL GRUPO",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red),
              ),
              const SizedBox(height: 10),
              const Text(
                "Estas acciones no se pueden deshacer.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 15),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
                icon: const Icon(Icons.delete_forever),
                label: const Text("BORRAR TODOS LOS GASTOS"),
                onPressed: () => _confirmarBorradoTotal(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FUNCIONES AUXILIARES ----------------------------

  void _copiarAlPortapapeles(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  // NUEVO DIALOG
  void _confirmarBorradoTotal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Estás seguro?"),
        content: const Text(
          "Esto eliminará TODOS los gastos, deudas y la lista de la compra de este grupo.\n\nLos balances volverán a cero. Esta acción es irreversible.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);

              // Ejecutar borrado
              try {
                await _payController.borrarTodosLosDatosDelGrupo(groupModel.id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Grupo reseteado con éxito")),
                  );
                }
              } catch (e) {
                print(e);
              }
            },
            child: const Text("Sí, borrar todo"),
          ),
        ],
      ),
    );
  }
}
