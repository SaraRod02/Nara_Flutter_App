
import '../database/nara_database.dart';

class ProfessionalConsentService {
  /// Consulta si un paciente ha concedido acceso a un especialista.
  static Future<bool> hasConsent({
    required int patientId,
    required int psychologistId,
  }) async {
    final db = await NaraDatabase.database;

    final result = await db.query(
      'consentimiento_profesional',
      columns: ['id_consentimiento'],
      where: '''
        id_usuario_paciente = ?
        AND id_psicologo = ?
        AND estado = 'concedido'
      ''',
      whereArgs: [patientId, psychologistId],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// Concede o reactiva el permiso para consultar información.
  static Future<void> grantConsent({
    required int patientId,
    required int psychologistId,
  }) async {
    if (patientId == psychologistId) {
      throw ArgumentError('El paciente y el especialista deben ser distintos.');
    }

    final db = await NaraDatabase.database;

    await db.transaction((txn) async {
      final existing = await txn.query(
        'consentimiento_profesional',
        columns: ['id_consentimiento'],
        where: '''
          id_usuario_paciente = ?
          AND id_psicologo = ?
          AND estado = 'concedido'
        ''',
        whereArgs: [patientId, psychologistId],
        limit: 1,
      );

      if (existing.isNotEmpty) return;

      await txn.insert('consentimiento_profesional', {
        'id_usuario_paciente': patientId,
        'id_psicologo': psychologistId,
        'estado': 'concedido',
        'fecha_concesion': DateTime.now().toIso8601String(),
        'fecha_revocacion': null,
      });
    });
  }

  /// Revoca el permiso sin eliminar el historial del consentimiento.
  static Future<void> revokeConsent({
    required int patientId,
    required int psychologistId,
  }) async {
    final db = await NaraDatabase.database;

    await db.update(
      'consentimiento_profesional',
      {
        'estado': 'revocado',
        'fecha_revocacion': DateTime.now().toIso8601String(),
      },
      where: '''
        id_usuario_paciente = ?
        AND id_psicologo = ?
        AND estado = 'concedido'
      ''',
      whereArgs: [patientId, psychologistId],
    );
  }
}
