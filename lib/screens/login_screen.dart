import 'package:compartimos_gastos/widgets/logo_widget.dart';
import 'package:compartimos_gastos/widgets/login_screen/auth_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/login_controller.dart';
import '../controllers/main_navigator_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  //final _emailCtrl = TextEditingController();
  final _emailCtrl = TextEditingController(
    text: 'joseroyo3@hotmail.com',
  ); // de momento se deja para acceder mas rápido
  final _passCtrl = TextEditingController();
  final _controller = LoginController();

  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  @override //
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _initPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
      if (_rememberMe) _emailCtrl.text = prefs.getString('savedEmail') ?? '';
    });
  }

  Future<void> _toggleRememberMe(bool value) async {
    setState(() => _rememberMe = value);
    final prefs = await SharedPreferences.getInstance();
    value
        ? await prefs.setString('savedEmail', _emailCtrl.text.trim())
        : await prefs.remove('savedEmail');
    await prefs.setBool('rememberMe', value);
  }

  Future<void> _executeAuth(
    Future<dynamic> Function() action, {
    bool validate = true,
  }) async {
    if (validate && !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    if (validate && _rememberMe) {
      await _toggleRememberMe(true);
    }

    final result = await action();

    if (mounted) {
      setState(() => _isLoading = false);
      // Feedback visual simple (error generico, no comprueba regex)
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error en la autenticación')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const LogoWidget(),

                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                  ),

                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Contraseña",
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),

                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (v) => _toggleRememberMe(v ?? false),
                    ),
                    const Text('Recordar usuario'),
                  ],
                ),

                const SizedBox(height: 24),

                if (_isLoading)
                  const CircularProgressIndicator()
                else ...[
                  //lista de widgets
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _executeAuth(
                        () => _controller.login(
                          _emailCtrl.text.trim(),
                          _passCtrl.text.trim(),
                        ),
                      ),
                      child: const Text("Entrar"),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // DIALOGS REGISTRO
                  TextButton(
                    onPressed: () =>
                        AuthDialogs.showRegister(context, _controller),
                    child: const Text("¿No tienes cuenta? Regístrate"),
                  ),

                  // DIALOGS RECUPERAR CONTRASEÑA
                  TextButton(
                    onPressed: () => AuthDialogs.showForgotPass(
                      context,
                      _emailCtrl,
                      _controller,
                    ),
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),

                  const SizedBox(height: 30),

                  // ANONIMO
                  SizedBox(
                    child: TextButton(
                      onPressed: () => _executeAuth(
                        () => _controller.signInAnonymously(),
                        validate: false,
                      ),
                      child: const Text("Entrar como Invitado"),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
