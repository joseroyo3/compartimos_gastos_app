import 'package:compartimos_gastos/widgets/logo_widget.dart';
import 'package:compartimos_gastos/widgets/login_screen/auth_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _controller = LoginController();

  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  @override
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
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 850) {
            // DESKTOP / TABLET HORIZONTAL
            return Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildHeroImage(isMobile: false),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(40),
                      child: _buildLoginForm(),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // MOBILE / TABLET VERTICAL
            return SingleChildScrollView(
              child: Column(
                children: [
                   _buildHeroImage(isMobile: true),
                  Transform.translate(
                    offset: const Offset(0, -30),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: _buildLoginForm(),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildHeroImage({required bool isMobile}) {
    return Stack(
      children: [
        Container(
          height: isMobile ? 350 : double.infinity,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/assets/images/login_hero.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          height: isMobile ? 350 : double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.6),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: isMobile ? 60 : 40,
          left: 30,
          right: 30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "¡Bienvenido de nuevo!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Gestiona tus gastos compartidos de forma sencilla y transparente.",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const LogoWidget(),
            const SizedBox(height: 20),
            Text(
              "Inicia Sesión",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "Introduce tus credenciales para continuar",
              style: TextStyle(color: Colors.blueGrey.shade400),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _emailCtrl,
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Contraseña",
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) => _toggleRememberMe(v ?? false),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Recordar usuario'),
                  ],
                ),
                TextButton(
                  onPressed: () => AuthDialogs.showForgotPass(
                    context,
                    _emailCtrl,
                    _controller,
                  ),
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator()
            else ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  onPressed: () => _executeAuth(
                    () => _controller.login(
                      _emailCtrl.text.trim(),
                      _passCtrl.text.trim(),
                    ),
                  ),
                  child: const Text(
                    "Entrar",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("¿No tienes cuenta?"),
                  TextButton(
                    onPressed: () =>
                        AuthDialogs.showRegister(context, _controller),
                    child: const Text("Regístrate"),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "O continúa con",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // Centered for cleaner look
                children: [
                  _socialButton(
                    icon: FontAwesomeIcons.google,
                    color: const Color(0xffDB4437),
                    onTap: () => _executeAuth(
                      () => _controller.signInWithGoogle(),
                      validate: false,
                    ),
                  ),
                  const SizedBox(width: 20),
                  _socialButton(
                    icon: FontAwesomeIcons.facebook,
                    color: const Color(0xff4267B2),
                    onTap: () => _executeAuth(
                      () => _controller.signInWithFacebook(),
                      validate: false,
                    ),
                  ),
                  const SizedBox(width: 20),
                  _socialButton(
                    icon: FontAwesomeIcons.apple,
                    color: Colors.black,
                    onTap: () => _executeAuth(
                      () => _controller.signInWithApple(),
                      validate: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              TextButton.icon(
                icon: const Icon(Icons.person_outline),
                onPressed: () => _executeAuth(
                  () => _controller.signInAnonymously(),
                  validate: false,
                ),
                label: const Text("Entrar como Invitado"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _socialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Center(
          child: FaIcon(
            icon,
            color: color,
            size: 24,
          ),
        ),
      ),
    );
  }
}
