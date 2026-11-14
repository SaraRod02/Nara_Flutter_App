import 'package:flutter/material.dart';

import '../models/nara_user.dart';
import '../models/nara_user_session.dart';
import 'home_screen.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _cargando = false;

  NaraUserType _tipoSeleccionado = NaraUserType.usuarioPrincipal;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _registrarse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      final usuario = await AuthService.registrarUsuario(
        nombre: _nombreController.text,
        correo: _correoController.text,
        password: _contrasenaController.text,
        tipo: _tipoSeleccionado,
      );

      if (!mounted) return;

      await NaraUserSession.setUser(usuario);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        foregroundColor: const Color(0xFF7155A5),
        backgroundColor: const Color(0xFFF8F4FF),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Comencemos 💜',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7155A5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Crea tu espacio personal en NARA.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  TextFormField(
                    controller: _nombreController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Escribe tu nombre.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  TextFormField(
                    controller: _correoController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                              .hasMatch(value.trim())) {
                        return 'Ingresa un correo válido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  TextFormField(
                    controller: _contrasenaController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                      helperText: 'Usa al menos 6 caracteres.',
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Necesitas al menos 6 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    '¿Cómo utilizarás NARA?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  RadioGroup<NaraUserType>(
                    groupValue: _tipoSeleccionado,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _tipoSeleccionado = value;
                        });
                      }
                    },
                    child: Column(
                      children: [
                        RadioListTile<NaraUserType>(
                          value: NaraUserType.usuarioPrincipal,
                          title: const Text('Usuario principal'),
                          subtitle: const Text(
                            'Quiero registrar y dar seguimiento a mis emociones.',
                          ),
                        ),
                        RadioListTile<NaraUserType>(
                          value: NaraUserType.contactoConfianza,
                          title: const Text('Contacto de confianza'),
                          subtitle: const Text(
                            'Quiero acompañar a una persona de confianza.',
                          ),
                        ),
                        RadioListTile<NaraUserType>(
                          value: NaraUserType.profesional,
                          title: const Text('Profesional de apoyo'),
                          subtitle: const Text(
                            'Quiero brindar acompañamiento profesional.',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _cargando ? null : _registrarse,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B83D5),
                        foregroundColor: Colors.white,
                      ),
                      child: _cargando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Crear mi cuenta'),
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Text(
                    'Tu cuenta se guardará de forma segura en este dispositivo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
