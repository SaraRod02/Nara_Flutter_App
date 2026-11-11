
import 'package:flutter/material.dart';
import '../theme_controller.dart';

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
}

class SymptomScreen extends StatefulWidget {
  final NaraPalette palette;

  const SymptomScreen({
    super.key,
    required this.palette,
  });

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

  void saveRecord() {
    if (selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un síntoma.'),
        ),
      );
      return;
    }

    SymptomRecordStore.addRecord(
      SymptomRecord(
        symptoms: Map<String, int>.from(selectedSymptoms),
        note: noteController.text.trim(),
        date: DateTime.now(),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tu registro se guardó correctamente 💜'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar síntomas'),
      ),
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
              style: TextStyle(
                color: palette.text,
                height: 1.5,
              ),
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
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Muy leve'),
                            Text('Muy intenso'),
                          ],
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
              style: TextStyle(
                color: palette.text,
                height: 1.7,
              ),
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
