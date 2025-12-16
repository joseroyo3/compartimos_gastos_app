import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Función para GUARDAR
  Future<void> crearUsuario(UserModel usuario) async {
    await firestore.collection('usuarios').doc(usuario.id).set(usuario.toMap());
  }

  // Función para LEER
  Future<UserModel?> obtenerUsuario(String id) async {
    var doc = await firestore.collection('usuarios').doc(id).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // Función para ACTUALIZAR
  Future<void> actualizarUsuario(
    String uid,
    Map<String, dynamic> datosAActualizar,
  ) async {
    // .update solo modifica los campos que le pasas en el mapa, sin modificar el resto
    await firestore.collection('usuarios').doc(uid).update(datosAActualizar);
  }
}
