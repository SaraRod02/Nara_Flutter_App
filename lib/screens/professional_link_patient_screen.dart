import 'package:material_ui/material_ui.dart';

import '../models/nara_user_session.dart';
import '../services/professional_link_service.dart';
import '../theme_controller.dart';

class ProfessionalLinkPatientScreen extends StatefulWidget {
  const ProfessionalLinkPatientScreen({super.key});

  @override
  State<ProfessionalLinkPatientScreen> createState() =>
      _ProfessionalLinkPatientScreenState();
}

class _ProfessionalLinkPatientScreenState
    extends State<ProfessionalLinkPatientScreen> {
  final TextEditingController _codeController = TextEditingController();

  bool _enviando = false;
  String? _mensaje;
  bool _esExito = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _enviarSolicitud(NaraPalette palette) async {
    final code = _codeController.text.trim();
    final usuario = NaraUserSession.currentUser.value;

    if (code.length != 6 || int.tryParse(code) == null) {
      setState(() {
        _mensaje = 'Ingresa un código válido de 6 dígitos.';
        _esExito = false;
      });
      return;
    }

    if (usuario?.idUsuario == null) {
      setState(() {
        _mensaje = 'No se encontró la sesión profesional.';
        _esExito = false;
      });
      return;
    }

    setState(() {
      _enviando = true;
      _mensaje = null;
    });

    try {
      final resultado = await ProfessionalLinkService.requestByCode(
        code: code,
        psychologistId: usuario!.idUsuario!,
      );

      if (!mounted) return;

      String mensaje;
      bool exito = false;

      switch (resultado) {
        case ProfessionalLinkResult.success:
          mensaje =
              '¡Solicitud enviada! El paciente deberá autorizar '
              'la vinculación desde su cuenta.';
          exito = true;
          _codeController.clear();
          break;
        case ProfessionalLinkResult.invalidCode:
          mensaje = 'El código no existe. Verifica los 6 dígitos.';
          break;
        case ProfessionalLinkResult.expiredCode:
          mensaje = 'El código ha vencido. Solicita uno nuevo al paciente.';
          break;
        case ProfessionalLinkResult.alreadyRequested:
          mensaje = 'Ya tienes una solicitud pendiente para este paciente.';
          break;
        case ProfessionalLinkResult.alreadyLinked:
          mensaje = 'Ya estás vinculado con este paciente.';
          break;
        case ProfessionalLinkResult.alreadyHasProfessionalOfType:
          mensaje =
              'El paciente ya tiene un profesional de este tipo vinculado.';
          break;
        case ProfessionalLinkResult.selfRequest:
          mensaje = 'No puedes enviar una solicitud a tu propia cuenta.';
          break;
        case ProfessionalLinkResult.wrongRole:
          mensaje =
              'El código no corresponde a tu tipo de especialidad '
              'o tu cuenta no tiene un perfil profesional válido.';
          break;
      }

      setState(() {
        _mensaje = mensaje;
        _esExito = exito;
        _enviando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _mensaje = 'Ocurrió un error al enviar la solicitud.';
        _esExito = false;
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NaraPalette>(
      valueListenable: NaraThemeController.current,
      builder: (context, palette, child) {
        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            title: Text(
              'Vincular paciente',
              style: TextStyle(
                color: palette.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: palette.surface,
            foregroundColor: palette.text,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 25),
                Icon(
                  Icons.person_add_alt_1_outlined,
                  size: 75,
                  color: palette.accent,
                ),
                const SizedBox(height: 22),
                Text(
                  'Conecta con un paciente',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Solicita al paciente su código de vinculación '
                  'de seis dígitos. Al enviarlo, recibirá una solicitud '
                  'que podrá aceptar o rechazar desde su cuenta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Código de vinculación',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    letterSpacing: 10,
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                  decoration: InputDecoration(
                    hintText: '000000',
                    counterText: '',
                    filled: true,
                    fillColor: palette.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: palette.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: palette.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: palette.accent, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: _enviando ? null : () => _enviarSolicitud(palette),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _enviando
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Enviar solicitud',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                if (_mensaje != null) ...[
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _esExito
                          ? palette.accent.withValues(alpha: 0.12)
                          : palette.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: palette.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _esExito
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                          color: palette.accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _mensaje!,
                            style: TextStyle(height: 1.4, color: palette.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
