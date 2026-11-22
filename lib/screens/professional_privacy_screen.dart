import 'package:material_ui/material_ui.dart';

import '../theme_controller.dart';
import '../services/professional_link_service.dart';
import '../services/professional_consent_service.dart';

class ProfessionalPrivacyScreen extends StatefulWidget {
  final int patientId;
  final NaraPalette palette;

  const ProfessionalPrivacyScreen({
    super.key,
    required this.patientId,
    required this.palette,
  });

  @override
  State<ProfessionalPrivacyScreen> createState() =>
      _ProfessionalPrivacyScreenState();
}

class _ProfessionalPrivacyScreenState extends State<ProfessionalPrivacyScreen> {
  final List<String> _types = ['psicologo', 'psiquiatra'];

  final Map<String, Map<String, dynamic>?> _professionals = {};
  final Map<String, bool> _consents = {};

  late Future<void> _loadFuture;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadProfessionals();
  }

  Future<void> _loadProfessionals() async {
    for (final type in _types) {
      final professional = await ProfessionalLinkService.getLinkedProfessional(
        widget.patientId,
        type,
      );

      _professionals[type] = professional;

      if (professional != null) {
        _consents[type] = await ProfessionalConsentService.hasConsent(
          patientId: widget.patientId,
          psychologistId: professional['id_psicologo'] as int,
        );
      } else {
        _consents[type] = false;
      }
    }
  }

  Future<void> _changeConsent(String type, bool grant) async {
    final professional = _professionals[type];
    if (professional == null || _saving) return;

    setState(() => _saving = true);

    try {
      final professionalId = professional['id_psicologo'] as int;

      if (grant) {
        await ProfessionalConsentService.grantConsent(
          patientId: widget.patientId,
          psychologistId: professionalId,
        );
      } else {
        await ProfessionalConsentService.revokeConsent(
          patientId: widget.patientId,
          psychologistId: professionalId,
        );
      }

      if (!mounted) return;

      setState(() {
        _consents[type] = grant;
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            grant
                ? 'Permiso concedido correctamente.'
                : 'Permiso revocado correctamente.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el permiso: $e')),
      );
    }
  }

  Widget _buildProfessionalCard(String type) {
    final palette = widget.palette;
    final professional = _professionals[type];
    final hasConsent = _consents[type] ?? false;

    final typeName = type == 'psicologo' ? 'Psicólogo' : 'Psiquiatra';

    if (professional == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
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
              typeName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No tienes un $typeName vinculado actualmente.',
              style: TextStyle(color: palette.mutedText),
            ),
          ],
        ),
      );
    }

    final name = professional['nombre']?.toString() ?? 'Sin nombre';
    final specialty =
        professional['especialidad']?.toString() ?? 'Sin especialidad';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              CircleAvatar(
                backgroundColor: palette.iconBackground,
                child: Icon(
                  Icons.medical_services_outlined,
                  color: palette.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: palette.text,
                      ),
                    ),
                    Text(typeName, style: TextStyle(color: palette.mutedText)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(specialty, style: TextStyle(color: palette.mutedText)),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                hasConsent ? Icons.check_circle_outline : Icons.lock_outline,
                color: hasConsent ? Colors.green : palette.mutedText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasConsent
                      ? 'Tiene permiso para consultar tus registros.'
                      : 'No tiene permiso para consultar tus registros.',
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving
                  ? null
                  : () => _changeConsent(type, !hasConsent),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasConsent ? palette.surface : palette.accent,
                foregroundColor: hasConsent ? palette.text : Colors.white,
                side: BorderSide(color: palette.accent),
              ),
              child: Text(hasConsent ? 'Revocar acceso' : 'Conceder acceso'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Privacidad y permisos'),
        backgroundColor: palette.background,
        foregroundColor: palette.text,
      ),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: palette.accent),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudo cargar la información de tus especialistas.',
                  style: TextStyle(color: palette.text),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tú decides quién puede consultar tu información.',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Puedes conceder o revocar el acceso a tus registros '
                  'emocionales y de síntomas de manera independiente '
                  'para cada especialista.',
                  style: TextStyle(color: palette.text, height: 1.5),
                ),
                const SizedBox(height: 24),
                for (final type in _types) _buildProfessionalCard(type),
                const SizedBox(height: 12),
                Text(
                  'La vinculación con un especialista no le concede '
                  'automáticamente acceso a tus registros.',
                  style: TextStyle(
                    color: palette.mutedText,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
