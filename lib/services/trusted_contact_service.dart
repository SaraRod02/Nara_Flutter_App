import 'package:sqflite/sqflite.dart';

import '../database/nara_database.dart';
import '../models/trusted_contact.dart';

enum TrustedContactRequestResult {
  success,
  invalidCode,
  alreadyRequested,
  alreadyLinked,
  selfRequest,
  wrongRole,
}

class TrustedContactService {
  // =========================================
  // CÓDIGO DE INVITACIÓN
  // =========================================

  static Future<String> getOrCreateCode(int principalId) async {
    final db = await NaraDatabase.database;

    final existing = await db.query(
      'codigo_invitacion',
      where: 'id_usuario_principal = ?',
      whereArgs: [principalId],
    );

    if (existing.isNotEmpty) {
      return existing.first['codigo'] as String;
    }

    return _saveNewCode(db, principalId);
  }

  static Future<String> renewCode(int principalId) async {
    final db = await NaraDatabase.database;
    return _saveNewCode(db, principalId);
  }

  static Future<String> _saveNewCode(Database db, int principalId) async {
    String code;

    while (true) {
      code = TrustedContactCode.generate();

      final existing = await db.query(
        'codigo_invitacion',
        where: 'codigo = ?',
        whereArgs: [code],
      );

      if (existing.isEmpty) break;
    }

    await db.insert('codigo_invitacion', {
      'id_usuario_principal': principalId,
      'codigo': code,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    return code;
  }

  // =========================================
  // ENVIAR SOLICITUD
  // =========================================

  static Future<TrustedContactRequestResult> requestByCode({
    required String code,
    required int contactId,
  }) async {
    final db = await NaraDatabase.database;

    // Comprobar que el contacto existe y tiene el rol correcto.
    final contactUser = await db.query(
      'usuario',
      where: 'id_usuario = ?',
      whereArgs: [contactId],
    );

    if (contactUser.isEmpty ||
        contactUser.first['rol'] != 'contacto_confianza') {
      return TrustedContactRequestResult.wrongRole;
    }

    // Buscar al usuario principal mediante el código.
    final invitation = await db.query(
      'codigo_invitacion',
      where: 'codigo = ?',
      whereArgs: [code],
    );

    if (invitation.isEmpty) {
      return TrustedContactRequestResult.invalidCode;
    }

    final principalId = invitation.first['id_usuario_principal'] as int;

    // Evitar que una persona se vincule consigo misma.
    if (principalId == contactId) {
      return TrustedContactRequestResult.selfRequest;
    }

    // Comprobar que el código pertenece a un usuario principal.
    final principalUser = await db.query(
      'usuario',
      where: 'id_usuario = ?',
      whereArgs: [principalId],
    );

    if (principalUser.isEmpty || principalUser.first['rol'] != 'paciente') {
      return TrustedContactRequestResult.invalidCode;
    }

    // Buscar si ya existe una relación entre ambos.
    final existing = await db.query(
      'contacto_confianza',
      where: 'id_usuario_principal = ? AND id_usuario_contacto = ?',
      whereArgs: [principalId, contactId],
    );

    if (existing.isNotEmpty) {
      final status = existing.first['estado'];

      if (status == 'aceptada') {
        return TrustedContactRequestResult.alreadyLinked;
      }

      if (status == 'pendiente') {
        return TrustedContactRequestResult.alreadyRequested;
      }

      // Si fue rechazada o revocada, permite solicitar nuevamente.
      await db.update(
        'contacto_confianza',
        {
          'codigo_vinculacion': code,
          'estado': 'pendiente',
          'fecha_solicitud': DateTime.now().toIso8601String(),
          'fecha_respuesta': null,
        },
        where: 'id_vinculacion = ?',
        whereArgs: [existing.first['id_vinculacion']],
      );

      return TrustedContactRequestResult.success;
    }

    // Crear la solicitud.
    await db.insert('contacto_confianza', {
      'id_usuario_principal': principalId,
      'id_usuario_contacto': contactId,
      'codigo_vinculacion': code,
      'estado': 'pendiente',
    });

    return TrustedContactRequestResult.success;
  }

  // =========================================
  // SOLICITUDES PENDIENTES
  // =========================================

  static Future<List<Map<String, Object?>>> getPendingRequests(
    int principalId,
  ) async {
    final db = await NaraDatabase.database;

    return db.rawQuery(
      '''
      SELECT
        cc.id_vinculacion,
        cc.id_usuario_principal,
        cc.id_usuario_contacto,
        cc.estado,
        cc.fecha_solicitud,
        u.nombre,
        u.correo
      FROM contacto_confianza cc
      INNER JOIN usuario u
        ON u.id_usuario = cc.id_usuario_contacto
      WHERE cc.id_usuario_principal = ?
        AND cc.estado = 'pendiente'
      ORDER BY cc.fecha_solicitud DESC
    ''',
      [principalId],
    );
  }

  // =========================================
  // ACEPTAR O RECHAZAR
  // =========================================

  static Future<void> respondToRequest({
    required int requestId,
    required int principalId,
    required String status,
  }) async {
    if (status != 'aceptada' && status != 'rechazada') {
      throw ArgumentError('Estado de solicitud no válido.');
    }

    final db = await NaraDatabase.database;

    final result = await db.update(
      'contacto_confianza',
      {'estado': status, 'fecha_respuesta': DateTime.now().toIso8601String()},
      where: '''
        id_vinculacion = ?
        AND id_usuario_principal = ?
        AND estado = 'pendiente'
      ''',
      whereArgs: [requestId, principalId],
    );

    if (result == 0) {
      throw Exception('La solicitud ya no está pendiente.');
    }
  }

  // =========================================
  // CONTACTOS VINCULADOS
  // =========================================

  static Future<List<Map<String, Object?>>> getLinkedContacts(
    int principalId,
  ) async {
    final db = await NaraDatabase.database;

    return db.rawQuery(
      '''
      SELECT
        cc.id_vinculacion,
        cc.id_usuario_contacto,
        cc.puede_recibir_alertas,
        cc.fecha_respuesta,
        u.nombre,
        u.correo
      FROM contacto_confianza cc
      INNER JOIN usuario u
        ON u.id_usuario = cc.id_usuario_contacto
      WHERE cc.id_usuario_principal = ?
        AND cc.estado = 'aceptada'
      ORDER BY u.nombre
    ''',
      [principalId],
    );
  }

  // =========================================
  // USUARIOS PRINCIPALES QUE ACOMPAÑA EL CONTACTO
  // =========================================

  static Future<List<Map<String, Object?>>> getSupportedUsers(
    int contactId,
  ) async {
    final db = await NaraDatabase.database;

    return db.rawQuery(
      '''
      SELECT
        cc.id_vinculacion,
        cc.id_usuario_principal,
        cc.puede_recibir_alertas,
        cc.fecha_respuesta,
        u.nombre,
        u.correo
      FROM contacto_confianza cc
      INNER JOIN usuario u
        ON u.id_usuario = cc.id_usuario_principal
      WHERE cc.id_usuario_contacto = ?
        AND cc.estado = 'aceptada'
      ORDER BY u.nombre
    ''',
      [contactId],
    );
  }

  // =========================================
  // DESVINCULAR PERSONAS
  // =========================================

  static Future<void> revokeLink({
    required int linkId,
    required int userId,
  }) async {
    final db = await NaraDatabase.database;

    final result = await db.update(
      'contacto_confianza',
      {
        'estado': 'revocada',
        'fecha_respuesta': DateTime.now().toIso8601String(),
      },
      where: '''
        id_vinculacion = ?
        AND estado = 'aceptada'
        AND (
          id_usuario_principal = ?
          OR id_usuario_contacto = ?
        )
      ''',
      whereArgs: [linkId, userId, userId],
    );

    if (result == 0) {
      throw Exception('No se pudo encontrar una vinculación activa.');
    }
  }
}
