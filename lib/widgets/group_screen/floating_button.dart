import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/group_controller.dart';
import '../../controllers/themes_controller.dart';
import '../../models/group_model.dart';

class FloattingButton extends StatelessWidget {
  const FloattingButton({super.key});

  void _mostrarDialogoCrearGrupo(BuildContext context) {
    // Controladores CREAR
    final TextEditingController nombreGrupoController = TextEditingController();
    final TextEditingController nombreInvitadoController =
        TextEditingController();

    // Controladores UNIRSE
    final TextEditingController codigoGrupoController = TextEditingController();

    // Estado del diálogo
    Color colorDialogo = ThemeController.groupColors[0]['color'];

    // Estado para cambiar de pestaña
    bool esModoCrear = true;

    // Estado de carga para evitar doble click
    bool estaGuardando = false;

    // Lista temporal
    List<String> listaInvitados = [];

    // Color principal
    final Color primaryColor = Theme.of(context).primaryColor;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              titlePadding: EdgeInsets.zero,

              // TITULO CON PESTAÑAS -------------------------------------------
              title: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(
                  children: [
                    // PESTAÑA CREAR
                    Expanded(
                      child: InkWell(
                        onTap: () => setStateDialog(() => esModoCrear = true),
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(28)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            border: esModoCrear
                                ? Border(
                                    bottom: BorderSide(
                                        color: primaryColor, width: 3))
                                : null,
                          ),
                          child: Text(
                            "Crear",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: esModoCrear ? primaryColor : Colors.grey,
                              fontWeight: esModoCrear
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // PESTAÑA UNIRSE
                    Expanded(
                      child: InkWell(
                        onTap: () => setStateDialog(() => esModoCrear = false),
                        borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(28)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            border: !esModoCrear
                                ? Border(
                                    bottom: BorderSide(
                                        color: primaryColor, width: 3))
                                : null,
                          ),
                          child: Text(
                            "Unirse",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !esModoCrear ? primaryColor : Colors.grey,
                              fontWeight: !esModoCrear
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // BODY -------------------------------------------
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //  VISTA CREAR GRUPO =====================
                    if (esModoCrear) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: nombreGrupoController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del grupo',
                          prefixIcon: Icon(Icons.group_add_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Selector de Color
                      Row(
                        children: [
                          const Text("Color: "),
                          const SizedBox(width: 10),
                          DropdownButton<Color>(
                            value: colorDialogo,
                            items: ThemeController.groupColors.map((item) {
                              return DropdownMenuItem<Color>(
                                value: item['color'],
                                child: Row(
                                  children: [
                                    Icon(Icons.circle,
                                        color: item['color'], size: 16),
                                    const SizedBox(width: 10),
                                    Text(item['name']),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (Color? newColor) {
                              if (newColor != null) {
                                setStateDialog(() => colorDialogo = newColor);
                              }
                            },
                          ),
                        ],
                      ),

                      const Divider(height: 30),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Miembros:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 10),

                      // MIEMBROS
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nombreInvitadoController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            style: IconButton.styleFrom(
                                backgroundColor: primaryColor),
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: () {
                              if (nombreInvitadoController.text
                                  .trim()
                                  .isNotEmpty) {
                                setStateDialog(() {
                                  listaInvitados.add(
                                      nombreInvitadoController.text.trim());
                                  nombreInvitadoController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      if (listaInvitados.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8.0,
                          children: listaInvitados.asMap().entries.map((entry) {
                            return Chip(
                              label: Text(entry.value),
                              onDeleted: () => setStateDialog(
                                  () => listaInvitados.removeAt(entry.key)),
                            );
                          }).toList(),
                        ),
                      ],
                    ]

                    // VISTA UNIRSE =====================
                    else ...[
                      const SizedBox(height: 20),
                      const Text(
                        "Introduce el Código del Grupo",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: codigoGrupoController,
                        decoration: InputDecoration(
                          hintText: 'Ej: xYz123...',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.paste),
                            onPressed: () async {
                              final data =
                                  await Clipboard.getData(Clipboard.kTextPlain);
                              if (data?.text != null) {
                                codigoGrupoController.text = data!.text!;
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),

                // BOTÓN DE ACCIÓN
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  // Si está guardando, deshabilitamos el botón
                  onPressed: estaGuardando
                      ? null
                      : () async {
                          // Mostrar carga
                          setStateDialog(() => estaGuardando = true);

                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;

                            if (esModoCrear) {
                              // LÓGICA DE CREAR GRUPO
                              if (nombreGrupoController.text.trim().isEmpty) {
                                setStateDialog(() => estaGuardando = false);
                                return;
                              }

                              // Generamos ID nuevo
                              String newId = FirebaseFirestore.instance
                                  .collection('grupos')
                                  .doc()
                                  .id;

                              // Mapa de miembros, yo e invitados
                              Map<String, String> mapaMiembros = {
                                user.uid: user.displayName ?? 'Yo',
                              };

                              // Invitados con ID temporal
                              for (var nombreInvitado in listaInvitados) {
                                String tempId =
                                    'invitado_${DateTime.now().microsecondsSinceEpoch}_${listaInvitados.indexOf(nombreInvitado)}';
                                mapaMiembros[tempId] = nombreInvitado;
                              }

                              // Creamos el objeto
                              final nuevoGrupo = GroupModel(
                                id: newId,
                                nombre: nombreGrupoController.text.trim(),
                                creadoPor: user.uid,
                                color: colorDialogo
                                    .value, //guardamos el valor del color
                                fechaCreacion: Timestamp.now(),
                                miembros: mapaMiembros,
                              );

                              await GroupController().crearGrupo(nuevoGrupo);

                              // Navegaremos y cerrar
                              if (context.mounted) {
                                Navigator.pop(context); // Cerrar diálogo
                              }
                            } else {
                              // LÓGICA DE UNIRSE (ToDo)
                              print("Por implementar");
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            print("Error creando grupo: $e");
                            setStateDialog(() => estaGuardando = false);
                          }
                        },
                  child: estaGuardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(esModoCrear ? 'Crear Grupo' : 'Unirse'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _mostrarDialogoCrearGrupo(context),
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}
