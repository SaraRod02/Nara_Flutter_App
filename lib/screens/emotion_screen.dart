import 'package:material_ui/material_ui.dart';

import '../database/nara_database.dart';
import '../models/nara_user_session.dart';
import '../theme_controller.dart';
import 'symptom_screen.dart';
import '../services/emotional_alert_service.dart';

class EmotionalRecord {
  final String emotion;
  final int intensity;
  final String note;
  final DateTime date;

  EmotionalRecord({
    required this.emotion,
    required this.intensity,
    required this.note,
    required this.date,
  });
}

// Almacenamiento temporal durante la ejecución de la app.
class EmotionalStore {
  static final ValueNotifier<List<EmotionalRecord>> records =
      ValueNotifier<List<EmotionalRecord>>([]);

  static Future<void> loadRecords(int userId) async {
    final db = await NaraDatabase.database;

    final results = await db.query(
      'registro_emocional',
      where: 'id_usuario = ?',
      whereArgs: [userId],
      orderBy: 'fecha_registro DESC',
    );

    records.value = results.map((row) {
      return EmotionalRecord(
        emotion: row['emocion'] as String,
        intensity: (row['nivel_intensidad'] as num?)?.toInt() ?? 0,
        note: row['comentario'] as String? ?? '',
        date: DateTime.parse(row['fecha_registro'] as String),
      );
    }).toList();
  }
}

class EmotionScreen extends StatefulWidget {
  const EmotionScreen({super.key});

  @override
  State<EmotionScreen> createState() => _EmotionScreenState();
}

class _EmotionScreenState extends State<EmotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  final List<Map<String, dynamic>> _emotions = [
    {'name': 'Feliz', 'emoji': '😊'},
    {'name': 'Tranquilo/a', 'emoji': '😌'},
    {'name': 'Ansioso/a', 'emoji': '😰'},
    {'name': 'Triste', 'emoji': '😔'},
    {'name': 'Enojado/a', 'emoji': '😠'},
    {'name': 'Agotado/a', 'emoji': '🥱'},
    {'name': 'Con miedo', 'emoji': '😟'},
    {'name': 'Confundido/a', 'emoji': '😵‍💫'},
  ];

  String? _selectedEmotion;
  double _intensity = 5;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (_selectedEmotion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero elige cómo te sientes 💗')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final userId = NaraUserSession.currentUser.value?.idUsuario;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar tu cuenta.')),
      );
      return;
    }

    final now = DateTime.now();
    final note = _noteController.text.trim();

    try {
      final db = await NaraDatabase.database;

      await db.insert('registro_emocional', {
        'id_usuario': userId,
        'emocion': _selectedEmotion!,
        'nivel_intensidad': _intensity.round(),
        'comentario': note,
        'fecha_registro': now.toIso8601String(),
      });

      await EmotionalAlertService.checkAndGenerateAlert(
  patientId: userId,
  emotion: _selectedEmotion!,
  intensity: _intensity.round(),
);

      if (!mounted) return;

      EmotionalStore.records.value = [
        EmotionalRecord(
          emotion: _selectedEmotion!,
          intensity: _intensity.round(),
          note: note,
          date: now,
        ),
        ...EmotionalStore.records.value,
      ];
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el registro: $e')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tu registro se guardó  Gracias por escucharte.'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NaraPalette>(
      valueListenable: NaraThemeController.current,
      builder: (context, palette, child) {
        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            title: const Text('¿Cómo me siento?'),
            backgroundColor: palette.surface,
            foregroundColor: palette.text,
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  Text(
                    'Date un momento para ti',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: palette.accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No hay emociones buenas o malas. '
                    'Elige la que mejor describa cómo te sientes ahora.',
                    style: TextStyle(height: 1.5, color: palette.text),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '¿Qué emoción estás sintiendo?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _emotions.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.65,
                        ),
                    itemBuilder: (context, index) {
                      final emotion = _emotions[index];
                      final name = emotion['name'] as String;
                      final selected = _selectedEmotion == name;

                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          setState(() {
                            _selectedEmotion = name;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: selected
                                ? palette.secondary
                                : palette.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected ? palette.accent : palette.border,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                emotion['emoji'] as String,
                                style: const TextStyle(fontSize: 29),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: palette.text,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Text(
                    '¿Qué tan intensa es esta emoción?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '1 · Muy leve',
                        style: TextStyle(color: palette.mutedText),
                      ),
                      Text(
                        '10 · Muy intensa',
                        style: TextStyle(color: palette.mutedText),
                      ),
                    ],
                  ),
                  Slider(
                    value: _intensity,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _intensity.round().toString(),
                    activeColor: palette.accent,
                    inactiveColor: palette.secondary,
                    onChanged: (value) {
                      setState(() {
                        _intensity = value;
                      });
                    },
                  ),
                  Center(
                    child: Text(
                      '${_intensity.round()} de 10',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: palette.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '¿Quieres contar algo más? (Opcional)',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 4,
                    maxLength: 500,
                    style: TextStyle(color: palette.text),
                    decoration: InputDecoration(
                      hintText: '¿Qué pasó o qué tienes en mente?',
                      hintStyle: TextStyle(color: palette.mutedText),
                      filled: true,
                      fillColor: palette.surface,
                      prefixIconColor: palette.accent,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: palette.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: palette.accent, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _saveRecord,
                      icon: const Icon(Icons.star_outline),
                      label: const Text('Guardar registro'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Este espacio es tuyo. Puedes compartir solo lo que quieras.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: palette.mutedText),
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

class EmotionHistoryScreen extends StatefulWidget {
  const EmotionHistoryScreen({super.key});

  @override
  State<EmotionHistoryScreen> createState() => _EmotionHistoryScreenState();
}

class _EmotionHistoryScreenState extends State<EmotionHistoryScreen> {
  @override
  void initState() {
    super.initState();

    final userId = NaraUserSession.currentUser.value?.idUsuario;

    if (userId != null) {
      EmotionalStore.loadRecords(userId);
      SymptomRecordStore.loadRecords(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NaraPalette>(
      valueListenable: NaraThemeController.current,
      builder: (context, palette, child) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: palette.background,
            appBar: AppBar(
              title: const Text('Mi historial'),
              backgroundColor: palette.surface,
              foregroundColor: palette.text,
              bottom: TabBar(
                labelColor: palette.accent,
                unselectedLabelColor: palette.mutedText,
                indicatorColor: palette.accent,
                tabs: const [
                  Tab(icon: Icon(Icons.favorite_outline), text: 'Emociones'),
                  Tab(
                    icon: Icon(Icons.monitor_heart_outlined),
                    text: 'Síntomas',
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _EmotionHistoryList(palette: palette),
                _SymptomHistoryList(palette: palette),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmotionHistoryList extends StatelessWidget {
  final NaraPalette palette;

  const _EmotionHistoryList({required this.palette});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<EmotionalRecord>>(
      valueListenable: EmotionalStore.records,
      builder: (context, records, child) {
        if (records.isEmpty) {
          return Center(
            child: Text(
              'Todavía no tienes registros emocionales.',
              style: TextStyle(color: palette.mutedText),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            final date = record.date;

            final dateText =
                '${date.day.toString().padLeft(2, '0')}/'
                '${date.month.toString().padLeft(2, '0')}/'
                '${date.year} · '
                '${date.hour.toString().padLeft(2, '0')}:'
                '${date.minute.toString().padLeft(2, '0')}';

            return Card(
              color: palette.surface,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: palette.iconBackground,
                  child: Icon(Icons.favorite, color: palette.accent),
                ),
                title: Text(
                  record.emotion,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
                subtitle: Text(
                  '$dateText\n'
                  'Intensidad: ${record.intensity}/10'
                  '${record.note.isEmpty ? '' : '\n${record.note}'}',
                  style: TextStyle(color: palette.mutedText, height: 1.5),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}

class _SymptomHistoryList extends StatelessWidget {
  final NaraPalette palette;

  const _SymptomHistoryList({required this.palette});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<SymptomRecord>>(
      valueListenable: SymptomRecordStore.records,
      builder: (context, records, child) {
        if (records.isEmpty) {
          return Center(
            child: Text(
              'Todavía no tienes registros de síntomas.',
              style: TextStyle(color: palette.mutedText),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            final date = record.date;

            final dateText =
                '${date.day.toString().padLeft(2, '0')}/'
                '${date.month.toString().padLeft(2, '0')}/'
                '${date.year} · '
                '${date.hour.toString().padLeft(2, '0')}:'
                '${date.minute.toString().padLeft(2, '0')}';

            return Card(
              color: palette.surface,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: palette.iconBackground,
                          child: Icon(
                            Icons.monitor_heart_outlined,
                            color: palette.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            dateText,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: palette.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...record.symptoms.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: TextStyle(
                                color: palette.text,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: entry.value / 5,
                                    color: palette.accent,
                                    backgroundColor: palette.iconBackground,
                                    minHeight: 7,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${entry.value}/5',
                                  style: TextStyle(
                                    color: palette.text,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    if (record.note.isNotEmpty) ...[
                      const Divider(),
                      Text(
                        'Nota: ${record.note}',
                        style: TextStyle(color: palette.mutedText, height: 1.5),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
