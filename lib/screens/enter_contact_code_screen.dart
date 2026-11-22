
import 'package:material_ui/material_ui.dart';

import '../models/trusted_contact_store.dart';
import '../theme_controller.dart';

class EnterContactCodeScreen extends StatefulWidget {
  final NaraPalette palette;

  const EnterContactCodeScreen({super.key, required this.palette});

  @override
  State<EnterContactCodeScreen> createState() =>
      _EnterContactCodeScreenState();
}

class _EnterContactCodeScreenState extends State<EnterContactCodeScreen> {
  final TextEditingController codeController = TextEditingController();

  bool isSending = false;

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  Future<void> sendRequest() async {
    final code = codeController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      showMessage('Introduce un código válido de 6 dígitos.');
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      final result = await TrustedContactStore.requestByCode(
        code: code,
        nombre: '',
        correo: '',
      );

      if (!mounted) return;

      switch (result) {
        case InvitationCodeResult.success:
          showMessage('¡Solicitud enviada correctamente! 💜');
          codeController.clear();
          break;

        case InvitationCodeResult.invalidCode:
          showMessage('El código no es válido.');
          break;

        case InvitationCodeResult.alreadyRequested:
          showMessage('Ya enviaste una solicitud.');
          break;

        case InvitationCodeResult.alreadyLinked:
          showMessage('Ya estás vinculado con esta persona.');
          break;
      }
    } catch (error) {
      if (!mounted) return;
      showMessage('No se pudo enviar la solicitud. Inténtalo de nuevo.');
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
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
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Vincularme a NARA'),
        backgroundColor: palette.surface,
        foregroundColor: palette.text,
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

            Text(
              'Únete a una red de apoyo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: palette.accent,
              ),
            ),
            const SizedBox(height: 10),

            Text(
              'Introduce el código que te compartió '
              'la persona a la que deseas acompañar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.text,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 25,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                labelText: 'Código de invitación',
                hintText: '123456',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: isSending ? null : sendRequest,
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isSending
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Enviar solicitud'),
            ),

            const SizedBox(height: 16),

            Text(
              'Tu nombre y correo se obtienen automáticamente '
              'de tu cuenta NARA.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: palette.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
