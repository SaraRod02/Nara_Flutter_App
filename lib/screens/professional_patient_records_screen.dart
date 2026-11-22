import 'package:material_ui/material_ui.dart';

import '../models/nara_user.dart';
import '../models/nara_user_session.dart';
import '../services/professional_record_service.dart';
import '../theme_controller.dart';

class ProfessionalPatientRecordsScreen extends StatefulWidget {
  final int patientId;
  final String patientName;

  const ProfessionalPatientRecordsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<ProfessionalPatientRecordsScreen> createState() =>
      _ProfessionalPatientRecordsScreenState();
}

class _ProfessionalPatientRecordsScreenState
    extends State<ProfessionalPatientRecordsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _emotionalRecords = [];
  List<Map<String, dynamic>> _symptomRecords = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final user = NaraUserSession.currentUser.value;

      if (user == null ||
          user.tipo != NaraUserType.profesional ||
          user.idUsuario == null) {
        throw StateError('La sesión profesional no es válida.');
      }

      final emotional = await ProfessionalRecordService.getEmotionalRecords(
        patientId: widget.patientId,
        psychologistId: user.idUsuario!,
      );

      final symptoms = await ProfessionalRecordService.getSymptomRecords(
        patientId: widget.patientId,
        psychologistId: user.idUsuario!,
      );

      if (!mounted) return;

      setState(() {
        _emotionalRecords = emotional;
        _symptomRecords = symptoms;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().contains('autorización')
            ? 'Este paciente no ha autorizado el acceso o ha revocado el permiso.'
            : e.toString();
        _loading = false;
      });
    }
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');

    if (date == null) return 'Fecha no disponible';

    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NaraPalette>(
      valueListenable: NaraThemeController.current,
      builder: (context, palette, child) {
        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            title: const Text('Seguimiento autorizado'),
            backgroundColor: palette.surface,
            foregroundColor: palette.text,
          ),
          body: _loading
              ? Center(child: CircularProgressIndicator(color: palette.accent))
              : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 55,
                          color: palette.mutedText,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: palette.text),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _loadRecords,
                          child: const Text('Volver a comprobar'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRecords,
                  color: palette.accent,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        widget.patientName,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: palette.accent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Información compartida con tu cuenta profesional.',
                        style: TextStyle(color: palette.mutedText),
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Registros emocionales', palette),
                      if (_emotionalRecords.isEmpty)
                        _emptyMessage('No hay registros emocionales.', palette)
                      else
                        ..._emotionalRecords.map(
                          (record) => _recordCard(
                            palette,
                            title: record['emocion']?.toString() ?? 'Emoción',
                            subtitle:
                                'Intensidad: ${record['nivel_intensidad'] ?? 0}/10',
                            comment: record['comentario']?.toString() ?? '',
                            date: _formatDate(record['fecha_registro']),
                          ),
                        ),
                      const SizedBox(height: 24),
                      _sectionTitle('Registros de síntomas', palette),
                      if (_symptomRecords.isEmpty)
                        _emptyMessage('No hay registros de síntomas.', palette)
                      else
                        ..._symptomRecords.map(
                          (record) => _recordCard(
                            palette,
                            title:
                                record['nombre_sintoma']?.toString() ??
                                'Síntoma',
                            subtitle:
                                'Intensidad: ${record['nivel_intensidad'] ?? 0}/5',
                            comment: record['comentario']?.toString() ?? '',
                            date: _formatDate(record['fecha_registro']),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text(
                        'Estos registros son información de seguimiento y '
                        'no constituyen por sí mismos un diagnóstico.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: palette.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _sectionTitle(String title, NaraPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: palette.accent,
        ),
      ),
    );
  }

  Widget _emptyMessage(String message, NaraPalette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(message, style: TextStyle(color: palette.mutedText)),
    );
  }

  Widget _recordCard(
    NaraPalette palette, {
    required String title,
    required String subtitle,
    required String comment,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: palette.text),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: palette.accent)),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(comment, style: TextStyle(color: palette.text)),
          ],
          const SizedBox(height: 8),
          Text(date, style: TextStyle(fontSize: 12, color: palette.mutedText)),
        ],
      ),
    );
  }
}
