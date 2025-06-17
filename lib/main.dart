import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // ahora lo importas
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// import 'screens/login_screen.dart'; ← si quieres ir directo al login primero

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // <--- usa esto
  );
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
