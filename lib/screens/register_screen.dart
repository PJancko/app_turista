import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _error = '';

  Future<void> _register() async {
    try {
      // Crear usuario en Firebase Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = cred.user!.uid;

      // Crear documento en la colección usuarios
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'nombre': _nameController.text.trim(),
        'correo': _emailController.text.trim(),
        'rol': 'usuario',
        'favoritosEventos': [],
        'favoritosLugares': [],
      });

      // Mostrar éxito
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registro exitoso')));

      Navigator.pop(context); // Volver al login o home
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Error desconocido';
      });
    } catch (e) {
      setState(() {
        _error = 'Error al registrar usuario.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Crear cuenta")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
        child: Column(
          children: [
            const Text(
              'Registro de usuario',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Nombre
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),

            // Correo
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 20),

            // Contraseña
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 10),

            // Mostrar error
            if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 20),

            // Botón de registro
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _register,
                child: const Text("Registrarse"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
