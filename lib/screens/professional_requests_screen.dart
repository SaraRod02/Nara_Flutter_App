import 'package:material_ui/material_ui.dart';

import '../models/nara_user_session.dart';
import '../services/professional_link_service.dart';
import '../theme_controller.dart';

class ProfessionalRequestsScreen extends StatefulWidget {
  const ProfessionalRequestsScreen({super.key});

  @override
  State<ProfessionalRequestsScreen> createState() =>
      _ProfessionalRequestsScreenState();
}

class _ProfessionalRequestsScreenState
    extends State<ProfessionalRequestsScreen> {
  List<Map<String, dynamic>> _solicitudes = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    try {
      final usuario = NaraUserSession.currentUser.value;

      if (usuario?.idUsuario == null) {
        throw Exception('No se encontró la sesión del profesional.');
      }

      final solicitudes =
          await ProfessionalLinkService.getPendingRequestsForProfessional(
            usuario!.idUsuario!,
          );

      if (!mounted) return;

      setState(() {
        _solicitudes = solicitudes;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return 'Fecha no disponible';

    final date = DateTime.tryParse(fecha.toString());

    if (date == null) return 'Fecha no disponible';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
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
              'Solicitudes',
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
              : _solicitudes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mark_email_read_outlined,
                          size: 65,
                          color: palette.accent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tienes solicitudes pendientes',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: palette.accent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Cuando envíes una solicitud de '
                          'vinculación, aparecerá aquí hasta '
                          'que el paciente responda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: palette.text, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarSolicitudes,
                  color: palette.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _solicitudes.length,
                    itemBuilder: (context, index) {
                      final solicitud = _solicitudes[index];

                      final tipo =
                          solicitud['tipo_profesional']?.toString() ??
                          'psicologo';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: palette.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              solicitud['nombre']?.toString() ?? 'Paciente',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: palette.accent,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              solicitud['correo']?.toString() ?? 'Sin correo',
                              style: TextStyle(color: palette.text),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tipo: ${tipo == 'psiquiatra' ? 'Psiquiatra' : 'Psicólogo/a'}',
                              style: TextStyle(color: palette.text),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Enviada: ${_formatearFecha(solicitud['fecha_solicitud'])}',
                              style: TextStyle(color: palette.text),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 18,
                                  color: palette.accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Pendiente de autorización',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: palette.accent,
                                  ),
                                ),
                              ],
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
