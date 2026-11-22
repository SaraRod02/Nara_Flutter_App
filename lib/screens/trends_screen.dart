import 'package:material_ui/material_ui.dart';

import '../theme_controller.dart';
import 'emotion_screen.dart';
import 'symptom_screen.dart';
import '../models/nara_user_session.dart';

class TrendsScreen extends StatefulWidget {
  final NaraPalette palette;

  const TrendsScreen({super.key, required this.palette});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = NaraUserSession.currentUser.value?.idUsuario;

    if (userId != null) {
      await Future.wait([
        EmotionalStore.loadRecords(userId),
        SymptomRecordStore.loadRecords(userId),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Scaffold(
      appBar: AppBar(title: const Text('Mis tendencias')),
      body: ValueListenableBuilder<List<EmotionalRecord>>(
        valueListenable: EmotionalStore.records,
        builder: (context, emotionalRecords, _) {
          return ValueListenableBuilder<List<SymptomRecord>>(
            valueListenable: SymptomRecordStore.records,
            builder: (context, symptomRecords, _) {
              final averageEmotion = emotionalRecords.isEmpty
                  ? 0.0
                  : emotionalRecords
                            .map((record) => record.intensity)
                            .reduce((a, b) => a + b) /
                        emotionalRecords.length;

              final emotionCounts = <String, int>{};

              for (final record in emotionalRecords) {
                emotionCounts[record.emotion] =
                    (emotionCounts[record.emotion] ?? 0) + 1;
              }

              final sortedEmotions = emotionCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              final symptomCounts = <String, int>{};
              final symptomIntensities = <String, List<int>>{};

              for (final record in symptomRecords) {
                record.symptoms.forEach((symptom, intensity) {
                  symptomCounts[symptom] = (symptomCounts[symptom] ?? 0) + 1;

                  symptomIntensities
                      .putIfAbsent(symptom, () => [])
                      .add(intensity);
                });
              }

              final sortedSymptoms = symptomCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Conócete un poquito más ✨',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aquí puedes observar cómo te has sentido y '
                      'qué síntomas has registrado.',
                      style: TextStyle(color: palette.mutedText),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            title: 'Registros emocionales',
                            value: '${emotionalRecords.length}',
                            icon: Icons.favorite_outline,
                            color: palette.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            title: 'Registros de síntomas',
                            value: '${symptomRecords.length}',
                            icon: Icons.spa_outlined,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _MetricCard(
                      title: 'Intensidad emocional promedio',
                      value: emotionalRecords.isEmpty
                          ? 'Sin datos'
                          : '${averageEmotion.toStringAsFixed(1)} / 10',
                      icon: Icons.insights_outlined,
                      color: palette.accent,
                    ),

                    const SizedBox(height: 24),

                    _SectionTitle(title: 'Emociones frecuentes 💜'),

                    if (sortedEmotions.isEmpty)
                      const _EmptyMessage(
                        message: 'Todavía no tienes registros emocionales.',
                      )
                    else
                      ...sortedEmotions.map(
                        (entry) => _ProgressItem(
                          title: entry.key,
                          count: entry.value,
                          total: emotionalRecords.length,
                          color: palette.accent,
                        ),
                      ),

                    const SizedBox(height: 24),

                    _SectionTitle(title: 'Síntomas registrados 🌿'),

                    if (sortedSymptoms.isEmpty)
                      const _EmptyMessage(
                        message: 'Todavía no tienes registros de síntomas.',
                      )
                    else
                      ...sortedSymptoms.map((entry) {
                        final intensities = symptomIntensities[entry.key]!;
                        final average =
                            intensities.reduce((a, b) => a + b) /
                            intensities.length;

                        return _SymptomItem(
                          title: entry.key,
                          count: entry.value,
                          average: average,
                          total: symptomRecords.length,
                        );
                      }),

                    const SizedBox(height: 20),

                    Text(
                      'Tus tendencias se calculan a partir de los registros '
                      'disponibles en esta sesión. No representan un '
                      'diagnóstico médico.',
                      style: TextStyle(color: palette.mutedText, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ProgressItem extends StatelessWidget {
  final String title;
  final int count;
  final int total;
  final Color color;

  const _ProgressItem({
    required this.title,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title)),
              Text('$count ${count == 1 ? 'vez' : 'veces'}'),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: total == 0 ? 0 : count / total,
            color: color,
            backgroundColor: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }
}

class _SymptomItem extends StatelessWidget {
  final String title;
  final int count;
  final double average;
  final int total;

  const _SymptomItem({
    required this.title,
    required this.count,
    required this.average,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          '$count ${count == 1 ? 'registro' : 'registros'} · '
          'Intensidad promedio: ${average.toStringAsFixed(1)} / 5',
        ),
        trailing: const Icon(Icons.show_chart),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String message;

  const _EmptyMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
