import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../controllers/login_controller.dart';


// Clase que usaremos solo para los dialogs de login screen
abstract class AuthDialogs {
  static void showForgotPass(
    BuildContext context,
    TextEditingController
    emailCtrl, // Reutilizamos el controller para que el usuario no reescriba su email
    LoginController controller,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress, // teclado estandar pero comprobando @ y .
          decoration: const InputDecoration(labelText: 'Tu email'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailCtrl.text.isEmpty) return;

              // Navigator.pop antes de operaciones asíncronas largas para cerrar rapido
              Navigator.pop(ctx);

              await controller.sendPasswordResetEmail(emailCtrl.text.trim());

              // Verificamos 'mounted' del contexto original (context) no del diálogo (ctx)
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Email enviado')));
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  static void showRegister(BuildContext context, LoginController controller) {
    // Definimos controllers locales
    final rEmail = TextEditingController();
    final rPass = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rEmail,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: rPass,
              obscureText: true, // salen *******
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (rEmail.text.isEmpty || rPass.text.isEmpty) return;

              Navigator.pop(ctx);

              // Creamos usuario en auth
              User? usuario = await controller.register(
                rEmail.text.trim(),
                rPass.text.trim(),
              );

              // Comprobamamos que no sea null (que hay usuario y conexion)
              if (usuario != null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Registrado con éxito. Verifica tu email.')),
                  );
                }
              } else {
                // Si usuario es null, mostramos error generico
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email en uso o sin red.')),
                  );
                }
              }
            },
            child: const Text('Registrarse'),
          ),
        ],
      ),
    );
  }
}
