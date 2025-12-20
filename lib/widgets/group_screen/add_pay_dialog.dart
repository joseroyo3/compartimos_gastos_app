import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/pay_controller.dart';
import '../../models/group_model.dart';
import '../../models/pay_model.dart';

class AddExpenseDialog extends StatefulWidget {
  final GroupModel groupModel;

  const AddExpenseDialog({super.key, required this.groupModel});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();

  String? _idPagadorSeleccionado;
  List<String> _idsInvolucrados = [];
  bool _estaGuardando = false;

  @override
  void initState() {
    super.initState();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != null && widget.groupModel.miembros.containsKey(currentUid)) {
      _idPagadorSeleccionado = currentUid;
    } else {
      _idPagadorSeleccionado = widget.groupModel.miembros.keys.first;
    }
    _idsInvolucrados = widget.groupModel.miembros.keys.toList();
  }

  @override
  Widget build(BuildContext context) {
    final Color colorGrupo = Color(widget.groupModel.colorValue);

    return AlertDialog(
      title: const Text("Nuevo Gasto"),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // CANTIDAD -----------
                TextFormField(
                  controller: _cantidadController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorGrupo),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: '0.00 €',
                    border: InputBorder.none,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+([.,]\d{0,2})?')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Introduce cantidad';
                    String cleanValue = value.replaceAll(',', '.');
                    if (double.tryParse(cleanValue) == null || double.parse(cleanValue) <= 0) {
                      return 'Mayor que 0';
                    }
                    return null;
                  },
                ),
                const Divider(),

                //DESCRIPCIÓN --------------------
                TextFormField(
                  controller: _descripcionController,
                  cursorColor: colorGrupo,
                  decoration: InputDecoration(
                    labelText: 'Concepto (Cena, Taxi...)',
                    prefixIcon: const Icon(Icons.description_outlined),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorGrupo)),
                    floatingLabelStyle: TextStyle(color: colorGrupo),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => value!.isEmpty ? 'Pon un nombre' : null,
                ),
                const SizedBox(height: 15),

                // QUIÉN PAGÓ -------------------------------------
                DropdownButtonFormField<String>(
                  value: _idPagadorSeleccionado,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Pagado por',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  items: widget.groupModel.miembros.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _idPagadorSeleccionado = value);
                  },
                ),
                const SizedBox(height: 15),

                // PARA QUIÉN -------------------------------------------
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Para quiénes:", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 5),

                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Column(
                    children: widget.groupModel.miembros.entries.map((entry) {
                      final uid = entry.key;
                      final nombre = entry.value;
                      final estaSeleccionado = _idsInvolucrados.contains(uid);

                      return CheckboxListTile(
                        title: Text(nombre),
                        value: estaSeleccionado,
                        activeColor: colorGrupo,
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _idsInvolucrados.add(uid);
                            } else {
                              if (_idsInvolucrados.length > 1) {
                                _idsInvolucrados.remove(uid);
                              }
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),

                if (_idsInvolucrados.length == 1 && _idsInvolucrados.contains(_idPagadorSeleccionado))
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Gasto individual (no genera deuda).",
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _estaGuardando ? null : _guardarGasto,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorGrupo,
            foregroundColor: Colors.white,
          ),
          child: _estaGuardando
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Guardar'),
        ),
      ],
    );
  }

  void _guardarGasto() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idsInvolucrados.isEmpty) return;

    setState(() => _estaGuardando = true);

    try {
      final double cantidad = double.parse(_cantidadController.text.replaceAll(',', '.'));
      final controller = PayController();

      final mapDistribucion = controller.calcularDistribucion(cantidad, _idsInvolucrados);

      final nuevoPago = PayModel(
        id: '',
        descripcion: _descripcionController.text.trim(),
        fecha: Timestamp.now(),
        cantidad: cantidad,
        idPagador: _idPagadorSeleccionado!,
        distribucion: mapDistribucion,
      );

      await controller.crearPago(widget.groupModel.id, nuevoPago);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print("Error guardando gasto: $e");
      setState(() => _estaGuardando = false);
    }
  }
}