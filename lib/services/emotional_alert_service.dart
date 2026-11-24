
import '../database/nara_database.dart';

class EmotionalAlertService {
  static Future<void> checkAndGenerateAlert({
    required int patientId,
    required String emotion,
    required int intensity,
  }) async {
    // Solo se evalúa tristeza con intensidad máxima.
    if (emotion != 'Triste' || intensity != 10) return;

    final db = await NaraDatabase.database;

    await db.transaction((txn) async {
      // Contar los registros que cumplen la condición.
      final countResult = await txn.rawQuery(
        '''
        SELECT COUNT(*) AS total
        FROM registro_emocional
        WHERE id_usuario = ?
          AND emocion = 'Triste'
          AND nivel_intensidad = 10
        ''',
        [patientId],
      );

      final total = countResult.first['total'] as int;

      // Calcular cuántas alertas deberían existir.
      // Se genera una alerta por cada grupo de tres registros.
      final expectedAlerts = total ~/ 3;

      // Si todavía no existen tres registros, no generar alerta.
      if (expectedAlerts == 0) return;

      // Obtener especialistas con vínculo activo
      // y consentimiento concedido.
      final professionals = await txn.rawQuery(
        '''
        SELECT DISTINCT p.id_psicologo
        FROM paciente p
        INNER JOIN consentimiento_profesional c
          ON c.id_usuario_paciente = p.id_usuario_paciente
          AND c.id_psicologo = p.id_psicologo
        WHERE p.id_usuario_paciente = ?
          AND p.fecha_fin IS NULL
          AND c.estado = 'concedido'
        ''',
        [patientId],
      );

      for (final professional in professionals) {
        final psychologistId = professional['id_psicologo'] as int;

        // Contar las alertas que ya existen para este paciente
        // y este especialista.
        final alertCountResult = await txn.rawQuery(
          '''
          SELECT COUNT(*) AS total
          FROM alerta_emocional
          WHERE id_usuario_paciente = ?
            AND id_psicologo = ?
            AND motivo = ?
          ''',
          [
            patientId,
            psychologistId,
            'tristeza_intensidad_maxima',
          ],
        );

        final existingAlerts =
            alertCountResult.first['total'] as int;

        // Evitar generar alertas duplicadas.
        if (existingAlerts >= expectedAlerts) continue;

        // Crear la nueva alerta.
        await txn.insert('alerta_emocional', {
          'id_usuario_paciente': patientId,
          'id_psicologo': psychologistId,
          'motivo': 'tristeza_intensidad_maxima',
          'descripcion':
              'El paciente ha registrado tristeza con intensidad 10 '
              'en al menos tres ocasiones.',
          'estado': 'pendiente',
        });
      }
    });
  }
}
