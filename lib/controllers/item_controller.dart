import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/item_model.dart';

class ItemController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper para acceder a la colección
  CollectionReference _getCollection(String groupId) {
    return _firestore
        .collection('grupos')
        .doc(groupId)
        .collection('listaCompra');
  }

  // AGREGAR PRODUCTO
  Future<void> agregarProducto(String groupId, String nombre, String descripcion) async {
    try {
      final String userId = _auth.currentUser?.uid ?? 'anonimo';

      final newItem = {
        'nombre': nombre,
        'descripción': descripcion,
        'creadoPor': userId,
        'fechaCreacion': Timestamp.now(),
      };

      await _getCollection(groupId).add(newItem);
    } catch (e) {
      print("Error al agregar producto: $e");
      rethrow;
    }
  }

  // LEER LISTA (STREAM)
  // Ordenado solo por fecha (lo más nuevo arriba)
  Stream<List<ItemModel>> obtenerLista(String groupId) {
    return _getCollection(groupId)
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ItemModel.fromFirestore(doc))
          .toList();
    });
  }

  // ELIMINAR PRODUCTO
  Future<void> eliminarProducto(String groupId, String productId) async {
    await _getCollection(groupId).doc(productId).delete();
  }
}