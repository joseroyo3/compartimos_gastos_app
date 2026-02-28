import 'package:cloud_firestore/cloud_firestore.dart';
import 'balance_model.dart';
import 'item_model.dart';

class GroupModel {
  final String id;
  final String nombre;
  final String creadoPor; // ID del usuario que creó el grupo
  final int
      color; // Cambiado de string a int para elegir el color predetermiado de la lista
  final Timestamp fechaCreacion;
  final Map<String, String>
      miembros; // tambien debe ser Map, debo guardar nombre y uid
  final Map<String, double> netos; // Nuevo: Saldo neto por usuario {uid: saldo}
  final List<BalanceModel>
      balances; // Nuevo: Deudas simplificadas ya calculadas
  final List<ItemModel> listaCompra; // Nuevo: Lista de la compra centralizada

  GroupModel({
    required this.id,
    required this.nombre,
    required this.creadoPor,
    required this.color,
    required this.fechaCreacion,
    required this.miembros,
    this.netos = const {},
    this.balances = const [],
    this.listaCompra = const [],
  });

  int get colorValue => color;

  // DESDE FIRESTORE DATABASE (Cuando LEES un grupo)
  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    // Convertimos la data del documento a un Mapa seguro
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Mapear netos (Firestore guarda double o int, convertimos a double)
    Map<String, double> netosTemp = {};
    if (data['netos'] != null) {
      (data['netos'] as Map<String, dynamic>).forEach((key, value) {
        netosTemp[key] = (value as num).toDouble();
      });
    }

    // Mapear balances simplificados
    List<BalanceModel> balancesTemp = [];
    if (data['balancesSimplificados'] != null) {
      balancesTemp = (data['balancesSimplificados'] as List)
          .map((b) => BalanceModel(
                id: '', // No hace falta ID para balances internos
                deudorId: b['deudorId'] ?? '',
                acreedorId: b['acreedorId'] ?? '',
                cantidad: (b['cantidad'] as num?)?.toDouble() ?? 0.0,
              ))
          .toList();
    }

    // Mapear lista de compra
    List<ItemModel> itemsTemp = [];
    if (data['listaCompraCentralizada'] != null) {
      itemsTemp = (data['listaCompraCentralizada'] as List)
          .map((i) => ItemModel(
                id: i['id'] ?? '',
                nombre: i['nombre'] ?? '',
                descripcion: i['descripción'] ?? '',
                creadoPor: i['creadoPor'] ?? '',
                fechaCreacion: i['fechaCreacion'] ?? Timestamp.now(),
              ))
          .toList();
    }

    return GroupModel(
      id: doc.id, // El ID del documento es el ID del grupo
      nombre: data['nombre'] ?? 'Sin Nombre',
      creadoPor: data['creadoPor'] ?? '',
      color: data['color'] ?? 4280391411,
      fechaCreacion:
          data['fechaCreacion'] ?? Timestamp.now(), // guardada, no actual
      miembros: Map<String, String>.from(data['miembros'] ?? {}),
      netos: netosTemp,
      balances: balancesTemp,
      listaCompra: itemsTemp,
    );
  }

  // HACIA FIRESTORE DATABASE (Para crear/actualizar el grupo)
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'creadoPor': creadoPor,
      'color': color,
      'fechaCreacion': fechaCreacion,
      'miembros': miembros,
      'netos': netos,
      'balancesSimplificados': balances.map((b) => b.toMap()).toList(),
      'listaCompraCentralizada': listaCompra
          .map((i) => {
                'id': i.id,
                'nombre': i.nombre,
                'descripción': i.descripcion,
                'creadoPor': i.creadoPor,
                'fechaCreacion': i.fechaCreacion,
              })
          .toList(),
    };
  }

  // COPYWITH (Para actualizar la UI fácilmente)
  GroupModel copyWith({
    String? id,
    String? nombre,
    String? creadoPor,
    int? color,
    Timestamp? fechaCreacion,
    Map<String, String>? miembros,
    Map<String, double>? netos,
    List<BalanceModel>? balances,
  }) {
    return GroupModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      creadoPor: creadoPor ?? this.creadoPor,
      color: color ?? this.color,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      miembros: miembros ?? this.miembros,
      netos: netos ?? this.netos,
      balances: balances ?? this.balances,
    );
  }
}
