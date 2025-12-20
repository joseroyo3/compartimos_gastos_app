import 'package:cloud_firestore/cloud_firestore.dart';

class PayModel {
  final String id;
  final String descripcion;
  final Timestamp fecha;
  final double cantidad; // Total pagado
  final String idPagador; // De quien paga
  final Map<String, double> distribucion; // Cuánto le toca a cada uno

  PayModel({
    required this.id,
    required this.descripcion,
    required this.fecha,
    required this.cantidad,
    required this.idPagador,
    required this.distribucion,
  });

  // LEER DE FIRESTORE
  factory PayModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    Map<String, double> distMap = {};
    if (data['distribucion'] != null) {
      final rawMap = data['distribucion'] as Map<String, dynamic>;
      rawMap.forEach((key, value) {
        distMap[key] = (value as num).toDouble();
      });
    }

    return PayModel(
      id: doc.id,
      descripcion: data['descripcion'] ?? 'Sin descripción',
      fecha: data['fecha'] ?? Timestamp.now(),
      cantidad: (data['cantidad'] as num?)?.toDouble() ?? 0.0,
      idPagador: data['idPagador'] ?? '',
      distribucion: distMap,
    );
  }

  // GUARDAR EN FIRESTORE
  Map<String, dynamic> toMap() {
    return {
      'descripcion': descripcion,
      'fecha': fecha,
      'cantidad': cantidad,
      'idPagador': idPagador,
      'distribucion': distribucion,
    };
  }

  // COPYWITH
  PayModel copyWith({
    String? id,
    String? descripcion,
    Timestamp? fecha,
    double? cantidad,
    String? idPagador,
    Map<String, double>? distribucion,
  }) {
    return PayModel(
      id: id ?? this.id,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
      cantidad: cantidad ?? this.cantidad,
      idPagador: idPagador ?? this.idPagador,
      distribucion: distribucion ?? this.distribucion,
    );
  }
}
