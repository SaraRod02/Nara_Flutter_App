import 'package:flutter/material.dart';

import '../theme_controller.dart';

class DiaryEntry {
  final String feelings;
  final String influence;
  final DateTime date;

  DiaryEntry({
    required this.feelings,
    required this.influence,
    required this.date,
  });
}

class DiaryStore {
  static final ValueNotifier<List<DiaryEntry>> entries =
      ValueNotifier<List<DiaryEntry>>([]);

  static void deleteEntry(DiaryEntry entry) {
    entries.value = entries.value
        .where((item) => !identical(item, entry))
        .toList();
  }
}

class DiaryScreen extends StatefulWidget {
  final NaraPalette palette;

  const DiaryScreen({super.key, required this.palette});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final TextEditingController feelingsController = TextEditingController();

  final TextEditingController influenceController = TextEditingController();

  @override
  void dispose() {
    feelingsController.dispose();
    influenceController.dispose();
    super.dispose();
  }

  void saveEntry() {
    final feelings = feelingsController.text.trim();
    final influence = influenceController.text.trim();

    if (feelings.isEmpty && influence.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe algo antes de guardar tu entrada.'),
        ),
      );
      return;
    }

    DiaryStore.entries.value = [
      DiaryEntry(
        feelings: feelings,
        influence: influence,
        date: DateTime.now(),
      ),
      ...DiaryStore.entries.value,
    ];

    feelingsController.clear();
    influenceController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tu entrada se guardó correctamente 💜')),
    );
  }

  Future<void> confirmDelete(DiaryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar entrada'),
          content: const Text(
            '¿Estás segura de que deseas eliminar esta entrada? '
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      DiaryStore.deleteEntry(entry);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Entrada eliminada.')));
    }
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} - '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi diario emocional')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.menu_book_rounded, size: 55, color: palette.accent),

            const SizedBox(height: 12),

            Text(
              'Un espacio solo para ti ✨',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: palette.accent,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'No tienes que escribir todos los días. '
              'Este espacio está aquí cuando quieras expresarte.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.text, height: 1.5),
            ),

            const SizedBox(height: 26),

            Text(
              '¿Cómo me siento hoy?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: palette.text,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: feelingsController,
              maxLines: 5,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Escribe libremente lo que pasa por tu mente...',
                filled: true,
                fillColor: palette.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              '¿Qué influyó en mi día?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: palette.text,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: influenceController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Una situación, un pensamiento o algo que ocurrió...',
                filled: true,
                fillColor: palette.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: saveEntry,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar entrada'),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'Mis entradas anteriores',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: palette.accent,
              ),
            ),

            const SizedBox(height: 14),

            ValueListenableBuilder<List<DiaryEntry>>(
              valueListenable: DiaryStore.entries,
              builder: (context, entries, _) {
                if (entries.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Todavía no tienes entradas. '
                      'Cuando guardes la primera, aparecerá aquí. 💜',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.mutedText),
                    ),
                  );
                }

                return Column(
                  children: entries.map((entry) {
                    return Card(
                      color: palette.surface,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: palette.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    formatDate(entry.date),
                                    style: TextStyle(
                                      color: palette.mutedText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: palette.mutedText,
                                  ),
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      confirmDelete(entry);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Eliminar'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            if (entry.feelings.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                '¿Cómo me sentí?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: palette.accent,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                entry.feelings,
                                style: TextStyle(color: palette.text),
                              ),
                            ],

                            if (entry.influence.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                '¿Qué influyó en mi día?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: palette.accent,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                entry.influence,
                                style: TextStyle(color: palette.text),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


class DiaryDetailScreen extends StatelessWidget {
  final DiaryEntry entry;
  final NaraPalette palette;

  const DiaryDetailScreen({
    super.key,
    required this.entry,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final date = entry.date;

    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} - '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi entrada'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 55,
              color: palette.accent,
            ),

            const SizedBox(height: 16),

            Text(
              formattedDate,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.mutedText),
            ),

            const SizedBox(height: 28),

            if (entry.feelings.isNotEmpty) ...[
              Text(
                '¿Cómo me sentí?',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: palette.accent,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                entry.feelings,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: palette.text,
                ),
              ),
            ],

            if (entry.influence.isNotEmpty) ...[
              const SizedBox(height: 26),
              Text(
                '¿Qué influyó en mi día?',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: palette.accent,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                entry.influence,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: palette.text,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

