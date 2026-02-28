import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/item_model.dart';
import '../models/group_model.dart';

class ItemController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // AGREGAR PRODUCTO (AHORA CENTRALIZADO)
  Future<void> agregarProducto(
      String groupId, String nombre, String descripcion) async {
    final groupRef = _firestore.collection('grupos').doc(groupId);

    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(groupRef);
      if (!snap.exists) return;

      final group = GroupModel.fromFirestore(snap);
      final List<ItemModel> nuevaLista = List.from(group.listaCompra);

      final String userId = _auth.currentUser?.uid ?? 'anonimo';
      final newItem = ItemModel(
        id: _firestore.collection('tmp').doc().id, // ID local único
        nombre: nombre,
        descripcion: descripcion,
        creadoPor: userId,
        fechaCreacion: Timestamp.now(),
      );

      nuevaLista.add(newItem);

      transaction.update(groupRef, {
        'listaCompraCentralizada': nuevaLista
            .map((i) => {
                  'id': i.id,
                  'nombre': i.nombre,
                  'descripción': i.descripcion,
                  'creadoPor': i.creadoPor,
                  'fechaCreacion': i.fechaCreacion,
                })
            .toList(),
      });
    });
  }

  // LEER LISTA (AHORA DEL DOCUMENTO DEL GRUPO)
  Stream<List<ItemModel>> obtenerLista(String groupId) {
    return _firestore.collection('grupos').doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return [];
      final group = GroupModel.fromFirestore(doc);
      // Devolver ordenada por fecha (más nuevo arriba)
      final lista = List<ItemModel>.from(group.listaCompra);
      lista.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
      return lista;
    });
  }

  // ELIMINAR PRODUCTO
  Future<void> eliminarProducto(String groupId, String productId) async {
    final groupRef = _firestore.collection('grupos').doc(groupId);

    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(groupRef);
      if (!snap.exists) return;

      final group = GroupModel.fromFirestore(snap);
      final List<ItemModel> nuevaLista = List.from(group.listaCompra);

      nuevaLista.removeWhere((item) => item.id == productId);

      transaction.update(groupRef, {
        'listaCompraCentralizada': nuevaLista
            .map((i) => {
                  'id': i.id,
                  'nombre': i.nombre,
                  'descripción': i.descripcion,
                  'creadoPor': i.creadoPor,
                  'fechaCreacion': i.fechaCreacion,
                })
            .toList(),
      });
    });
  }

  // ELIMINAR VARIOS PRODUCTOS DE GOLPE
  Future<void> eliminarVariosProductos(
      String groupId, List<String> productIds) async {
    if (productIds.isEmpty) return;

    final groupRef = _firestore.collection('grupos').doc(groupId);

    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(groupRef);
      if (!snap.exists) return;

      final group = GroupModel.fromFirestore(snap);
      final List<ItemModel> nuevaLista = List.from(group.listaCompra);

      nuevaLista.removeWhere((item) => productIds.contains(item.id));

      transaction.update(groupRef, {
        'listaCompraCentralizada': nuevaLista
            .map((i) => {
                  'id': i.id,
                  'nombre': i.nombre,
                  'descripción': i.descripcion,
                  'creadoPor': i.creadoPor,
                  'fechaCreacion': i.fechaCreacion,
                })
            .toList(),
      });
    });
  }

  // AGREGAR VARIOS PRODUCTOS DE GOLPE (OPTIMIZADO: 1 ESCRITURA)
  Future<void> agregarVariosProductos(
      String groupId, List<Map<String, String>> productos) async {
    if (productos.isEmpty) return;

    final groupRef = _firestore.collection('grupos').doc(groupId);
    final String userId = _auth.currentUser?.uid ?? 'anonimo';
    final now = Timestamp.now();

    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(groupRef);
      if (!snap.exists) return;

      final group = GroupModel.fromFirestore(snap);
      final List<ItemModel> nuevaLista = List.from(group.listaCompra);

      for (var prod in productos) {
        nuevaLista.add(ItemModel(
          id: _firestore.collection('tmp').doc().id,
          nombre: prod['nombre'] ?? '',
          descripcion: prod['descripcion'] ?? '',
          creadoPor: userId,
          fechaCreacion: now,
        ));
      }

      transaction.update(groupRef, {
        'listaCompraCentralizada': nuevaLista
            .map((i) => {
                  'id': i.id,
                  'nombre': i.nombre,
                  'descripción': i.descripcion,
                  'creadoPor': i.creadoPor,
                  'fechaCreacion': i.fechaCreacion,
                })
            .toList(),
      });
    });
  }
}
