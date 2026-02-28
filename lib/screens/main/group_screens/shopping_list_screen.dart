import 'package:flutter/material.dart';
import '../../../controllers/item_controller.dart';
import '../../../models/group_model.dart';
import '../../../models/item_model.dart';
import '../../../widgets/appbar_custom.dart';
import 'settings_group_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  final GroupModel groupModel;

  ShoppingListScreen({super.key, required this.groupModel});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  // Instanciamos el controlador
  final ItemController _shoppingController = ItemController();

  // Estado para la selección masiva
  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};

  void _toggleSelection(String itemId) {
    setState(() {
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
        if (_selectedItems.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedItems.add(itemId);
      }
    });
  }

  void _enterSelectionMode(String itemId) {
    setState(() {
      _isSelectionMode = true;
      _selectedItems.add(itemId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedItems.clear();
    });
  }

  Future<void> _eliminarSeleccionados() async {
    final count = _selectedItems.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar productos"),
        content: Text(
            "¿Estás seguro de que quieres eliminar $count productos seleccionados?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _shoppingController.eliminarVariosProductos(
        widget.groupModel.id,
        _selectedItems.toList(),
      );
      _exitSelectionMode();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$count productos eliminados")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el color del grupo para el diseño
    final Color colorGrupo = Color(widget.groupModel.colorValue);

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: Colors.red[700],
              title: Text("${_selectedItems.length} seleccionados",
                  style: const TextStyle(color: Colors.white)),
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _exitSelectionMode,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _eliminarSeleccionados,
                ),
              ],
            )
          : CustomAppBar(
              title: 'Lista de Compra',
              showLogout: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Ajustes',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SettingsGroupScreen(groupModel: widget.groupModel),
                      ),
                    );
                  },
                ),
              ],
            ),
      // Botón para añadir producto (solo si no estamos seleccionando)
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              heroTag: "btn_add_producto",
              backgroundColor: colorGrupo,
              onPressed: () => _mostrarDialogoAnadir(context, colorGrupo),
              child: const Icon(Icons.add, color: Colors.white),
            ),

      body: StreamBuilder<List<ItemModel>>(
        stream: _shoppingController.obtenerLista(widget.groupModel.id),
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
            padding: EdgeInsets.only(bottom: _isSelectionMode ? 20 : 80),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = lista[index];
              final isSelected = _selectedItems.contains(item.id);
              final fecha = item.fechaCreacion.toDate();
              final fechaStr = "${fecha.day}/${fecha.month}";

              return ListTile(
                selected: isSelected,
                selectedTileColor: widget.groupModel.colorValue != null
                    ? Color(widget.groupModel.colorValue).withOpacity(0.05)
                    : Colors.grey[100],
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleSelection(item.id);
                  }
                },
                onLongPress: () {
                  if (!_isSelectionMode) {
                    _enterSelectionMode(item.id);
                  }
                },
                leading: _isSelectionMode
                    ? Checkbox(
                        value: isSelected,
                        activeColor: colorGrupo,
                        onChanged: (_) => _toggleSelection(item.id),
                      )
                    : CircleAvatar(
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
                isThreeLine: item.descripcion.isNotEmpty,
                trailing: _isSelectionMode
                    ? null
                    : IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmarBorradoIndividual(item),
                      ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmarBorradoIndividual(ItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar producto"),
        content: Text("¿Quieres eliminar \"${item.nombre}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              _shoppingController
                  .eliminarVariosProductos(widget.groupModel.id, [item.id]);
              Navigator.pop(context);
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  // Diálogo para añadir varios productos
  void _mostrarDialogoAnadir(BuildContext context, Color color) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BulkAddDialog(
        color: color,
        onSave: (productos) {
          if (productos.isNotEmpty) {
            _shoppingController.agregarVariosProductos(
                widget.groupModel.id, productos);
          }
        },
      ),
    );
  }

  String _obtenerNombre(String uid) {
    if (widget.groupModel.miembros.containsKey(uid)) {
      return widget.groupModel.miembros[uid]!;
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
