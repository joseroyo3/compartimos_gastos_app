import 'package:compartimos_gastos/controllers/user_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class LoginController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // REGISTRO
  Future<User?> register(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        UserModel nuevoUsuarioRegistrandose = UserModel.fromFirebase(user);

        // Llamamos al UserController para crearlo en la base de datos
        await UserController().crearUsuario(nuevoUsuarioRegistrandose);
        await user.sendEmailVerification();
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print("Error de registro: ${e.code} - ${e.message}");
      return null;
    }
  }

  // LOGIN
  Future<User?> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Error de login: ${e.code} - ${e.message}");
      return null;
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  // OBTENER USUARIO ACTUAL
  User? get currentUser => _auth.currentUser;

  // RECUPERAR CONTRASEÑA
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ACTUALIZAR CONTRASEÑA
  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  // VERIFICACION POR EMAIL EN CASO DE OLVIDO
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // CAMBIAR EMAIL
  Future<void> changeEmail(String newEmail) async {
    await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail);
  }

  /* ---------- USUARIOS ANONIMOS ---------- */

// INICIAR SESIÓN ANÓNIMA
  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
        UserModel usuarioAnonimo = UserModel(
          id: user.uid,
          email: '',
          nombre: 'Anónimo',
          fotoPerfil: '',
          grupos: [],
        );
        // Debemos registrar al anonimo para que pueda crear/entrar en grupos
        await UserController().crearUsuario(usuarioAnonimo);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print("Error anónimo: $e");
      return null;
    }
  }

  // USUARIO ANONIMO A REGISTRARSE
  Future<User?> linkAnonymousAccount(String email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      final userCredential =
          await _auth.currentUser?.linkWithCredential(credential);
      final user = userCredential?.user;

      if (user != null) {
        await UserController().actualizarUsuario(user.uid, {
          'email': email,
        });
        await user.sendEmailVerification();
      }

      return user;
    } catch (e) {
      print("Error vinculando cuenta: $e");
      return null;
    }
  }
}
