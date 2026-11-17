
import 'package:flutter/material.dart';

import '../models/nara_user_session.dart';
import '../theme_controller.dart';

class TrustedContactHomeScreen extends StatelessWidget {
  const TrustedContactHomeScreen({super.key});

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
              'Mi acompañamiento',
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
                  Icons.volunteer_activism_outlined,
                  size: 70,
                  color: palette.accent,
                ),
                const SizedBox(height: 18),
                Text(
                  '¡Hola${usuario == null ? '' : ', ${usuario.nombre}'}!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Gracias por formar parte de una red de apoyo. '
                  'Tu presencia puede hacer la diferencia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 30),
                _InfoCard(
                  palette: palette,
                  icon: Icons.people_outline,
                  title: 'Personas que acompaño',
                  description:
                      'Aquí aparecerán las personas que hayan aceptado '
                      'vincularse contigo.',
                ),
                const SizedBox(height: 14),
                _InfoCard(
                  palette: palette,
                  icon: Icons.notifications_active_outlined,
                  title: 'Avisos y alertas',
                  description:
                      'Aquí recibirás los avisos que cada persona '
                      'haya autorizado compartir contigo.',
                ),
                const SizedBox(height: 14),
                _InfoCard(
                  palette: palette,
                  icon: Icons.favorite_outline,
                  title: '¿Cómo puedo ayudar?',
                  description:
                      'Acompaña con empatía, escucha sin juzgar y '
                      'respeta los tiempos y decisiones de la otra persona.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final NaraPalette palette;
  final IconData icon;
  final String title;
  final String description;

  const _InfoCard({
    required this.palette,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  style: TextStyle(
                    height: 1.4,
                    color: palette.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

