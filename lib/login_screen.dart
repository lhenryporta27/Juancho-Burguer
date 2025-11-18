import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔥 IMPORTA LAS PANTALLAS SEGÚN ROL
import 'platos/categorias_screen.dart';
import 'platos_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenScreenState createState() => _LoginScreenScreenState();
}

class _LoginScreenScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nombreController = TextEditingController();

  bool isLogin = true;
  bool cargando = false;

  bool mostrarPassword = false;
  bool mostrarPasswordConfirm = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideLogo;
  late Animation<Offset> _slideInputs;
  late Animation<Offset> _slideButton;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideLogo = Tween(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _slideInputs = Tween(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideButton = Tween(
      begin: const Offset(0, 2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ============================================================
  // 🔥 VALIDACIONES
  // ============================================================

  bool _emailValido(String email) {
    final exp = RegExp(r"^[\w\.-]+@gmail\.com$"); // SOLO gmail.com
    return exp.hasMatch(email);
  }

  String _errorMessage(Object e) {
    final msg = e.toString();

    if (msg.contains("email-already-in-use"))
      return "El correo ya está registrado.";
    if (msg.contains("invalid-email")) return "Formato de correo inválido.";
    if (msg.contains("wrong-password")) return "Contraseña incorrecta.";
    if (msg.contains("user-not-found")) return "Usuario no encontrado.";
    if (msg.contains("weak-password")) return "Contraseña demasiado débil.";

    return "Error: ${e.toString()}";
  }

  // ============================================================
  // 🔥 REGISTRO
  // ============================================================
  Future<void> _register() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();
    final nombre = _nombreController.text.trim();

    if (email.isEmpty ||
        pass.isEmpty ||
        confirmPass.isEmpty ||
        nombre.isEmpty) {
      return _alert("Completa todos los campos");
    }

    if (!_emailValido(email)) {
      return _alert(
        "Debe ser un correo Gmail válido. Ejemplo: usuario@gmail.com",
      );
    }

    if (pass.length < 6) {
      return _alert("La contraseña debe tener mínimo 6 caracteres.");
    }

    if (pass.contains(" ")) {
      return _alert("La contraseña no debe contener espacios.");
    }

    if (pass != confirmPass) {
      return _alert("Las contraseñas no coinciden.");
    }

    try {
      setState(() => cargando = true);

      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      await _db.collection("Usuarios").doc(userCred.user!.uid).set({
        "nombre": nombre,
        "email": email,
        "rol": "cliente",
        "telefono": "",
      });

      if (!mounted) return;

      _alert("Usuario registrado correctamente ✓");

      setState(() => isLogin = true);
    } catch (e) {
      if (!mounted) return;
      _alert(_errorMessage(e));
    } finally {
      setState(() => cargando = false);
    }
  }

  // ============================================================
  // 🔥 LOGIN
  // ============================================================
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      return _alert("Completa correo y contraseña");
    }

    if (!_emailValido(email)) {
      return _alert("Debe ser un correo Gmail válido.");
    }

    try {
      setState(() => cargando = true);

      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      final user = cred.user;
      if (user == null) throw Exception("No se pudo obtener el usuario.");

      final doc = await _db.collection("Usuarios").doc(user.uid).get();
      final data = doc.data() ?? {};
      final rol = data["rol"] ?? "cliente";

      if (!mounted) return;

      // 🔥 Ir a la pantalla correcta según el rol REAL
      Widget destino;

      if (rol == "admin") {
        destino = const CategoriasScreen(rol: "admin");
      } else if (rol == "cliente") {
        destino = const CategoriasScreen(rol: "cliente");
      } else {
        destino = const CategoriasScreen(rol: "visitante");
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => destino),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _alert(_errorMessage(e));
    } finally {
      setState(() => cargando = false);
    }
  }

  // ============================================================
  // 🔥 ALERTA REUTILIZABLE
  // ============================================================
  void _alert(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ============================================================
  // 🔥 UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Color(0xFF1C1C1C)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    SlideTransition(
                      position: _slideLogo,
                      child: const Icon(
                        Icons.fastfood,
                        size: 70,
                        color: Color(0xFFFFC107),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      isLogin ? "Bienvenido 🍔" : "Crea tu cuenta 🍔",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 25),

                    SlideTransition(
                      position: _slideInputs,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 30),
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white24),
                        ),

                        child: Column(
                          children: [
                            // 🔥 Campo nombre (solo registro)
                            if (!isLogin)
                              TextField(
                                controller: _nombreController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: "Nombre completo",
                                  labelStyle: TextStyle(color: Colors.white70),
                                  prefixIcon: Icon(
                                    Icons.person,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),

                            if (!isLogin) const SizedBox(height: 15),

                            // 🔥 Email
                            TextField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: "Correo (@gmail.com)",
                                labelStyle: TextStyle(color: Colors.white70),
                                prefixIcon: Icon(
                                  Icons.email,
                                  color: Colors.white70,
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),

                            // 🔥 Contraseña
                            TextField(
                              controller: _passwordController,
                              obscureText: !mostrarPassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: "Contraseña",
                                labelStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock,
                                  color: Colors.white70,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    mostrarPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () => setState(
                                    () => mostrarPassword = !mostrarPassword,
                                  ),
                                ),
                              ),
                            ),

                            // 🔥 Confirmación de contraseña (solo registro)
                            if (!isLogin) ...[
                              const SizedBox(height: 15),
                              TextField(
                                controller: _confirmPasswordController,
                                obscureText: !mostrarPasswordConfirm,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Confirmar contraseña",
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock,
                                    color: Colors.white70,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      mostrarPasswordConfirm
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () => setState(
                                      () => mostrarPasswordConfirm =
                                          !mostrarPasswordConfirm,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // 🔥 BOTÓN LOGIN / REGISTRO
                    SlideTransition(
                      position: _slideButton,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 60,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: cargando
                            ? null
                            : isLogin
                            ? _login
                            : _register,
                        child: cargando
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                isLogin ? "Iniciar sesión" : "Registrar",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextButton(
                      onPressed: () => setState(() => isLogin = !isLogin),
                      child: Text(
                        isLogin
                            ? "¿No tienes cuenta? Regístrate"
                            : "¿Ya tienes cuenta? Inicia sesión",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
