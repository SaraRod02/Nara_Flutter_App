
class LumiActivity {
  final String title;
  final String description;
  final String emoji;
  final int points;

  const LumiActivity({
    required this.title,
    required this.description,
    required this.emoji,
    required this.points,
  });
}

const List<LumiActivity> lumiActivities = [
  LumiActivity(
    title: 'Respiración consciente',
    description: 'Realiza un ejercicios de respiracion cada 2 minutos durante 20 minutos.',
    emoji: '🧘',
    points: 10,
  ),

  LumiActivity(
    title: 'Escribe tus emociones',
    description: 'Utilizar el diario para escribir cómo te sientes el día de hoy.',
    emoji: '📖',
    points: 15,
  ),

  LumiActivity(
    title: 'Tómate un descanso',
    description: 'Realiza una pequeña caminata y despeja tu mente.',
    emoji: '🚶',
    points: 20,
  ),

  LumiActivity(
    title: 'Identifica algo positivo',
    description: 'Escribe tres cosas buenas que te hayan ocurrido hoy.',
    emoji: '🌻',
    points: 15,
  ),

  LumiActivity(
    title: 'Escucha música relajante',
    description: 'Dedica unos minutos a escuchar tu música favorita.',
    emoji: '🎵',
    points: 10,
  ),

  LumiActivity(
    title: 'Expresa tus emociones',
    description: 'Dibuja o escribe cómo te sientes actualmente.',
    emoji: '🎨',
    points: 20,
  ),

  LumiActivity(
    title: 'Practica la gratitud',
    description: 'Piensa en algo por lo que te sientas agradecido hoy.',
    emoji: '💚',
    points: 10,
  ),

  LumiActivity(
    title: 'Relaja tu cuerpo',
    description: 'Realiza algunos estiramientos suaves.',
    emoji: '🌿',
    points: 15,
  ),

  LumiActivity(
    title: 'Dedica tiempo a ti',
    description: 'Piensa en tu hobby favorito y dedica tiempo a realizarlo.',
    emoji: '✨',
    points: 20,
  ),
];
