import 'package:compartimos_gastos/controllers/group_controller.dart';
import 'package:compartimos_gastos/screens/main/group_screens/settings_group_screen.dart';
import 'package:flutter/material.dart';
import '../../../controllers/pay_controller.dart';
import '../../../controllers/themes_controller.dart';
import '../../../models/group_model.dart';
import '../../../models/pay_model.dart';
import '../../../widgets/appbar_custom.dart';
import '../../../widgets/group_screen/add_pay_dialog.dart';
import '../../../widgets/responsive_list_container.dart';

class GroupScreen extends StatefulWidget {
  final GroupModel groupModel;

  const GroupScreen({super.key, required this.groupModel});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final PayController _paymentController = PayController();
  final GroupController _groupController = GroupController();

  // Estado para la selección masiva
  bool _isSelectionMode = false;
  final Set<PayModel> _selectedPagos = {};

  void _toggleSelection(PayModel pago) {
    setState(() {
      if (_selectedPagos.any((p) => p.id == pago.id)) {
        _selectedPagos.removeWhere((p) => p.id == pago.id);
        if (_selectedPagos.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedPagos.add(pago);
      }
    });
  }

  void _enterSelectionMode(PayModel pago) {
    setState(() {
      _isSelectionMode = true;
      _selectedPagos.add(pago);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedPagos.clear();
    });
  }

  Future<void> _eliminarSeleccionados(GroupModel liveGroup) async {
    final count = _selectedPagos.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar gastos"),
        content: Text(
            "¿Estás seguro de que quieres eliminar $count gastos seleccionados?\n\nSe recalcularán las deudas."),
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
      await _paymentController.eliminarVariosPagos(
        liveGroup.id,
        _selectedPagos.toList(),
      );
      _exitSelectionMode();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("$count gastos eliminados y balances actualizados")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GroupModel?>(
      stream: _groupController.obtenerDetallesGrupoStream(widget.groupModel.id),
      initialData: widget.groupModel,
      builder: (context, groupSnapshot) {
        final liveGroup = groupSnapshot.data ?? widget.groupModel;
        final Color colorGrupo = Color(liveGroup.colorValue);

        return Theme(
          data: ThemeController.crearTema(colorGrupo),
          child: Scaffold(
            appBar: _isSelectionMode
                ? AppBar(
                    backgroundColor: Colors.red[700],
                    title: Text("${_selectedPagos.length} seleccionados",
                        style: const TextStyle(color: Colors.white)),
                    leading: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _exitSelectionMode,
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () => _eliminarSeleccionados(liveGroup),
                      ),
                    ],
                  )
                : CustomAppBar(
                    title: liveGroup.nombre,
                    showLogout: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.settings),
                        tooltip: 'Ajustes',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsGroupScreen(
                                  groupModel: liveGroup),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
            floatingActionButton: _isSelectionMode
                ? null
                : FloatingActionButton(
                    heroTag: "btn_add_gasto",
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AddExpenseDialog(groupModel: liveGroup);
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
                Expanded(
                  child: StreamBuilder<List<PayModel>>(
                    stream: _paymentController
                        .obtenerPagosDelGrupo(liveGroup.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

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

                      var pagos = snapshot.data!;

                      return ResponsiveListContainer(
                        child: ListView.builder(
                          itemCount: pagos.length,
                          itemBuilder: (context, index) {
                            final pago = pagos[index];
                            final isSelected =
                                _selectedPagos.any((p) => p.id == pago.id);

                            final date = pago.fecha.toDate();
                            String fechaFormateada =
                                "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}";

                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: colorGrupo.withOpacity(0.05),
                              onTap: () {
                                if (_isSelectionMode) {
                                  _toggleSelection(pago);
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AddExpenseDialog(
                                      groupModel: liveGroup,
                                      existingPay: pago,
                                    ),
                                  );
                                }
                              },
                              onLongPress: () {
                                if (!_isSelectionMode) {
                                  _enterSelectionMode(pago);
                                }
                              },
                              leading: _isSelectionMode
                                  ? Checkbox(
                                      value: isSelected,
                                      activeColor: colorGrupo,
                                      onChanged: (_) => _toggleSelection(pago),
                                    )
                                  : CircleAvatar(
                                      backgroundColor: colorGrupo,
                                      child: const Icon(Icons.shopping_bag,
                                          color: Colors.white),
                                    ),
                              title: Text(
                                pago.descripcion,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "Pagado por: ${_obtenerNombre(pago.idPagador, liveGroup)}",
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              trailing: _isSelectionMode
                                  ? null
                                  : Column(
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
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _obtenerNombre(String uid, GroupModel liveGroup) {
    if (liveGroup.miembros.containsKey(uid)) {
      return liveGroup.miembros[uid]!;
    }
    return "Usuario";
  }
}
