import 'package:compartimos_gastos/screens/main/group_screens/settings_group_screen.dart';
import 'package:flutter/material.dart';
import '../../../controllers/pay_controller.dart';
import '../../../controllers/themes_controller.dart';
import '../../../models/group_model.dart';
import '../../../models/pay_model.dart';
import '../../../widgets/appbar_custom.dart';
import '../../../widgets/group_screen/add_pay_dialog.dart';

class GroupScreen extends StatelessWidget {
  // Recibimos el modelo completo del grupo
  final GroupModel groupModel;

  GroupScreen({super.key, required this.groupModel});
  final PayController _paymentController = PayController();

  @override
  Widget build(BuildContext context) {
    // Usamos el color del grupo para configurar el tema de esta pantalla
    final Color colorGrupo = Color(groupModel.colorValue);

    return Theme(
      data: ThemeController.crearTema(colorGrupo),
      child: Scaffold(
        appBar: CustomAppBar(
          title: groupModel.nombre,
          showLogout: false,
          actions: [
            IconButton( //  introducimos d emanera manual
              icon: const Icon(Icons.settings),
              tooltip: 'Ajustes',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SettingsGroupScreen(groupModel: groupModel),
                  ),
                );
              },
            ),
          ],
        ),

        //BOTÓN FLOTANTE (AÑADIR GASTO) ------------------------
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return AddExpenseDialog(groupModel: groupModel);
              },
            );
          },
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),

        body: Column(
          children: [
            // LISTA DE PAGOS (VERTICAL)
            Expanded(
              child: StreamBuilder<List<PayModel>>(
                stream: _paymentController.obtenerPagosDelGrupo(groupModel.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Sin gastos
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long,
                              size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 10),
                          const Text("No hay gastos registrados"),
                        ],
                      ),
                    );
                  }

                  // Lista de gastos
                  var pagos = snapshot.data!;

                  return ListView.builder(
                    itemCount: pagos.length,
                    itemBuilder: (context, index) {
                      final pago = pagos[index];

                      // Formateo fecha
                      final date = pago.fecha.toDate();
                      String fechaFormateada =
                          "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}";

                      return ListTile(
                        onLongPress: () { // si presionamos largo borramos
                          _mostrarDialogoBorrar(context, pago);
                        },
                        leading: CircleAvatar(
                          backgroundColor: colorGrupo,
                          child: const Icon(Icons.shopping_bag,
                              color: Colors.white),
                        ),
                        title: Text(
                          pago.descripcion,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Pagado por: ${_obtenerNombre(pago.idPagador)}",
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${pago.cantidad.toStringAsFixed(2)} €",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: colorGrupo,
                              ),
                            ),
                            Text(
                              fechaFormateada,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Función auxiliar para traducir UIDs a Nombres reales
  String _obtenerNombre(String uid) {
    if (groupModel.miembros.containsKey(uid)) {
      return groupModel.miembros[uid]!;
    }
    return "Usuario";
  }

  void _mostrarDialogoBorrar(BuildContext context, PayModel pago) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text('¿Seguro que quieres borrar "${pago.descripcion}" de ${pago.cantidad.toStringAsFixed(2)}€?\n\nSe recalcularán las deudas automáticamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              // Cerrar diálogo
              Navigator.pop(context);

              // Llamar al controlador para borrar
              try {
                await _paymentController.eliminarPago(groupModel.id, pago);

                // Configrmacion
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gasto eliminado y balances actualizados')),
                  );
                }
              } catch (e) {
                print("Error borrando: $e");
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
