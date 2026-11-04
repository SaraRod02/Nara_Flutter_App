
import 'package:flutter/material.dart';
import '../theme_controller.dart';
import 'emotion_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NaraPalette>(
      valueListenable: NaraThemeController.current,
      builder: (context, palette, child) {
        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            backgroundColor: palette.surface,
            foregroundColor: palette.text,
            title: Text(
              'NARA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                color: palette.accent,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const _LogoutScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'Hola, qué gusto tenerte aquí',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: palette.accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Este es tu espacio. Ve a tu ritmo y date permiso de sentir.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Tarjeta de LUMI
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: palette.secondary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '☁️',
                          style: TextStyle(fontSize: 62),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '¡Hola! Soy LUMI',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: palette.accent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Estoy aquí para acompañarte mientras aprendes '
                          'a escuchar tus emociones.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.text,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _HomeOption(
                    palette: palette,
                    icon: Icons.favorite_outline,
                    title: '¿Cómo me siento?',
                    description: 'Registra tu estado emocional.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmotionScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  _HomeOption(
                    palette: palette,
                    icon: Icons.calendar_month_outlined,
                    title: 'Mi historial',
                    description: 'Consulta tus registros emocionales.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmotionHistoryScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  _HomeOption(
                    palette: palette,
                    icon: Icons.palette_outlined,
                    title: 'Personalizar NARA',
                    description: 'Puedes elegir tus colores.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeOption extends StatelessWidget {
  final NaraPalette palette;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _HomeOption({
    required this.palette,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: palette.surface,
      elevation: 1,
      shadowColor: palette.border,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: palette.iconBackground,
          child: Icon(icon, color: palette.accent),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: palette.text,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(color: palette.mutedText),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: palette.accent,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _LogoutScreen extends StatelessWidget {
  const _LogoutScreen();

  @override
  Widget build(BuildContext context) {
    return const _LogoutRedirect();
  }
}

class _LogoutRedirect extends StatelessWidget {
  const _LogoutRedirect();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (route) => false,
            );
          },
          child: const Text('Volver al inicio'),
        ),
      ),
    );
  }
}
