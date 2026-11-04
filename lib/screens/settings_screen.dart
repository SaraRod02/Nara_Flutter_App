
import 'package:flutter/material.dart';
import '../theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NaraPalette>(
      valueListenable: NaraThemeController.current,
      builder: (context, palette, child) {
        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            title: const Text('Personalizar NARA'),
            backgroundColor: palette.background,
            foregroundColor: palette.accent,
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Haz tuyo este espacio 💜',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Elige los colores que te hagan sentir cómoda/o.',
              ),
              const SizedBox(height: 28),
              const Text(
                'Temas disponibles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...NaraThemeController.palettes.map((option) {
                final selected = palette.name == option.name;

                return Card(
                  color: option.surface,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: option.accent,
                    ),
                    title: Text(option.name),
                    subtitle: Text(
                      selected ? 'Tema seleccionado' : 'Vista previa',
                    ),
                    trailing: selected
                        ? Icon(
                            Icons.check_circle,
                            color: option.accent,
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: () {
                      NaraThemeController.select(option);
                    },
                  ),
                );
              }),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.favorite,
                      color: palette.accent,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Así se siente tu espacio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Un pequeño recordatorio de que mereces cuidarte.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.accent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Listo'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
