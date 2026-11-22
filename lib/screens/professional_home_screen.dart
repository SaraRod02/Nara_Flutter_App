import 'package:material_ui/material_ui.dart';

import '../models/nara_user_session.dart';
import '../theme_controller.dart';
import 'professional_profile_screen.dart';
import 'professional_patients_screen.dart';
import 'professional_requests_screen.dart';
import 'professional_link_patient_screen.dart';

class ProfessionalHomeScreen extends StatelessWidget {
  const ProfessionalHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NaraPalette>(
      valueListenable: NaraThemeController.current,
      builder: (context, palette, child) {
        final usuario = NaraUserSession.currentUser.value;

        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            title: Text(
              'Espacio profesional',
              style: TextStyle(
                color: palette.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: palette.surface,
            foregroundColor: palette.text,
            actions: [
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await NaraUserSession.clear();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Icon(
                  Icons.medical_services_outlined,
                  size: 70,
                  color: palette.accent,
                ),
                const SizedBox(height: 18),
                Text(
                  '¡Bienvenido${usuario == null ? '' : ', ${usuario.nombre}'}!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Este es tu espacio de apoyo profesional en NARA. '
                  'Aquí podrás acompañar a las personas que autoricen '
                  'su vinculación contigo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 30),
                _ProfessionalCard(
                  palette: palette,
                  icon: Icons.people_alt_outlined,
                  title: 'Mis pacientes',
                  description:
                      'Aquí aparecen las personas que están '
                      'vinculadas contigo.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ProfessionalPatientsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),

                _ProfessionalCard(
                  palette: palette,
                  icon: Icons.person_add_alt_1_outlined,
                  title: 'Vincular paciente',
                  description:
                      'Ingresa el código de seis dígitos que '
                      'te proporcione el paciente.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ProfessionalLinkPatientScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),

                _ProfessionalCard(
                  palette: palette,
                  icon: Icons.mark_email_unread_outlined,
                  title: 'Solicitudes',
                  description:
                      'Consulta las solicitudes de vinculación '
                      'pendientes de autorización.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ProfessionalRequestsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _ProfessionalCard(
                  palette: palette,
                  icon: Icons.insights_outlined,
                  title: 'Seguimiento autorizado',
                  description:
                      'Consulta los indicadores y registros que '
                      'cada paciente haya permitido compartir.',
                ),
                const SizedBox(height: 14),
                _ProfessionalCard(
                  palette: palette,
                  icon: Icons.person_outline,
                  title: 'Mi perfil profesional',
                  description:
                      'Aquí podrás consultar y actualizar tu '
                      'información profesional.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfessionalProfileScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  final NaraPalette palette;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const _ProfessionalCard({
    required this.palette,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: palette.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: palette.accent,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    description,
                    style: TextStyle(height: 1.4, color: palette.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
