import 'package:cloud_firestore/cloud_firestore.dart';

class BalanceModel {
  final String id;
  final String deudorId; //  debe dinero
  final String acreedorId; //  le deben dinero
  final double cantidad;

  BalanceModel({
    required this.id,
    required this.deudorId,
    required this.acreedorId,
    required this.cantidad,
  });

  // LEER DE FIRESTORE
  factory BalanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return BalanceModel(
      id: doc.id,
      deudorId: data['deudorId'] ?? '',
      acreedorId: data['acreedorId'] ?? '',
      // Conversión segura de int a double por si acaso
      cantidad: (data['cantidad'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // GUARDAR EN FIRESTORE
  Map<String, dynamic> toMap() {
    return {
      'deudorId': deudorId,
      'acreedorId': acreedorId,
      'cantidad': cantidad,
    };
  }

  // COPYWITH
  BalanceModel copyWith({
    String? id,
    String? deudorId,
    String? acreedorId,
    double? cantidad,
  }) {
    return BalanceModel(
      id: id ?? this.id,
      deudorId: deudorId ?? this.deudorId,
      acreedorId: acreedorId ?? this.acreedorId,
      cantidad: cantidad ?? this.cantidad,
    );
  }
}
