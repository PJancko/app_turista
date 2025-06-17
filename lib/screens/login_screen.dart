import 'package:app_turista/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _error = '';

  Future<void> _login() async {
    try {
      // Paso 1: Autenticación con Firebase Auth
      UserCredential userCred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Paso 2: Obtener UID del usuario autenticado
      final uid = userCred.user!.uid;

      // Paso 3: Buscar datos del usuario en Firestore
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .get();

      if (!doc.exists) {
        setState(() {
          _error = 'Usuario no registrado en la base de datos.';
        });
        return;
      }

      final data = doc.data()!;
      final nombre = data['nombre'];
      final rol = data['rol'];

      // Paso 4: Mostrar mensaje de éxito
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Bienvenido $nombre ($rol)')));
      // TODO: Redirigir a otra pantalla según rol o guardar sesión
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Ocurrió un error inesperado.';
      });
    } catch (e) {
      setState(() {
        _error = 'Error de conexión o datos.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Iniciar sesión',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                // Campo de correo
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Correo electrónico',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 20),

                // Campo de contraseña
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 10),

                // Mostrar error
                if (_error.isNotEmpty)
                  Text(_error, style: const TextStyle(color: Colors.red)),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Navegar a pantalla de recuperación
                    },
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),
                const SizedBox(height: 20),

                // Botón de iniciar sesión
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _login,
                    child: const Text(
                      'Continuar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                const Text('¿No tienes una cuenta?'),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text('Crear cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
