import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../controllers/group_controller.dart';

class DetailGroupDialog extends StatelessWidget {
  final dynamic pago;
  final String groupId; // Necesario para recuperar los miembros del grupo
  final Color color;

  const DetailGroupDialog({
    super.key,
    required this.pago,
    required this.groupId,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final GroupController groupController = GroupController();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      // Cargamos los miembros del grupo para traducir UIDs a nombres
      content: FutureBuilder<Map<String, String>>(
        future: groupController.obtenerMiembrosDelGrupo(groupId),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return const Text("Error al cargar los datos");
          }

          final miembros = snapshot.data ?? {};

          // Mapeo de datos para la vista
          final String nombrePagador = miembros[pago.idPagador] ?? 'Desconocido';
          final String fechaBonita = _formatearFecha(pago.fecha);

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(Icons.receipt_long, color: color),
                  ),
                  const SizedBox(width: 10),
                  const Text("Detalle del Gasto", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 20),

              // Importe principal
              Center(
                child: Text(
                  "${pago.cantidad.toStringAsFixed(2)} €",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _infoRow(Icons.description, "Concepto", pago.descripcion),
              const SizedBox(height: 15),

              _infoRow(Icons.person, "Pagado por", nombrePagador),
              const SizedBox(height: 15),

              _infoRow(Icons.calendar_today, "Fecha", fechaBonita),

              const SizedBox(height: 20),
              const Divider(),

              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    "Participantes",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
              ),

              // Generación de usuarios
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                alignment: WrapAlignment.center,
                children: _generarParticipantes(pago.distribucion, miembros),
              )
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cerrar"),
        ),
      ],
    );
  }

  String _formatearFecha(dynamic fecha) {
    DateTime date;
    if (fecha is Timestamp) {
      date = fecha.toDate();
    } else if (fecha is DateTime) {
      date = fecha;
    } else {
      return "Fecha desconocida";
    }
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  // Crea la lista visual de participantes involucrados en el gasto
  List<Widget> _generarParticipantes(Map<String, dynamic> distribucion, Map<String, String> nombres) {
    List<String> idsParticipantes = distribucion.keys.toList();

    return idsParticipantes.map((uid) {
      String nombre = nombres[uid] ?? 'Usuario';
      return Chip(
        label: Text(nombre, style: const TextStyle(fontSize: 12)),
        backgroundColor: Colors.grey[200],
        avatar: CircleAvatar(
          backgroundColor: Colors.grey[400],
          child: Text(nombre[0].toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)),
        ),
      );
    }).toList();
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}