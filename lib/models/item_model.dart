import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String nombre;
  final String descripcion;
  final String creadoPor;
  final Timestamp fechaCreacion;

  ItemModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.creadoPor,
    required this.fechaCreacion,
  });

  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemModel(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      // Aceptamos con o sin tilde por seguridad
      descripcion: data['descripcion'] ?? data['descripción'] ?? '',
      creadoPor: data['creadoPor'] ?? '',
      fechaCreacion: data['fechaCreacion'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion, // Guardo sin tilde por estándar, pero puedes ponerla
      'creadoPor': creadoPor,
      'fechaCreacion': fechaCreacion,
    };
  }
}