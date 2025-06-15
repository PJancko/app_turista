import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // ahora lo importas
// import 'screens/login_screen.dart'; ← si quieres ir directo al login primero

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventosCiudad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomeLayout(), // ahora todo arranca desde aquí
    );
  }
}
