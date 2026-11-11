
import 'package:flutter/material.dart';
import '../models/trusted_contact_store.dart';
import '../theme_controller.dart';

class EnterContactCodeScreen extends StatefulWidget {
  final NaraPalette palette;

  const EnterContactCodeScreen({
    super.key,
    required this.palette,
  });

  @override
  State<EnterContactCodeScreen> createState() =>
      _EnterContactCodeScreenState();
}

class _EnterContactCodeScreenState
    extends State<EnterContactCodeScreen> {
  final TextEditingController codeController =
      TextEditingController();

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  @override
  void dispose() {
    codeController.dispose();
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void sendRequest() {
    final code = codeController.text.trim();
    final name = nameController.text.trim();
    final email = emailController.text.trim();

    if (code.length != 6 ||
        name.isEmpty ||
        email.isEmpty ||
        !email.contains('@')) {
      showMessage('Revisa tus datos e introduce un código de 6 dígitos.');
      return;
    }

    final result = TrustedContactStore.requestByCode(
      code: code,
      nombre: name,
      correo: email,
    );

    switch (result) {
      case InvitationCodeResult.success:
        showMessage('¡Solicitud enviada correctamente!');
        codeController.clear();
        nameController.clear();
        emailController.clear();
        break;

      case InvitationCodeResult.invalidCode:
        showMessage('El código no es válido.');
        break;

      case InvitationCodeResult.alreadyRequested:
        showMessage('Ya enviaste una solicitud con este correo.');
        break;

      case InvitationCodeResult.alreadyLinked:
        showMessage('Este contacto ya está vinculado.');
        break;
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vincularme a NARA'),
        backgroundColor: palette.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.people_alt_outlined,
              size: 70,
              color: palette.accent,
            ),
            const SizedBox(height: 20),
            const Text(
              'Únete a una red de apoyo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Introduce el código que te compartió '
              'la persona a la que deseas acompañar.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Código de invitación',
                hintText: 'Ej. 123456',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tu nombre',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Tu correo electrónico',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: sendRequest,
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Enviar solicitud'),
            ),
          ],
        ),
      ),
    );
  }
}
