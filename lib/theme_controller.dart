
import 'package:flutter/material.dart';

class NaraPalette {
  final String name;
  final Color accent;
  final Color background;
  final Color surface;
  final Color secondary;
  final Color text;
  final Color mutedText;
  final Color iconBackground;
  final Color border;

  const NaraPalette({
    required this.name,
    required this.accent,
    required this.background,
    required this.surface,
    required this.secondary,
    required this.text,
    required this.mutedText,
    required this.iconBackground,
    required this.border,
  });
}

class NaraThemeController {
  static const List<NaraPalette> palettes = [
    NaraPalette(
      name: 'Lila',
      accent: Color(0xFF9271C8),
      background: Color(0xFFFAF7FF),
      surface: Color(0xFFFFFFFF),
      secondary: Color(0xFFECE3FA),
      text: Color(0xFF30263D),
      mutedText: Color(0xFF776D83),
      iconBackground: Color(0xFFECE3FA),
      border: Color(0xFFDED2F0),
    ),
    NaraPalette(
      name: 'Rosa',
      accent: Color(0xFFC65F8B),
      background: Color(0xFFFFF7FA),
      surface: Color(0xFFFFFFFF),
      secondary: Color(0xFFF9E1EB),
      text: Color(0xFF432632),
      mutedText: Color(0xFF896A78),
      iconBackground: Color(0xFFF9E1EB),
      border: Color(0xFFF0CCDC),
    ),
    NaraPalette(
      name: 'Menta',
      accent: Color(0xFF39866F),
      background: Color(0xFFF5FBF8),
      surface: Color(0xFFFFFFFF),
      secondary: Color(0xFFDDF2E8),
      text: Color(0xFF203B32),
      mutedText: Color(0xFF658176),
      iconBackground: Color(0xFFDDF2E8),
      border: Color(0xFFC5E6D8),
    ),
    NaraPalette(
      name: 'Azul',
      accent: Color(0xFF4778B8),
      background: Color(0xFFF5F8FF),
      surface: Color(0xFFFFFFFF),
      secondary: Color(0xFFE0EAFA),
      text: Color(0xFF25334A),
      mutedText: Color(0xFF6A7B95),
      iconBackground: Color(0xFFE0EAFA),
      border: Color(0xFFCDDCF3),
    ),
  ];

  static final ValueNotifier<NaraPalette> current =
      ValueNotifier<NaraPalette>(palettes[0]);

  static void select(NaraPalette palette) {
    current.value = palette;
  }
}
