import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String id;
  final String nombre;
  final String email;
  final String fotoPerfil;
  final List<String> grupos;

  UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.fotoPerfil,
    required this.grupos,
  });

  //DESDE AUTH (Cuando el usuario se registra/loguea)
  factory UserModel.fromFirebase(User user) {
    return UserModel(
      id: user.uid,
      nombre: user.displayName ?? '',
      email: user.email ?? 'no-email',
      fotoPerfil: user.photoURL ?? '',
      grupos: [], // Auth no tiene grupos, iniciamos vacío
    );
  }

  // DESDE FIRESTORE DATABASE (Cuando LEES la base de datos)
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    // Convertimos la data del documento a un Mapa seguro
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UserModel(
      id: doc.id, // El ID viene del documento, no de la data interna
      nombre: data['nombre'] ?? '',
      email: data['email'] ?? '',
      fotoPerfil: data['fotoPerfil'] ?? '',
      grupos: List<String>.from(data['grupos'] ?? []),
    );
  }

  // HACIA FIRESTORE DATABASE (Para guardar/actualizar)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'fotoPerfil': fotoPerfil,
      'grupos': grupos,
    };
  }

  // COPYWITH (Para actualizar la UI fácilmente)
  UserModel copyWith({
    String? id,
    String? nombre,
    String? email,
    String? fotoPerfil,
    List<String>? grupos,
  }) {
    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
      grupos: grupos ?? this.grupos,
    );
  }
}
