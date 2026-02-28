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
                  Icon(Icons.shopping_basket_outlined,
                      size: 80, color: Colors.grey[300]),
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
                    item.nombre.isNotEmpty
                        ? item.nombre.substring(0, 1).toUpperCase()
                        : "?",
                    style: TextStyle(
                        color: colorGrupo, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  item.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text.rich(
                  TextSpan(
                    text: item.descripcion.isNotEmpty
                        ? "${item.descripcion}\n"
                        : "",
                    children: [
                      TextSpan(
                        text:
                            "Añadido por ${_obtenerNombre(item.creadoPor)} el $fechaStr",
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                isThreeLine: item.descripcion
                    .isNotEmpty, // Da más espacio si hay descripción
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    _shoppingController.eliminarProducto(
                        groupModel.id, item.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Diálogo para añadir varios productos
  void _mostrarDialogoAnadir(BuildContext context, Color color) {
    showDialog(
      context: context,
      barrierDismissible: false, // NO se cierra al dar fuera
      builder: (context) => _BulkAddDialog(
        color: color,
        onSave: (productos) {
          if (productos.isNotEmpty) {
            _shoppingController.agregarVariosProductos(
                groupModel.id, productos);
          }
        },
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

// Widget interno del diálogo para manejar su propio estado
class _BulkAddDialog extends StatefulWidget {
  final Color color;
  final Function(List<Map<String, String>>) onSave;

  const _BulkAddDialog({required this.color, required this.onSave});

  @override
  State<_BulkAddDialog> createState() => _BulkAddDialogState();
}

class _BulkAddDialogState extends State<_BulkAddDialog> {
  final List<Map<String, String>> _productosTemporales = [];
  final _nombreController = TextEditingController();
  final _descController = TextEditingController();

  void _anadirAListaTemporal() {
    final nombre = _nombreController.text.trim();
    if (nombre.isNotEmpty) {
      setState(() {
        _productosTemporales.add({
          'nombre': nombre,
          'descripcion': _descController.text.trim(),
        });
        _nombreController.clear();
        _descController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Añadir a la lista"),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Formulario para un producto
            TextField(
              controller: _nombreController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: "Producto",
                hintText: "Ej: Leche, Huevos...",
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: widget.color)),
                labelStyle: TextStyle(color: widget.color),
              ),
            ),
            TextField(
              controller: _descController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: "Nota (Opcional)",
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: widget.color)),
                labelStyle: TextStyle(color: widget.color),
              ),
              onSubmitted: (_) => _anadirAListaTemporal(),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _anadirAListaTemporal,
              icon: Icon(Icons.add_circle_outline, color: widget.color),
              label: Text("Añadir a la lista temporal",
                  style: TextStyle(color: widget.color)),
            ),
            const Divider(),
            // Lista de productos ya añadidos en el diálogo
            if (_productosTemporales.isNotEmpty)
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _productosTemporales.length,
                    itemBuilder: (context, index) {
                      final item = _productosTemporales[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(item['nombre']!,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: item['descripcion']!.isNotEmpty
                            ? Text(item['descripcion']!)
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.close,
                              size: 18, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _productosTemporales.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text("No hay productos añadidos aún",
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.color,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            // Si hay algo en los campos pero no se añadió a la lista temporal, lo añadimos
            if (_nombreController.text.trim().isNotEmpty) {
              _anadirAListaTemporal();
            }

            if (_productosTemporales.isNotEmpty) {
              widget.onSave(_productosTemporales);
              Navigator.pop(context);
            }
          },
          child: Text(
              "Guardar ${_productosTemporales.length > 0 ? '(${_productosTemporales.length})' : ''}"),
        ),
      ],
    );
  }
}
