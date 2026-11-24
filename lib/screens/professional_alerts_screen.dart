
import 'package:material_ui/material_ui.dart';

import '../database/nara_database.dart';
import '../models/nara_user_session.dart';
import '../services/professional_link_service.dart';
import '../theme_controller.dart';

class ProfessionalAlertsScreen extends StatefulWidget {
  const ProfessionalAlertsScreen({super.key});

  @override
  State<ProfessionalAlertsScreen> createState() =>
      _ProfessionalAlertsScreenState();
}

class _ProfessionalAlertsScreenState
    extends State<ProfessionalAlertsScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final user = NaraUserSession.currentUser.value;

      if (user?.idUsuario == null) {
        throw Exception('No se encontró la sesión del profesional.');
      }

      final psychologistId = user!.idUsuario!;

      // Obtener pacientes vinculados y sus permisos actuales.
      final patients = await ProfessionalLinkService.getLinkedPatients(
        psychologistId,
      );

      final authorizedPatients = <int, String>{};

      for (final patient in patients) {
        final hasConsent =
            patient['tiene_consentimiento'] == 1 ||
            patient['tiene_consentimiento'] == true;

        if (hasConsent) {
          authorizedPatients[
              patient['id_usuario_paciente'] as int
          ] = patient['nombre']?.toString() ?? 'Paciente';
        }
      }

      final db = await NaraDatabase.database;

      final results = await db.query(
        'alerta_emocional',
        where: 'id_psicologo = ?',
        whereArgs: [psychologistId],
        orderBy: 'fecha_creacion DESC',
      );

      // Mostrar únicamente alertas de pacientes que
      // continúan vinculados y mantienen su consentimiento.
      final visibleAlerts = results.where((alert) {
        final patientId = alert['id_usuario_paciente'] as int;
        return authorizedPatients.containsKey(patientId);
      }).map((alert) {
        final patientId = alert['id_usuario_paciente'] as int;

        return {
          ...alert,
          'nombre_paciente': authorizedPatients[patientId],
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _alerts = visibleAlerts;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }


Future<void> _updateAlertStatus(
  Map<String, dynamic> alert,
  String newStatus,
) async {
  try {
    final user = NaraUserSession.currentUser.value;

    if (user?.idUsuario == null) {
      throw Exception('No se encontró la sesión profesional.');
    }

    final db = await NaraDatabase.database;

    await db.update(
      'alerta_emocional',
      {'estado': newStatus},
      where: 'id_alerta = ? AND id_psicologo = ?',
      whereArgs: [
        alert['id_alerta'],
        user!.idUsuario!,
      ],
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus == 'revisada'
              ? 'Alerta marcada como revisada.'
              : 'Alerta marcada como atendida.',
        ),
      ),
    );

    await _loadAlerts();
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No se pudo actualizar la alerta: $e'),
      ),
    );
  }
}


  String _formatDate(dynamic value) {
    if (value == null) return 'Fecha no disponible';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return 'Fecha no disponible';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'atendida':
        return Colors.green;
      case 'revisada':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'atendida':
        return 'Atendida';
      case 'revisada':
        return 'Revisada';
      default:
        return 'Pendiente';
    }
  }

  Widget _buildAlertCard(
    Map<String, dynamic> alert,
    NaraPalette palette,
  ) {
    final status = alert['estado']?.toString() ?? 'pendiente';
    final color = _statusColor(status);

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
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: color,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Alerta emocional',
                  style: TextStyle(
                    color: palette.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusText(status),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            alert['nombre_paciente']?.toString() ?? 'Paciente',
            style: TextStyle(
              color: palette.text,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            alert['descripcion']?.toString() ?? 'Sin descripción.',
            style: TextStyle(
              color: palette.text,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: palette.mutedText,
              ),
              const SizedBox(width: 7),
              Text(
                'Fecha: ${_formatDate(alert['fecha_creacion'])}',
                style: TextStyle(
                  color: palette.mutedText,
                  fontSize: 13,
                ),
              ),
            ],
          ),

        const SizedBox(height: 16),

        if (status == 'pendiente') ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _updateAlertStatus(alert, 'revisada');
              },
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Marcar como revisada'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _updateAlertStatus(alert, 'atendida');
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Marcar como atendida'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ] else if (status == 'revisada') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _updateAlertStatus(alert, 'atendida');
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Marcar como atendida'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],

        ],
      ),
    );
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
              'Alertas emocionales',
              style: TextStyle(
                color: palette.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: palette.surface,
            foregroundColor: palette.text,
          ),
          body: _loading
              ? Center(
                  child: CircularProgressIndicator(
                    color: palette.accent,
                  ),
                )
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No se pudieron cargar las alertas.\n\n$_error',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: palette.text),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAlerts,
                      color: palette.accent,
                      child: _alerts.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 100),
                                Icon(
                                  Icons.notifications_none,
                                  size: 70,
                                  color: palette.mutedText,
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'No hay alertas emocionales',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: palette.accent,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                  ),
                                  child: Text(
                                    'Cuando se genere una alerta de un '
                                    'paciente que haya autorizado el acceso, '
                                    'aparecerá aquí.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: palette.text,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView(
                              padding: const EdgeInsets.all(20),
                              children: [
                                Text(
                                  'Alertas de tus pacientes',
                                  style: TextStyle(
                                    color: palette.accent,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Se muestran las alertas de pacientes '
                                  'con vinculación y permiso vigentes.',
                                  style: TextStyle(
                                    color: palette.mutedText,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                ..._alerts.map(
                                  (alert) => _buildAlertCard(
                                    alert,
                                    palette,
                                  ),
                                ),
                              ],
                            ),
                    ),
        );
      },
    );
  }
}
