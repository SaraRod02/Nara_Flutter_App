import '../database/nara_database.dart';

class ProfessionalRecordService {
  /// Comprueba que exista una vinculación activa y un consentimiento vigente.
  static Future<bool> _hasAccess({
    required int patientId,
    required int psychologistId,
  }) async {
    final db = await NaraDatabase.database;

    final result = await db.rawQuery(
      '''
      SELECT 1
      FROM paciente p
      INNER JOIN consentimiento_profesional c
        ON c.id_usuario_paciente = p.id_usuario_paciente
        AND c.id_psicologo = p.id_psicologo
      WHERE p.id_usuario_paciente = ?
        AND p.id_psicologo = ?
        AND p.fecha_fin IS NULL
        AND c.estado = 'concedido'
      LIMIT 1
      ''',
      [patientId, psychologistId],
    );

    return result.isNotEmpty;
  }

  /// Consulta los registros emocionales autorizados.
  static Future<List<Map<String, dynamic>>> getEmotionalRecords({
    required int patientId,
    required int psychologistId,
  }) async {
    final hasAccess = await _hasAccess(
      patientId: patientId,
      psychologistId: psychologistId,
    );

    if (!hasAccess) {
      throw StateError(
        'No tienes autorización para consultar estos registros.',
      );
    }

    final db = await NaraDatabase.database;

    return db.query(
      'registro_emocional',
      where: 'id_usuario = ?',
      whereArgs: [patientId],
      orderBy: 'fecha_registro DESC',
    );
  }

  /// Consulta los registros de síntomas autorizados.
  static Future<List<Map<String, dynamic>>> getSymptomRecords({
    required int patientId,
    required int psychologistId,
  }) async {
    final hasAccess = await _hasAccess(
      patientId: patientId,
      psychologistId: psychologistId,
    );

    if (!hasAccess) {
      throw StateError(
        'No tienes autorización para consultar estos registros.',
      );
    }

    final db = await NaraDatabase.database;

    return db.rawQuery(
      '''
      SELECT
        r.id_registro_sintomas,
        r.id_usuario,
        r.comentario,
        r.fecha_registro,
        d.nombre_sintoma,
        d.nivel_intensidad
      FROM registro_sintomas r
      INNER JOIN detalle_sintoma d
        ON d.id_registro_sintomas = r.id_registro_sintomas
      WHERE r.id_usuario = ?
      ORDER BY r.fecha_registro DESC
      ''',
      [patientId],
    );
  }
}
