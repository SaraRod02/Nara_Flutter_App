import 'package:material_ui/material_ui.dart';

import '../models/nara_user_session.dart';
import '../services/professional_link_service.dart';
import '../theme_controller.dart';
import 'professional_patient_records_screen.dart';

class ProfessionalPatientsScreen extends StatefulWidget {
  const ProfessionalPatientsScreen({super.key});

  @override
  State<ProfessionalPatientsScreen> createState() =>
      _ProfessionalPatientsScreenState();
}

class _ProfessionalPatientsScreenState
    extends State<ProfessionalPatientsScreen> {
  List<Map<String, dynamic>> _pacientes = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPacientes();
  }

  Future<void> _cargarPacientes() async {
    try {
      final usuario = NaraUserSession.currentUser.value;

      if (usuario?.idUsuario == null) {
        throw Exception('No se encontró la sesión del profesional.');
      }

      final pacientes = await ProfessionalLinkService.getLinkedPatients(
        usuario!.idUsuario!,
      );

      if (!mounted) return;

      setState(() {
        _pacientes = pacientes;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  Future<void> _desvincularPaciente(Map<String, dynamic> paciente) async {
    final nombre = paciente['nombre']?.toString() ?? 'este paciente';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Desvincular paciente'),
          content: Text(
            '¿Estás seguro de que deseas finalizar la vinculación con '
            '$nombre?\n\n'
            'Esta acción no eliminará su cuenta ni su historial emocional.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Desvincular',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;

    try {
      final usuario = NaraUserSession.currentUser.value;

      if (usuario?.idUsuario == null) {
        throw Exception('No se encontró la sesión del profesional.');
      }

      final resultado = await ProfessionalLinkService.endLink(
        patientId: paciente['id_usuario_paciente'] as int,
        psychologistId: usuario!.idUsuario!,
      );

      if (!mounted) return;

      if (resultado) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Se finalizó la vinculación con $nombre.')),
        );

        await _cargarPacientes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró una vinculación activa.'),
          ),
        );

        await _cargarPacientes();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo desvincular al paciente: $e')),
      );
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
              'Mis pacientes',
              style: TextStyle(
                color: palette.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: palette.surface,
            foregroundColor: palette.text,
          ),
          body: _cargando
              ? Center(child: CircularProgressIndicator(color: palette.accent))
              : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.text),
                    ),
                  ),
                )
              : _pacientes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 65,
                          color: palette.accent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aún no tienes pacientes vinculados',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: palette.accent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Cuando una persona autorice la vinculación '
                          'contigo, aparecerá aquí.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: palette.text, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarPacientes,
                  color: palette.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _pacientes.length,
                    itemBuilder: (context, index) {
                      final paciente = _pacientes[index];
                      final tieneConsentimiento =
                          paciente['tiene_consentimiento'] == 1;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: palette.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: palette.background,
                              child: Icon(
                                Icons.person_outline,
                                color: palette.accent,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    paciente['nombre']?.toString() ??
                                        'Paciente',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: palette.accent,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    paciente['correo']?.toString() ??
                                        'Sin correo',
                                    style: TextStyle(color: palette.text),
                                  ),
                                  const SizedBox(height: 12),

                                  // Estado del consentimiento.
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tieneConsentimiento
                                          ? Colors.green.withValues(alpha: 0.12)
                                          : palette.iconBackground,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          tieneConsentimiento
                                              ? Icons.check_circle_outline
                                              : Icons.lock_outline,
                                          size: 16,
                                          color: tieneConsentimiento
                                              ? Colors.green
                                              : palette.mutedText,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          tieneConsentimiento
                                              ? 'Acceso autorizado'
                                              : 'Sin autorización',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: tieneConsentimiento
                                                ? Colors.green
                                                : palette.mutedText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Ver seguimiento si existe autorización.
                                  if (tieneConsentimiento) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProfessionalPatientRecordsScreen(
                                                    patientId:
                                                        paciente['id_usuario_paciente']
                                                            as int,
                                                    patientName:
                                                        paciente['nombre']
                                                            ?.toString() ??
                                                        'Paciente',
                                                  ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.insights_outlined,
                                        ),
                                        label: const Text('Ver seguimiento'),
                                      ),
                                    ),
                                  ],

                                  // Finalizar la vinculación.
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        _desvincularPaciente(paciente);
                                      },
                                      icon: const Icon(Icons.link_off_outlined),
                                      label: const Text('Desvincular paciente'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(
                                          color: Colors.red,
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
                    },
                  ),
                ),
        );
      },
    );
  }
}
