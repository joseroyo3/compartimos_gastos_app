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
    // Controladores
    final TextEditingController nombreGrupoController = TextEditingController();
    final TextEditingController nombreInvitadoController =
        TextEditingController();
    final TextEditingController codigoGrupoController = TextEditingController();

    Color colorDialogo = ThemeController.groupColors[0]['color'];
    bool esModoCrear = true;
    bool estaGuardando = false;
    List<String> listaInvitados = [];

    // Variables lógica selección de identidad
    Map<String, String>? miembrosEncontrados;
    String? idSeleccionado;
    bool codigoVerificado = false;

    final Color primaryColor = Theme.of(context).primaryColor;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Función para verificar código
            Future<void> verificarCodigo() async {
              if (codigoGrupoController.text.trim().isEmpty) return;

              // Quitamos el foco para cerrar el teclado antes de cambiar la UI
              FocusScope.of(context).unfocus();

              // Esperamos a que termine la animación del teclado para evitar errores de renderizado
              await Future.delayed(const Duration(milliseconds: 300));

              if (context.mounted) {
                setStateDialog(() => estaGuardando = true);
              }

              try {
                var miembros = await GroupController()
                    .obtenerMiembrosDelGrupo(codigoGrupoController.text.trim());

                if (context.mounted) {
                  setStateDialog(() {
                    miembrosEncontrados = miembros;
                    codigoVerificado = true;
                    estaGuardando = false;
                  });
                }
              } catch (e) {
                if (context.mounted) {
                  setStateDialog(() => estaGuardando = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Grupo no encontrado")),
                  );
                }
              }
            }

            return AlertDialog(
              titlePadding: EdgeInsets.zero,
              // Título con pestañas
              title: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setStateDialog(() {
                          esModoCrear = true;
                          miembrosEncontrados = null;
                          codigoVerificado = false;
                          codigoGrupoController.clear();
                        }),
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
                          child: Text("Crear",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color:
                                      esModoCrear ? primaryColor : Colors.grey,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
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
                          child: Text("Unirse",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color:
                                      !esModoCrear ? primaryColor : Colors.grey,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              content: SingleChildScrollView(
                // MaxFinite evita problemas de ancho en columnas dentro de diálogos
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // MODO CREAR
                      if (esModoCrear) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: nombreGrupoController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                              labelText: 'Nombre del grupo',
                              prefixIcon: Icon(Icons.group_add_outlined),
                              border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 15),
                        Row(children: [
                          const Text("Color: "),
                          const SizedBox(width: 10),
                          DropdownButton<Color>(
                              value: colorDialogo,
                              items: ThemeController.groupColors
                                  .map(
                                    (item) => DropdownMenuItem<Color>(
                                        value: item['color'],
                                        child: Row(children: [
                                          Icon(Icons.circle,
                                              color: item['color'], size: 16),
                                          const SizedBox(width: 10),
                                          Text(item['name'])
                                        ])),
                                  )
                                  .toList(),
                              onChanged: (c) =>
                                  setStateDialog(() => colorDialogo = c!))
                        ]),
                        const Divider(height: 30),
                        const Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Miembros iniciales:",
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                              child: TextField(
                                  controller: nombreInvitadoController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.all(10),
                                      border: OutlineInputBorder()))),
                          const SizedBox(width: 10),
                          IconButton(
                              style: IconButton.styleFrom(
                                  backgroundColor: primaryColor),
                              icon: const Icon(Icons.add, color: Colors.white),
                              onPressed: () {
                                if (nombreInvitadoController.text.isNotEmpty)
                                  setStateDialog(() {
                                    listaInvitados.add(
                                        nombreInvitadoController.text.trim());
                                    nombreInvitadoController.clear();
                                  });
                              })
                        ]),
                        if (listaInvitados.isNotEmpty)
                          Wrap(
                              spacing: 8,
                              children: listaInvitados
                                  .asMap()
                                  .entries
                                  .map((e) => Chip(
                                      label: Text(e.value),
                                      onDeleted: () => setStateDialog(() =>
                                          listaInvitados.removeAt(e.key))))
                                  .toList()),
                      ]

                      // MODO UNIRSE
                      else ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: codigoGrupoController,
                          // Reseteamos verificación si el usuario edita el texto
                          onChanged: (value) {
                            if (codigoVerificado) {
                              setStateDialog(() {
                                codigoVerificado = false;
                                miembrosEncontrados = null;
                                idSeleccionado = null;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Código del Grupo',
                            hintText: 'Ej: xYz123...',
                            border: const OutlineInputBorder(),
                            suffixIcon: !codigoVerificado
                                ? IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: verificarCodigo,
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.check,
                                        color: Colors.green),
                                    onPressed: null,
                                  ),
                          ),
                          onSubmitted: (_) => verificarCodigo(),
                        ),
                        if (codigoVerificado &&
                            miembrosEncontrados != null) ...[
                          const SizedBox(height: 20),
                          const Text("¿Quién eres tú en este grupo?",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 5),
                          const Text(
                              "Elige tu nombre si ya te añadieron, o únete como nuevo.",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8)),
                            child: ListView(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              children: [
                                RadioListTile<String?>(
                                  value: null,
                                  groupValue: idSeleccionado,
                                  title: const Text(
                                      "Soy nuevo (Unirme sin historial)"),
                                  secondary: const Icon(Icons.person_add_alt_1),
                                  onChanged: (val) => setStateDialog(
                                      () => idSeleccionado = val),
                                ),
                                const Divider(height: 1),
                                ...miembrosEncontrados!.entries.map((entry) {
                                  bool esInvitado =
                                      entry.key.startsWith('invitado_');
                                  if (!esInvitado)
                                    return const SizedBox.shrink();

                                  return RadioListTile<String?>(
                                    value: entry.key,
                                    groupValue: idSeleccionado,
                                    title: Text("Soy ${entry.value}"),
                                    subtitle: const Text(
                                        "Recuperar gastos asignados"),
                                    secondary: const Icon(Icons.face),
                                    onChanged: (val) => setStateDialog(
                                        () => idSeleccionado = val),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white),
                  onPressed: estaGuardando
                      ? null
                      : () async {
                          if (!esModoCrear && !codigoVerificado) {
                            verificarCodigo();
                            return;
                          }

                          setStateDialog(() => estaGuardando = true);
                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;

                            if (esModoCrear) {
                              // Crear
                              if (nombreGrupoController.text.trim().isEmpty) {
                                setStateDialog(() => estaGuardando = false);
                                return;
                              }
                              String newId = FirebaseFirestore.instance
                                  .collection('grupos')
                                  .doc()
                                  .id;
                              Map<String, String> mapaMiembros = {
                                user.uid: user.displayName ?? 'Yo'
                              };
                              for (var nombre in listaInvitados) {
                                String tempId =
                                    'invitado_${DateTime.now().microsecondsSinceEpoch}_${listaInvitados.indexOf(nombre)}';
                                mapaMiembros[tempId] = nombre;
                              }
                              final nuevoGrupo = GroupModel(
                                  id: newId,
                                  nombre: nombreGrupoController.text.trim(),
                                  creadoPor: user.uid,
                                  color: colorDialogo.value,
                                  fechaCreacion: Timestamp.now(),
                                  miembros: mapaMiembros);
                              await GroupController().crearGrupo(nuevoGrupo);
                            } else {
                              // Unirse
                              String groupId =
                                  codigoGrupoController.text.trim();
                              if (idSeleccionado == null) {
                                await GroupController().unirseAGrupo(groupId);
                              } else {
                                await GroupController()
                                    .unirseReemplazandoInvitado(
                                        groupId: groupId,
                                        guestId: idSeleccionado!);
                              }
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("¡Éxito!"),
                                      backgroundColor: Colors.green));
                            }
                          } catch (e) {
                            setStateDialog(() => estaGuardando = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text("Error: ${e.toString()}"),
                                      backgroundColor: Colors.red));
                            }
                          }
                        },
                  child: estaGuardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(esModoCrear
                          ? 'Crear Grupo'
                          : (!codigoVerificado ? 'Verificar' : 'Confirmar')),
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
      heroTag: 'fab_home',
      onPressed: () => _mostrarDialogoCrearGrupo(context),
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}
