import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _opacity = 0.0;
  double _slideTitle = -50;
  double _slideButton = 50;
  int _sloganIndex = 0;

  final List<String> slogans = [
    "Te servimos con pasión",
    "El sabor que disfrutas",
    "La mejor burger de la ciudad",
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () {
      setState(() {
        _opacity = 1.0;
        _slideTitle = 0;
        _slideButton = 0;
      });
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return false;
      setState(() {
        _sloganIndex = (_sloganIndex + 1) % slogans.length;
      });
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("lib/assets/burgerjuancho.jpg", fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.4)),

          AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(seconds: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 🔹 Título y slogan
                AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeOut,
                  transform: Matrix4.translationValues(0, _slideTitle, 0),
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      const Text(
                        "Burger Juancho",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 6,
                              color: Colors.black87,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      // ⬇️ Aquí bajamos más el slogan
                      const SizedBox(height: 25),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        child: Text(
                          slogans[_sloganIndex],
                          key: ValueKey<int>(_sloganIndex),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 🔹 Botón
                AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeOut,
                  transform: Matrix4.translationValues(0, _slideButton, 0),
                  padding: const EdgeInsets.only(bottom: 70),
                  child: SizedBox(
                    width: 230,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        elevation: 8,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LoginScreen()),
                        );
                      },
                      icon: const Icon(Icons.fastfood, color: Colors.white),
                      label: const Text(
                        "Iniciar Sesión",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
