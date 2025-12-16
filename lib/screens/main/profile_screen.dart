import 'package:compartimos_gastos/widgets/appbar_custom.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/login_controller.dart';
import '../../controllers/user_controller.dart';
import '../../widgets/profile_screen/alert_dialog.dart';
import '../../widgets/profile_screen/custom_text_field.dart';
import '../../widgets/profile_screen/profile_action_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final LoginController _loginController = LoginController();
  final UserController _userController = UserController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _nameController.text = user?.displayName ?? '';
  }

  // recargar el usuario y refrescar la pantalla
  Future<void> _refreshUser() async {
    await user?.reload();
    setState(() {
      user = FirebaseAuth.instance.currentUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    // INVITADO -----------------------------------------------
    if (user!.isAnonymous) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Perfil de Invitado'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.no_accounts, size: 80, color: Colors.grey),
                const SizedBox(height: 20),

                const Text(
                  "Has entrado como invitado",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                const Text(
                  "Si cierras sesión o pierdes tu dispositivo, perderás tus datos. Regístrate para guardarlos.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize:16, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                ProfileActionButton(
                  icon: Icons.save_as,
                  text: 'Registrarse',
                  onPressed: () => _convertirInvitadoARegistrado(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // USUARIO REGISTRADO-----------------------------------------------
    return Scaffold(
      appBar: const CustomAppBar(title: 'Mi Perfil'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // CARD DE INFORMACIÓN
              _buildUserInfoCard(),
              const SizedBox(height: 20),

              // BOTÓN VERIFICAR EMAIL (Solo si falta verificar)
              if (!user!.emailVerified) ...[
                ProfileActionButton(
                  icon: Icons.mark_email_unread,
                  text: 'Verificar tu correo electrónico',
                  color: Colors.orange,
                  onPressed: () async {
                    await _loginController.sendEmailVerification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Correo enviado")),
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],

              // BOTÓN ACTUALIZAR PERFIL
              ProfileActionButton(
                icon: Icons.person_4,
                text: 'Actualizar Perfil',
                onPressed: () => _editarPerfil(context),
              ),
              const SizedBox(height: 10),

              // BOTÓN CAMBIAR CONTRASEÑA
              ProfileActionButton(
                icon: Icons.lock_reset,
                text: 'Cambiar Contraseña',
                onPressed: () => _cambiarContrasena(context),
              ),
              const SizedBox(height: 10),

              // BOTÓN CAMBIAR EMAIL
              ProfileActionButton(
                icon: Icons.alternate_email,
                text: 'Cambiar Email',
                onPressed: () => _cambiarEmail(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET DE LA PÁGINA NO REUTILIZABLE----------------------

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 4,// sombreado
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 10),

            Text(
              user?.displayName ?? 'Actualiza perfil e introduce nombre.',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            Text(
              user?.email ?? 'Sin Email',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 5),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: user!.emailVerified
                    ? Colors.green[100]
                    : Colors.orange[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                user!.emailVerified ? "Verificado" : "No Verificado",
                style: TextStyle(
                  color: user!.emailVerified ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // LÓGICA DE DIÁLOGS ----------------------------

  void _convertirInvitadoARegistrado(BuildContext context) {
    _emailController.clear();
    _passwordController.clear();

    showDialog(
      context: context,
      builder: (context) => CustomInputDialog(
        title: 'Registrar Cuenta',
        confirmText: 'Vincular Cuenta',
        children: [
          const Text("Introduce un email y contraseña para registrarte."),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 15),
          CustomTextField(
            controller: _passwordController,
            label: 'Contraseña',
            icon: Icons.lock,
            obscureText: true, //*******
          ),
        ],
        onConfirm: () async {
          if (_emailController.text.isEmpty ||
              _passwordController.text.length < 6) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Email inválido o contraseña minimo 6 caracteres',
                  ),
                ),
              );
            }
            return;
          }

          final usuario = await _loginController.linkAnonymousAccount(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

          if (usuario != null) {
            await _refreshUser();
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cuenta guardada con éxito!')),
              );
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error al vincular. Email en uso.'),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _cambiarContrasena(BuildContext context) {
    _passwordController.clear();
    showDialog(
      context: context,
      builder: (context) => CustomInputDialog(
        title: 'Cambiar Contraseña',
        confirmText: 'Actualizar',
        children: [
          const Text("Asegúrate de haber iniciado sesión recientemente."),
          const SizedBox(height: 10),
          CustomTextField(
            controller: _passwordController,
            label: 'Nueva contraseña',
            icon: Icons.lock,
            obscureText: true, // *****
          ),
        ],
        onConfirm: () async {
          await _loginController.updatePassword(
            _passwordController.text.trim(),
          );
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contraseña actualizada con éxito')),
            );
          }
        },
      ),
    );
  }

  void _cambiarEmail(BuildContext context) {
    _emailController.clear();
    showDialog(
      context: context,
      builder: (context) => CustomInputDialog(
        title: 'Cambiar Email',
        confirmText: 'Enviar verificación',
        children: [
          const Text("Se enviará un enlace al nuevo correo para confirmar."),
          const SizedBox(height: 10),
          CustomTextField(
            controller: _emailController,
            label: 'Nuevo correo electrónico',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
        onConfirm: () async {
          await _loginController.changeEmail(_emailController.text.trim());
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verificación enviada. Revisa tu nuevo correo.'),
              ),
            );
          }
        },
      ),
    );
  }

  void _editarPerfil(BuildContext context) {
    _nameController.text = '';
    showDialog(
      context: context,
      builder: (context) => CustomInputDialog(
        title: 'Actualizar Perfil',
        confirmText: 'Guardar',
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey,
                child: Icon(Icons.camera_alt, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _nameController,
            label: 'Nombre',
            icon: Icons.person,
          ),
          const SizedBox(height: 20),
        ],
        onConfirm: () async {
          String nuevoNombre = _nameController.text.trim();
          if (nuevoNombre.isNotEmpty) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Perfil actualizado correctamente')),
            );
            try {
              await user?.updateDisplayName(nuevoNombre);

              await _userController.actualizarUsuario(user!.uid, {
                'nombre': nuevoNombre,
              });

              await _refreshUser();
            } catch (e) {
              // SI FALLA ALGO, AVISAMOS
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hubo un problema de conexión: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }
}
