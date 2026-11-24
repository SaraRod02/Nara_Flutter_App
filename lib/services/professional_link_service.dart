import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../database/nara_database.dart';

enum ProfessionalLinkResult {
  success,
  invalidCode,
  expiredCode,
  alreadyRequested,
  alreadyLinked,
  alreadyHasProfessionalOfType,
  selfRequest,
  wrongRole,
}

class ProfessionalLinkService {
  static const int codeValidityDays = 7;

  static String _generateCode() {
    final random = Random.secure();
    return (random.nextInt(900000) + 100000).toString();
  }

  static Future<String> getOrCreateCode(
    int patientId,
    String tipoProfesional,
  ) async {
    final db = await NaraDatabase.database;

    final existing = await db.query(
      'codigo_psicologo',
      columns: ['codigo', 'fecha_expiracion'],
      where: '''
        id_usuario_paciente = ?
        AND tipo_profesional = ?
      ''',
      whereArgs: [patientId, tipoProfesional],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final expiration = DateTime.tryParse(
        existing.first['fecha_expiracion'] as String,
      );

      if (expiration != null && expiration.isAfter(DateTime.now().toUtc())) {
        return existing.first['codigo'] as String;
      }
    }

    return _saveNewCode(db, patientId, tipoProfesional);
  }

  static Future<ProfessionalLinkResult> requestByCode({
    required String code,
    required int psychologistId,
  }) async {
    final db = await NaraDatabase.database;

    final psychologist = await db.query(
      'psicologo',
      columns: ['tipo_profesional'],
      where: 'id_psicologo = ?',
      whereArgs: [psychologistId],
      limit: 1,
    );

    if (psychologist.isEmpty) {
      return ProfessionalLinkResult.wrongRole;
    }

    final professionalType = psychologist.first['tipo_profesional'] as String;

    final codeResult = await db.query(
      'codigo_psicologo',
      where: 'codigo = ?',
      whereArgs: [code.trim()],
      limit: 1,
    );

    if (codeResult.isEmpty) {
      return ProfessionalLinkResult.invalidCode;
    }

    final invitation = codeResult.first;
    final patientId = invitation['id_usuario_paciente'] as int;
    final invitationType = invitation['tipo_profesional'] as String;

    if (invitationType != professionalType) {
      return ProfessionalLinkResult.wrongRole;
    }

    final expiration = DateTime.tryParse(
      invitation['fecha_expiracion'] as String,
    );

    if (expiration == null || !expiration.isAfter(DateTime.now().toUtc())) {
      return ProfessionalLinkResult.expiredCode;
    }

    if (patientId == psychologistId) {
      return ProfessionalLinkResult.selfRequest;
    }

    final patient = await db.query(
      'usuario',
      columns: ['id_usuario'],
      where: 'id_usuario = ? AND rol = ?',
      whereArgs: [patientId, 'paciente'],
      limit: 1,
    );

    if (patient.isEmpty) {
      return ProfessionalLinkResult.wrongRole;
    }

    final linked = await db.query(
      'paciente',
      where: '''
        id_usuario_paciente = ?
        AND id_psicologo = ?
        AND fecha_fin IS NULL
      ''',
      whereArgs: [patientId, psychologistId],
      limit: 1,
    );

    if (linked.isNotEmpty) {
      return ProfessionalLinkResult.alreadyLinked;
    }

    final existingProfessional = await db.rawQuery(
      '''
      SELECT p.id_psicologo
      FROM paciente p
      INNER JOIN psicologo ps
        ON ps.id_psicologo = p.id_psicologo
      WHERE p.id_usuario_paciente = ?
        AND ps.tipo_profesional = ?
        AND p.fecha_fin IS NULL
      LIMIT 1
    ''',
      [patientId, professionalType],
    );

    if (existingProfessional.isNotEmpty) {
      return ProfessionalLinkResult.alreadyHasProfessionalOfType;
    }

    final pending = await db.query(
      'solicitud_psicologo',
      where: '''
        id_usuario_paciente = ?
        AND id_psicologo = ?
        AND estado = ?
      ''',
      whereArgs: [patientId, psychologistId, 'pendiente'],
      limit: 1,
    );

    if (pending.isNotEmpty) {
      return ProfessionalLinkResult.alreadyRequested;
    }

    await db.insert('solicitud_psicologo', {
      'id_usuario_paciente': patientId,
      'id_psicologo': psychologistId,
      'codigo_utilizado': code.trim(),
      'estado': 'pendiente',
    });

    return ProfessionalLinkResult.success;
  }

  static Future<List<Map<String, dynamic>>> getPendingRequests(
    int patientId,
  ) async {
    final db = await NaraDatabase.database;

    return db.rawQuery(
      '''
      SELECT
        s.id_solicitud,
        s.id_psicologo,
        s.fecha_solicitud,
        u.nombre,
        u.correo,
        p.especialidad,
        p.cedula_profesional,
        p.tipo_profesional
      FROM solicitud_psicologo s
      INNER JOIN usuario u
        ON u.id_usuario = s.id_psicologo
      INNER JOIN psicologo p
        ON p.id_psicologo = s.id_psicologo
      WHERE s.id_usuario_paciente = ?
        AND s.estado = 'pendiente'
      ORDER BY s.fecha_solicitud DESC
    ''',
      [patientId],
    );
  }

  static Future<ProfessionalLinkResult> respondToRequest({
    required int requestId,
    required int patientId,
    required bool accept,
  }) async {
    final db = await NaraDatabase.database;

    return db.transaction((txn) async {
      final requests = await txn.query(
        'solicitud_psicologo',
        where: '''
          id_solicitud = ?
          AND id_usuario_paciente = ?
          AND estado = ?
        ''',
        whereArgs: [requestId, patientId, 'pendiente'],
        limit: 1,
      );

      if (requests.isEmpty) {
        return ProfessionalLinkResult.invalidCode;
      }

      final psychologistId = requests.first['id_psicologo'] as int;

      if (accept) {
        final professional = await txn.query(
          'psicologo',
          columns: ['tipo_profesional'],
          where: 'id_psicologo = ?',
          whereArgs: [psychologistId],
          limit: 1,
        );

        if (professional.isEmpty) {
          return ProfessionalLinkResult.wrongRole;
        }

        final professionalType =
            professional.first['tipo_profesional'] as String;

        final existing = await txn.query(
          'paciente',
          where: '''
            id_usuario_paciente = ?
            AND id_psicologo = ?
            AND fecha_fin IS NULL
          ''',
          whereArgs: [patientId, psychologistId],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          await txn.update(
            'solicitud_psicologo',
            {
              'estado': 'rechazada',
              'fecha_respuesta': DateTime.now().toIso8601String(),
            },
            where: 'id_solicitud = ?',
            whereArgs: [requestId],
          );

          return ProfessionalLinkResult.alreadyLinked;
        }

        final existingProfessional = await txn.rawQuery(
          '''
          SELECT p.id_psicologo
          FROM paciente p
          INNER JOIN psicologo ps
            ON ps.id_psicologo = p.id_psicologo
          WHERE p.id_usuario_paciente = ?
            AND ps.tipo_profesional = ?
            AND p.fecha_fin IS NULL
          LIMIT 1
        ''',
          [patientId, professionalType],
        );

        if (existingProfessional.isNotEmpty) {
          await txn.update(
            'solicitud_psicologo',
            {
              'estado': 'rechazada',
              'fecha_respuesta': DateTime.now().toIso8601String(),
            },
            where: 'id_solicitud = ?',
            whereArgs: [requestId],
          );

          return ProfessionalLinkResult.alreadyHasProfessionalOfType;
        }

        await txn.insert('paciente', {
          'id_usuario_paciente': patientId,
          'id_psicologo': psychologistId,
        });
      }

      await txn.update(
        'solicitud_psicologo',
        {
          'estado': accept ? 'aceptada' : 'rechazada',
          'fecha_respuesta': DateTime.now().toIso8601String(),
        },
        where: '''
          id_solicitud = ?
          AND id_usuario_paciente = ?
          AND estado = ?
        ''',
        whereArgs: [requestId, patientId, 'pendiente'],
      );

      return ProfessionalLinkResult.success;
    });
  }

  static Future<bool> hasProfessionalConsent({
    required int patientId,
    required int psychologistId,
  }) async {
    final db = await NaraDatabase.database;

    final result = await db.query(
      'consentimiento_profesional',
      where: '''
        id_usuario_paciente = ?
        AND id_psicologo = ?
        AND estado = ?
      ''',
      whereArgs: [patientId, psychologistId, 'concedido'],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  static Future<void> grantProfessionalConsent({
    required int patientId,
    required int psychologistId,
  }) async {
    final db = await NaraDatabase.database;

    await db.transaction((txn) async {
      final existing = await txn.query(
        'consentimiento_profesional',
        where: '''
          id_usuario_paciente = ?
          AND id_psicologo = ?
        ''',
        whereArgs: [patientId, psychologistId],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        await txn.update(
          'consentimiento_profesional',
          {
            'estado': 'concedido',
            'fecha_concesion': DateTime.now().toIso8601String(),
            'fecha_revocacion': null,
          },
          where: 'id_consentimiento = ?',
          whereArgs: [existing.first['id_consentimiento']],
        );
      } else {
        await txn.insert('consentimiento_profesional', {
          'id_usuario_paciente': patientId,
          'id_psicologo': psychologistId,
          'estado': 'concedido',
        });
      }
    });
  }

  static Future<void> revokeProfessionalConsent({
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
        AND estado = ?
      ''',
      whereArgs: [patientId, psychologistId, 'concedido'],
    );
  }

  static Future<List<Map<String, dynamic>>> getLinkedPatients(
    int psychologistId,
  ) 
  async {
    final db = await NaraDatabase.database;

    return db.rawQuery(
      '''
    SELECT
      p.id_usuario_paciente,
      u.nombre,
      u.correo,
      p.fecha_inicio,
      ps.tipo_profesional,
      CASE
        WHEN EXISTS (
          SELECT 1
          FROM consentimiento_profesional c
          WHERE c.id_usuario_paciente = p.id_usuario_paciente
            AND c.id_psicologo = p.id_psicologo
            AND c.estado = 'concedido'
        )
        THEN 1
        ELSE 0
      END AS tiene_consentimiento
    FROM paciente p
    INNER JOIN usuario u
      ON u.id_usuario = p.id_usuario_paciente
    INNER JOIN psicologo ps
      ON ps.id_psicologo = p.id_psicologo
    WHERE p.id_psicologo = ?
      AND p.fecha_fin IS NULL
    ORDER BY u.nombre ASC
    ''',
      [psychologistId],
    );
  }

  static Future<List<Map<String, dynamic>>> getPendingRequestsForProfessional(
    int professionalId,
  ) async {
    final db = await NaraDatabase.database;

    return db.rawQuery(
      '''
    SELECT
      s.id_solicitud,
      s.id_usuario_paciente,
      s.fecha_solicitud,
      u.nombre,
      u.correo,
      ps.tipo_profesional
    FROM solicitud_psicologo s
    INNER JOIN usuario u
      ON u.id_usuario = s.id_usuario_paciente
    INNER JOIN psicologo ps
      ON ps.id_psicologo = s.id_psicologo
    WHERE s.id_psicologo = ?
      AND s.estado = 'pendiente'
    ORDER BY s.fecha_solicitud DESC
    ''',
      [professionalId],
    );
  }

  static Future<Map<String, dynamic>?> getLinkedProfessional(
    int patientId,
    String tipoProfesional,
  ) async {
    final db = await NaraDatabase.database;

    
final result = await db.rawQuery(
  '''
  SELECT
    pa.id_psicologo,
    u.nombre,
    u.correo,
    ps.telefono,
    ps.especialidad,
    ps.cedula_profesional,
    ps.tipo_profesional,
    pa.fecha_inicio,
    CASE
      WHEN EXISTS (
        SELECT 1
        FROM consentimiento_profesional c
        WHERE c.id_usuario_paciente = pa.id_usuario_paciente
          AND c.id_psicologo = pa.id_psicologo
          AND c.estado = 'concedido'
      )
      THEN 1
      ELSE 0
    END AS tiene_consentimiento
  FROM paciente pa
  INNER JOIN usuario u
    ON u.id_usuario = pa.id_psicologo
  INNER JOIN psicologo ps
    ON ps.id_psicologo = pa.id_psicologo
  WHERE pa.id_usuario_paciente = ?
    AND ps.tipo_profesional = ?
    AND pa.fecha_fin IS NULL
  LIMIT 1
  ''',
  [patientId, tipoProfesional],
);


    if (result.isEmpty) return null;

    return result.first;
  }

  static Future<bool> endLink({
    required int patientId,
    required int psychologistId,
  }) async {
    final db = await NaraDatabase.database;

    final todayResult = await db.rawQuery("SELECT date('now') AS today");
    final today = todayResult.first['today'] as String;

    final updated = await db.update(
      'paciente',
      {'fecha_fin': today},
      where: '''
        id_usuario_paciente = ?
        AND id_psicologo = ?
        AND fecha_fin IS NULL
      ''',
      whereArgs: [patientId, psychologistId],
    );

    return updated > 0;
  }

  static Future<String> renewCode(int patientId, String tipoProfesional) async {
    final db = await NaraDatabase.database;
    return _saveNewCode(db, patientId, tipoProfesional);
  }

  static Future<String?> getCodeExpiration(
    int patientId,
    String tipoProfesional,
  ) async {
    final db = await NaraDatabase.database;

    final result = await db.query(
      'codigo_psicologo',
      columns: ['fecha_expiracion'],
      where: '''
        id_usuario_paciente = ?
        AND tipo_profesional = ?
      ''',
      whereArgs: [patientId, tipoProfesional],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return result.first['fecha_expiracion'] as String;
  }

  static Future<String> _saveNewCode(
    Database db,
    int patientId,
    String tipoProfesional,
  ) async {
    String code;

    do {
      code = _generateCode();

      final existing = await db.query(
        'codigo_psicologo',
        where: 'codigo = ?',
        whereArgs: [code],
        limit: 1,
      );

      if (existing.isEmpty) break;
    } while (true);

    final expiration = DateTime.now()
        .toUtc()
        .add(const Duration(days: codeValidityDays))
        .toIso8601String();

    await db.insert('codigo_psicologo', {
      'id_usuario_paciente': patientId,
      'codigo': code,
      'tipo_profesional': tipoProfesional,
      'fecha_expiracion': expiration,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    return code;
  }
}
