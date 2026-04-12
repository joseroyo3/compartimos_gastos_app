import 'package:compartimos_gastos/controllers/user_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

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

  // GOOGLE SIGN IN
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await _asegurarUsuarioEnFirestore(user);
      }
      return user;
    } catch (e) {
      print("Error Google: $e");
      return null;
    }
  }

  // FACEBOOK SIGN IN
  Future<User?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) return null;

      final OAuthCredential credential =
          FacebookAuthProvider.credential(result.accessToken!.token);
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await _asegurarUsuarioEnFirestore(user);
      }
      return user;
    } catch (e) {
      print("Error Facebook: $e");
      return null;
    }
  }

  // APPLE SIGN IN
  Future<User?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: _sha256ofString(rawNonce),
      );

      final OAuthCredential credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await _asegurarUsuarioEnFirestore(user);
      }
      return user;
    } catch (e) {
      print("Error Apple: $e");
      return null;
    }
  }

  // AUXILIARES
  Future<void> _asegurarUsuarioEnFirestore(User user) async {
    final userController = UserController();
    final usuarioExistente = await userController.obtenerUsuario(user.uid);

    if (usuarioExistente == null) {
      UserModel nuevoUsuario = UserModel.fromFirebase(user);
      await userController.crearUsuario(nuevoUsuario);
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
        length, (index) => charset[random % charset.length]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
