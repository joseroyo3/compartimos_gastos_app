import 'dart:ui';
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
                      child: _buildLoginForm(isMobile: false),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // MOBILE / TABLET VERTICAL - EXPERT CENTERING
            return Stack(
              children: [
                // Full Screen Background
                _buildHeroImage(isMobile: true),

                // Centered Glassmorphic Card
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 40),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          padding: const EdgeInsets.all(24),
                          child: _buildLoginForm(isMobile: true),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
          height: double.infinity,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/assets/images/login_hero.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
        ),
        if (!isMobile) // Solo mostrar texto hero en desktop, en movil va dentro del card o arriba
          Positioned(
            bottom: 40,
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

  Widget _buildLoginForm({required bool isMobile}) {
    final Color textColor = isMobile ? Colors.white : Colors.black87;
    final Color subTextColor = isMobile ? Colors.white.withOpacity(0.8) : Colors.black54;
    final Color dividerColor = isMobile ? Colors.white24 : Colors.black12;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LogoWidget(),
            const SizedBox(height: 8),
            Text(
              "Inicia Sesión",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isMobile
                  ? "Accede a tu cuenta"
                  : "Introduce tus credenciales para continuar",
              textAlign: TextAlign.center,
              style: TextStyle(color: subTextColor),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailCtrl,
              style: TextStyle(color: isMobile ? Colors.black : Colors.black87),
              decoration: InputDecoration(
                filled: true,
                fillColor: isMobile ? Colors.white.withOpacity(0.9) : Colors.grey[100],
                labelText: "Email",
                labelStyle: TextStyle(color: isMobile ? Colors.blueGrey : Colors.grey[700]),
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isMobile ? Colors.transparent : Colors.grey.shade300),
                ),
              ),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passCtrl,
              obscureText: true,
              style: TextStyle(color: isMobile ? Colors.black : Colors.black87),
              decoration: InputDecoration(
                filled: true,
                fillColor: isMobile ? Colors.white.withOpacity(0.9) : Colors.grey[100],
                labelText: "Contraseña",
                labelStyle: TextStyle(color: isMobile ? Colors.blueGrey : Colors.grey[700]),
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isMobile ? Colors.transparent : Colors.grey.shade300),
                ),
              ),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _rememberMe, 
                          onChanged: (v) => _toggleRememberMe(v ?? false),
                          side: BorderSide(color: isMobile ? Colors.white : Colors.grey, width: 2),
                          checkColor: Colors.blue.shade700,
                          activeColor: isMobile ? Colors.white : Colors.blue.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Recordar',
                          style: TextStyle(fontSize: 13, color: textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => AuthDialogs.showForgotPass(
                    context,
                    _emailCtrl,
                    _controller,
                  ),
                  child: const Text(
                    '¿Olvidaste la clave?',
                    style: TextStyle(fontSize: 13),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.blue.withOpacity(0.5),
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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("¿Nuevo aquí?", style: TextStyle(fontSize: 14, color: textColor)),
                  TextButton(
                    onPressed: () =>
                        AuthDialogs.showRegister(context, _controller),
                    style: TextButton.styleFrom(
                      foregroundColor: isMobile ? Colors.white : Colors.blue.shade700,
                    ),
                    child: const Text("Regístrate",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider(color: dividerColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Social",
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider(color: dividerColor)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialButton(
                    icon: FontAwesomeIcons.google,
                    color: const Color(0xffDB4437),
                    onTap: () => _executeAuth(
                      () => _controller.signInWithGoogle(),
                      validate: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                icon: const Icon(Icons.person_outline, size: 18),
                onPressed: () => _executeAuth(
                  () => _controller.signInAnonymously(),
                  validate: false,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: isMobile ? Colors.white : Colors.blueGrey,
                ),
                label: const Text("Entrar como Invitado",
                    style: TextStyle(fontSize: 13)),
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
        height: 50,
        width: 50,
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
            size: 20,
          ),
        ),
      ),
    );
  }
}
