import 'package:flutter/material.dart';
import '../../../controllers/item_controller.dart';
import '../../../models/group_model.dart';
import '../../../models/item_model.dart';

class ShoppingListScreen extends StatelessWidget {
  final GroupModel groupModel;

  ShoppingListScreen({super.key, required this.groupModel});

  // Instanciamos el controlador
  final ItemController _shoppingController = ItemController();

  @override
  Widget build(BuildContext context) {
    // Obtenemos el color del grupo para el diseño
    final Color colorGrupo = Color(groupModel.colorValue);

    return Scaffold(
      // Botón para añadir producto
      floatingActionButton: FloatingActionButton(
        heroTag: "btn_add_producto",
        backgroundColor: colorGrupo,
        onPressed: () => _mostrarDialogoAnadir(context, colorGrupo),
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: StreamBuilder<List<ItemModel>>(
        stream: _shoppingController.obtenerLista(groupModel.id),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Lista Vacía
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  Text(
                    "La lista está vacía",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Lista con Datos
          final lista = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 80), // Espacio para el FAB
            itemCount: lista.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = lista[index];
              final fecha = item.fechaCreacion.toDate();
              final fechaStr = "${fecha.day}/${fecha.month}";

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorGrupo.withOpacity(0.1),
                  child: Text(
                    item.nombre.substring(0, 1).toUpperCase(),
                    style: TextStyle(color: colorGrupo, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  item.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text.rich(
                  TextSpan(
                    text: item.descripcion.isNotEmpty ? "${item.descripcion}\n" : "",
                    children: [
                      TextSpan(
                        text: "Añadido por ${_obtenerNombre(item.creadoPor)} el $fechaStr",
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                isThreeLine: item.descripcion.isNotEmpty, // Da más espacio si hay descripción
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    _shoppingController.eliminarProducto(groupModel.id, item.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }


  // Diálogo para añadir producto
  void _mostrarDialogoAnadir(BuildContext context, Color color) {
    final nombreController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Añadir a la lista"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: "Producto",
                hintText: "Nombre del producto...",
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: color)),
                labelStyle: TextStyle(color: color),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: "Nota (Opcional)",
                hintText: "Observaciones...",
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: color)),
                labelStyle: TextStyle(color: color),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (nombreController.text.trim().isNotEmpty) {
                _shoppingController.agregarProducto(
                  groupModel.id,
                  nombreController.text.trim(),
                  descController.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Añadir"),
          ),
        ],
      ),
    );
  }

  // Traduce ID -> Nombre usando los datos locales del grupo
  String _obtenerNombre(String uid) {
    if (groupModel.miembros.containsKey(uid)) {
      return groupModel.miembros[uid]!;
    }
    return "Alguien";
  }
}