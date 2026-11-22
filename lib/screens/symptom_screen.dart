import 'package:material_ui/material_ui.dart';

import '../theme_controller.dart';
import '../database/nara_database.dart';
import '../models/nara_user_session.dart';

class SymptomRecord {
  final Map<String, int> symptoms;
  final String note;
  final DateTime date;

  SymptomRecord({
    required this.symptoms,
    required this.note,
    required this.date,
  });
}

class SymptomRecordStore {
  static final ValueNotifier<List<SymptomRecord>> records =
      ValueNotifier<List<SymptomRecord>>([]);

  static void addRecord(SymptomRecord record) {
    records.value = [...records.value, record];
  }

  static Future<void> loadRecords(int userId) async {
    final db = await NaraDatabase.database;

    final savedRecords = await db.query(
      'registro_sintomas',
      where: 'id_usuario = ?',
      whereArgs: [userId],
      orderBy: 'fecha_registro DESC',
    );

    final loadedRecords = <SymptomRecord>[];

    for (final savedRecord in savedRecords) {
      final recordId = savedRecord['id_registro_sintomas'] as int;

      final details = await db.query(
        'detalle_sintoma',
        where: 'id_registro_sintomas = ?',
        whereArgs: [recordId],
      );

      final symptoms = <String, int>{};

      for (final detail in details) {
        symptoms[detail['nombre_sintoma'] as String] =
            detail['nivel_intensidad'] as int;
      }

      loadedRecords.add(
        SymptomRecord(
          symptoms: symptoms,
          note: savedRecord['comentario'] as String? ?? '',
          date: DateTime.parse(savedRecord['fecha_registro'] as String),
        ),
      );
    }

    records.value = loadedRecords;
  }
}

class SymptomScreen extends StatefulWidget {
  final NaraPalette palette;

  const SymptomScreen({super.key, required this.palette});

  @override
  State<SymptomScreen> createState() => _SymptomScreenState();
}

class _SymptomScreenState extends State<SymptomScreen> {
  final List<String> availableSymptoms = [
    'Inquietud o nerviosismo',
    'Tensión muscular',
    'Dificultad para concentrarme',
    'Cansancio o fatiga',
    'Problemas para dormir',
    'Irritabilidad',
    'Respiración acelerada',
  ];

  final Map<String, int> selectedSymptoms = {};

  final TextEditingController noteController = TextEditingController();

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<void> saveRecord() async {
    if (selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un síntoma.')),
      );
      return;
    }

    final userId = NaraUserSession.currentUser.value?.idUsuario;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar al usuario.')),
      );
      return;
    }

    final now = DateTime.now();
    final note = noteController.text.trim();

    try {
      final db = await NaraDatabase.database;

      await db.transaction((txn) async {
        final recordId = await txn.insert('registro_sintomas', {
          'id_usuario': userId,
          'comentario': note,
          'fecha_registro': now.toIso8601String(),
        });

        for (final entry in selectedSymptoms.entries) {
          await txn.insert('detalle_sintoma', {
            'id_registro_sintomas': recordId,
            'nombre_sintoma': entry.key,
            'nivel_intensidad': entry.value,
          });
        }
      });

      SymptomRecordStore.addRecord(
        SymptomRecord(
          symptoms: Map<String, int>.from(selectedSymptoms),
          note: note,
          date: now,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu registro se guardó correctamente 💜')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el registro: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar síntomas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¿Qué has sentido últimamente?',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: palette.accent,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Selecciona los síntomas que has experimentado '
              'y evalúa la intensidad de cada uno.',
              style: TextStyle(color: palette.text, height: 1.5),
            ),

            const SizedBox(height: 24),

            Text(
              'Identifica tus síntomas',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: palette.text,
              ),
            ),

            const SizedBox(height: 10),

            ...availableSymptoms.map((symptom) {
              final isSelected = selectedSymptoms.containsKey(symptom);
              final currentIntensity = selectedSymptoms[symptom] ?? 3;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: palette.accent,
                        title: Text(
                          symptom,
                          style: TextStyle(
                            color: palette.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: isSelected,
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              selectedSymptoms[symptom] = 3;
                            } else {
                              selectedSymptoms.remove(symptom);
                            }
                          });
                        },
                      ),

                      if (isSelected) ...[
                        const Divider(),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Intensidad: $currentIntensity de 5',
                            style: TextStyle(
                              color: palette.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        Slider(
                          value: currentIntensity.toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          activeColor: palette.accent,
                          label: currentIntensity.toString(),
                          onChanged: (value) {
                            setState(() {
                              selectedSymptoms[symptom] = value.round();
                            });
                          },
                        ),

                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text('Muy leve'), Text('Muy intenso')],
                        ),

                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            Text(
              'Escala de intensidad',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: palette.text,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '1 - Muy leve\n'
              '2 - Leve\n'
              '3 - Moderado\n'
              '4 - Intenso\n'
              '5 - Muy intenso',
              style: TextStyle(color: palette.text, height: 1.7),
            ),

            const SizedBox(height: 24),

            Text(
              '¿Quieres agregar algún comentario?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: palette.text,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Escribe cómo te has sentido...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 28),

            FilledButton.icon(
              onPressed: saveRecord,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar registro'),
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
