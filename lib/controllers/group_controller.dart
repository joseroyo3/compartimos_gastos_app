import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_model.dart';

class GroupController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Función para GUARDAR (Crear grupo)
  Future<void> crearGrupo(GroupModel grupo) async {
    // Guardamos el grupo en la colección 'grupos'
    await firestore.collection('grupos').doc(grupo.id).set(grupo.toMap());

    // ACTUALIZAMOS al usuario creador para que tenga este grupo en su lista
    await firestore.collection('usuarios').doc(grupo.creadoPor).update({
      'grupos': FieldValue.arrayUnion([grupo.id])
    });
  }

  // Función para LEER un solo grupo
  Future<GroupModel?> obtenerGrupo(String id) async {
    var doc = await firestore.collection('grupos').doc(id).get();
    if (!doc.exists) return null;
    return GroupModel.fromFirestore(doc);
  }

  // Función para ACTUALIZAR
  Future<void> actualizarGrupo(
    String groupId,
    Map<String, dynamic> datosAActualizar,
  ) async {
    await firestore.collection('grupos').doc(groupId).update(datosAActualizar);
  }

  Stream<List<GroupModel>> obtenerGruposStream() {
    // TODOS los grupos por UID
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return const Stream.empty(); // Por seguridad si no hay login

    return firestore
        .collection('grupos')
        .where('creadoPor', isEqualTo: uid)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => GroupModel.fromFirestore(doc)).toList()
    );
  }
}
