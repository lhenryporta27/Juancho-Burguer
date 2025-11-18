import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FastFood App',

      // 🔥 TEMA GLOBAL DE LA APP
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primarySwatch: Colors.red,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFC107), // amarillo Juancho
        ),
        fontFamily: "Roboto",
      ),

      // 🔥 SIEMPRE INICIO EN EL HOME
      home: const HomeScreen(),
    );
  }
}
