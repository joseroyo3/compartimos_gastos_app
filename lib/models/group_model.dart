import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String nombre;
  final String creadoPor; // ID del usuario que creó el grupo
  final int color; // Cambiado de string a int para elegir el color predetermiado de la lista
  final Timestamp fechaCreacion;
  final List<String> miembros; // Lista de UIDs de los participantes

  GroupModel({
    required this.id,
    required this.nombre,
    required this.creadoPor,
    required this.color,
    required this.fechaCreacion,
    required this.miembros,
  });

  // DESDE FIRESTORE DATABASE (Cuando LEES un grupo)
  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    // Convertimos la data del documento a un Mapa seguro
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return GroupModel(
      id: doc.id, // El ID del documento es el ID del grupo
      nombre: data['nombre'] ?? 'Sin Nombre',
      creadoPor: data['creadoPor'] ?? '',
      color: data['color'] ?? '0',
      fechaCreacion: Timestamp.now(), //fecha actual de base
      miembros: List<String>.from(data['miembros'] ?? []),
    );
  }

  // HACIA FIRESTORE DATABASE (Para crear/sactualizar el grupo)
  Map<String, dynamic> toMap() {
    return {
      // 'id': id, no hace falta, está guardado "internamente"
      'nombre': nombre,
      'creadoPor': creadoPor,
      'color': color,
      'fechaCreacion': fechaCreacion,
      'miembros': miembros,
    };
  }

  // COPYWITH (Para actualizar la UI fácilmente)
  GroupModel copyWith({
    String? id,
    String? nombre,
    String? creadoPor,
    int? color,
    Timestamp? fechaCreacion,
    List<String>? miembros,
  }) {
    return GroupModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      creadoPor: creadoPor ?? this.creadoPor,
      color: color ?? this.color,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      miembros: miembros ?? this.miembros,
    );
  }
}