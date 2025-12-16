import 'package:compartimos_gastos/controllers/main_navigator_controller.dart';
import 'package:compartimos_gastos/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'controllers/themes_controller.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Compartimos Gastos',
      debugShowCheckedModeBanner: false,
      theme: ThemeController.tema,
      home: StreamBuilder<User?>(
        // escucha cambios
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Si está cargando -> pantalla de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Si existen credenciales guardadas, logea directomente
          if (snapshot.hasData) {
            return const MainNavigationController();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
