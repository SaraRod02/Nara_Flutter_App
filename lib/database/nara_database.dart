import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class NaraDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final db = await _initializeDatabase();
    _database = db;
    return db;
  }

  static Future<Database> _initializeDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = join(directory.path, 'nara.db');

    // Copiar la base original si todavía no existe.
    if (!await File(dbPath).exists()) {
      final data = await rootBundle.load('assets/database/nara.db');

      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      await File(dbPath).writeAsBytes(bytes, flush: true);

      // Identificar el archivo original como versión 1.
      final seedDb = await openDatabase(dbPath, version: 1);
      await seedDb.close();
    }

    return await openDatabase(
      dbPath,
      version: 10,

      // Desactivar temporalmente las llaves foráneas
      // durante la reconstrucción de las tablas.
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = OFF');
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        // ==========================================
        // MIGRACIÓN 1 -> 2
        // ==========================================

        if (oldVersion < 2) {
          // 1. Actualizar la tabla de usuarios.
          await db.execute('''
            CREATE TABLE usuario_nuevo (
              id_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
              nombre TEXT NOT NULL,
              correo TEXT NOT NULL COLLATE NOCASE UNIQUE,
              contraseña_hash TEXT NOT NULL,
              fecha_nacimiento TEXT,
              rol TEXT NOT NULL
                CHECK (rol IN (
                  'paciente',
                  'psicologo',
                  'administrador',
                  'contacto_confianza'
                )),
              estado_cuenta TEXT NOT NULL DEFAULT 'activa'
                CHECK (estado_cuenta IN (
                  'activa',
                  'suspendida',
                  'eliminada'
                ))
            )
          ''');

          await db.execute('''
            INSERT INTO usuario_nuevo
            SELECT * FROM usuario
          ''');

          await db.execute('DROP TABLE usuario');

          await db.execute('''
            ALTER TABLE usuario_nuevo RENAME TO usuario
          ''');

          // 2. Permitir que el psicólogo sea opcional.
          await db.execute('''
            CREATE TABLE paciente_nuevo (
              id_relacion INTEGER PRIMARY KEY AUTOINCREMENT,
              id_usuario_paciente INTEGER NOT NULL,
              id_psicologo INTEGER,
              fecha_inicio TEXT NOT NULL DEFAULT CURRENT_DATE,
              fecha_fin TEXT,
              FOREIGN KEY (id_usuario_paciente)
                REFERENCES usuario(id_usuario),
              FOREIGN KEY (id_psicologo)
                REFERENCES psicologo(id_psicologo),
              CHECK (
                fecha_fin IS NULL OR fecha_fin >= fecha_inicio
              )
            )
          ''');

          await db.execute('''
            INSERT INTO paciente_nuevo (
              id_relacion,
              id_usuario_paciente,
              id_psicologo,
              fecha_inicio,
              fecha_fin
            )
            SELECT
              id_relacion,
              id_usuario_paciente,
              id_psicologo,
              fecha_inicio,
              fecha_fin
            FROM paciente
          ''');

          await db.execute('DROP TABLE paciente');

          await db.execute('''
            ALTER TABLE paciente_nuevo RENAME TO paciente
          ''');

          // 3. Crear las relaciones de contactos de confianza.
          await db.execute('''
            CREATE TABLE contacto_confianza (
              id_vinculacion INTEGER PRIMARY KEY AUTOINCREMENT,
              id_usuario_principal INTEGER NOT NULL,
              id_usuario_contacto INTEGER NOT NULL,
              codigo_vinculacion TEXT NOT NULL UNIQUE,
              estado TEXT NOT NULL DEFAULT 'pendiente'
                CHECK (estado IN (
                  'pendiente',
                  'aceptada',
                  'rechazada',
                  'revocada'
                )),
              puede_recibir_alertas INTEGER NOT NULL DEFAULT 1
                CHECK (puede_recibir_alertas IN (0, 1)),
              fecha_solicitud TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              fecha_respuesta TEXT,
              FOREIGN KEY (id_usuario_principal)
                REFERENCES usuario(id_usuario),
              FOREIGN KEY (id_usuario_contacto)
                REFERENCES usuario(id_usuario),
              CHECK (
                id_usuario_principal <> id_usuario_contacto
              ),
              UNIQUE (
                id_usuario_principal,
                id_usuario_contacto
              )
            )
          ''');
        }

        // ==========================================
        // MIGRACIÓN 2 -> 3
        // ==========================================

        if (oldVersion < 3) {
          // 1. Reconstruir contacto_confianza.
          // Ahora un mismo código puede utilizarse
          // en varias solicitudes.
          await db.execute('''
            CREATE TABLE contacto_confianza_nueva (
              id_vinculacion INTEGER PRIMARY KEY AUTOINCREMENT,
              id_usuario_principal INTEGER NOT NULL,
              id_usuario_contacto INTEGER NOT NULL,
              codigo_vinculacion TEXT NOT NULL,
              estado TEXT NOT NULL DEFAULT 'pendiente'
                CHECK (estado IN (
                  'pendiente',
                  'aceptada',
                  'rechazada',
                  'revocada'
                )),
              puede_recibir_alertas INTEGER NOT NULL DEFAULT 1
                CHECK (puede_recibir_alertas IN (0, 1)),
              fecha_solicitud TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              fecha_respuesta TEXT,
              FOREIGN KEY (id_usuario_principal)
                REFERENCES usuario(id_usuario),
              FOREIGN KEY (id_usuario_contacto)
                REFERENCES usuario(id_usuario),
              CHECK (
                id_usuario_principal <> id_usuario_contacto
              ),
              UNIQUE (
                id_usuario_principal,
                id_usuario_contacto
              )
            )
          ''');

          await db.execute('''
            INSERT INTO contacto_confianza_nueva
            SELECT * FROM contacto_confianza
          ''');

          await db.execute('DROP TABLE contacto_confianza');

          await db.execute('''
            ALTER TABLE contacto_confianza_nueva
            RENAME TO contacto_confianza
          ''');

          // 2. Crear la tabla independiente de códigos.
          await db.execute('''
            CREATE TABLE IF NOT EXISTS codigo_invitacion (
              id_codigo INTEGER PRIMARY KEY AUTOINCREMENT,
              id_usuario_principal INTEGER NOT NULL UNIQUE,
              codigo TEXT NOT NULL UNIQUE,
              fecha_creacion TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              FOREIGN KEY (id_usuario_principal)
                REFERENCES usuario(id_usuario)
            )
          ''');
        }

        // ==========================================
        // MIGRACIÓN 3 -> 4
        // ==========================================

        if (oldVersion < 4) {
          // Agregar teléfono al perfil del especialista.
          await db.execute('''
            ALTER TABLE psicologo
            ADD COLUMN telefono TEXT
          ''');
        }

        // ==========================================
        // MIGRACIÓN 4 -> 5
        // ==========================================

        if (oldVersion < 5) {
          await db.execute('''
    ALTER TABLE codigo_invitacion
    ADD COLUMN fecha_expiracion TEXT
  ''');

          // Dar 7 días adicionales a los códigos existentes.
          await db.execute('''
    UPDATE codigo_invitacion
    SET fecha_expiracion = datetime('now', '+7 days')
    WHERE fecha_expiracion IS NULL
  ''');
        }

        // ==========================================
        // MIGRACIÓN 5 -> 6
        // ==========================================

        if (oldVersion < 6) {
          // 1. Código de invitación para psicólogos.
          await db.execute('''
            CREATE TABLE codigo_psicologo (
              id_codigo INTEGER PRIMARY KEY AUTOINCREMENT,
              id_usuario_paciente INTEGER NOT NULL UNIQUE,
              codigo TEXT NOT NULL UNIQUE,
              fecha_creacion TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              fecha_expiracion TEXT NOT NULL,
              FOREIGN KEY (id_usuario_paciente)
                REFERENCES usuario(id_usuario)
            )
          ''');

          // 2. Solicitudes de vinculación profesional.
          await db.execute('''
            CREATE TABLE solicitud_psicologo (
              id_solicitud INTEGER PRIMARY KEY AUTOINCREMENT,
              id_usuario_paciente INTEGER NOT NULL,
              id_psicologo INTEGER NOT NULL,
              codigo_utilizado TEXT NOT NULL,
              estado TEXT NOT NULL DEFAULT 'pendiente'
                CHECK (estado IN (
                  'pendiente',
                  'aceptada',
                  'rechazada'
                )),
              fecha_solicitud TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              fecha_respuesta TEXT,
              FOREIGN KEY (id_usuario_paciente)
                REFERENCES usuario(id_usuario),
              FOREIGN KEY (id_psicologo)
                REFERENCES psicologo(id_psicologo),
              CHECK (
                id_usuario_paciente <> id_psicologo
              )
            )
          ''');

          // 3. Índices para consultar solicitudes.
          await db.execute('''
            CREATE INDEX idx_solicitud_psicologo
            ON solicitud_psicologo (id_psicologo, estado)
          ''');

          await db.execute('''
            CREATE INDEX idx_solicitud_paciente
            ON solicitud_psicologo (id_usuario_paciente, estado)
          ''');
        }

        // ==========================================
        // MIGRACIÓN 6 -> 7
        // ==========================================

        if (oldVersion < 7) {
          // 1. Identificar el tipo de profesional.
          // Los registros anteriores serán psicólogos.
          await db.execute('''
            ALTER TABLE psicologo
            ADD COLUMN tipo_profesional TEXT NOT NULL
            DEFAULT 'psicologo'
            CHECK (
              tipo_profesional IN ('psicologo', 'psiquiatra')
            )
          ''');

          // 2. Reconstruir los códigos profesionales.
          // Ahora cada paciente tendrá un código
          // independiente para cada tipo profesional.
          await db.execute('''
            CREATE TABLE codigo_psicologo_nuevo (
              id_codigo INTEGER PRIMARY KEY AUTOINCREMENT,
              id_usuario_paciente INTEGER NOT NULL,
              codigo TEXT NOT NULL UNIQUE,
              tipo_profesional TEXT NOT NULL
                CHECK (
                  tipo_profesional IN ('psicologo', 'psiquiatra')
                ),
              fecha_creacion TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              fecha_expiracion TEXT NOT NULL,
              FOREIGN KEY (id_usuario_paciente)
                REFERENCES usuario(id_usuario),
              UNIQUE (id_usuario_paciente, tipo_profesional)
            )
          ''');

          await db.execute('''
            INSERT INTO codigo_psicologo_nuevo (
              id_codigo,
              id_usuario_paciente,
              codigo,
              tipo_profesional,
              fecha_creacion,
              fecha_expiracion
            )
            SELECT
              id_codigo,
              id_usuario_paciente,
              codigo,
              'psicologo',
              fecha_creacion,
              fecha_expiracion
            FROM codigo_psicologo
          ''');

          await db.execute('DROP TABLE codigo_psicologo');

          await db.execute('''
            ALTER TABLE codigo_psicologo_nuevo
            RENAME TO codigo_psicologo
          ''');
        }

        // ==========================================
        // MIGRACIÓN 7 -> 8
        // ==========================================

        if (oldVersion < 8) {
          // 1. Crear los registros principales de síntomas.
          await db.execute('''
            CREATE TABLE registro_sintomas (
              id_registro_sintomas INTEGER PRIMARY KEY AUTOINCREMENT,
              id_usuario INTEGER NOT NULL,
              comentario TEXT,
              fecha_registro TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              FOREIGN KEY (id_usuario)
                REFERENCES usuario(id_usuario)
            )
          ''');

          // 2. Crear el detalle de cada síntoma registrado.
          await db.execute('''
            CREATE TABLE detalle_sintoma (
              id_detalle INTEGER PRIMARY KEY AUTOINCREMENT,
              id_registro_sintomas INTEGER NOT NULL,
              nombre_sintoma TEXT NOT NULL,
              nivel_intensidad INTEGER NOT NULL
                CHECK (nivel_intensidad BETWEEN 1 AND 5),
              FOREIGN KEY (id_registro_sintomas)
                REFERENCES registro_sintomas(id_registro_sintomas)
                ON DELETE CASCADE,
              UNIQUE (id_registro_sintomas, nombre_sintoma)
            )
          ''');

          // 3. Facilitar la consulta del historial por usuario.
          await db.execute('''
            CREATE INDEX idx_registro_sintomas_usuario
            ON registro_sintomas (id_usuario, fecha_registro)
          ''');
        }

        // ==========================================
        // MIGRACIÓN 8 -> 9
        // ==========================================

        if (oldVersion < 9) {
          // Registrar los permisos que cada paciente
          // concede o revoca a sus especialistas.
          await db.execute('''
            CREATE TABLE consentimiento_profesional (
              id_consentimiento INTEGER PRIMARY KEY AUTOINCREMENT,
              id_usuario_paciente INTEGER NOT NULL,
              id_psicologo INTEGER NOT NULL,
              estado TEXT NOT NULL
                CHECK (estado IN ('concedido', 'revocado')),
              fecha_concesion TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              fecha_revocacion TEXT,
              FOREIGN KEY (id_usuario_paciente)
                REFERENCES usuario(id_usuario),
              FOREIGN KEY (id_psicologo)
                REFERENCES psicologo(id_psicologo),
              CHECK (
                id_usuario_paciente <> id_psicologo
              )
            )
          ''');

          // Consultar rápidamente los permisos vigentes.
          await db.execute('''
            CREATE INDEX idx_consentimiento_profesional
            ON consentimiento_profesional (
              id_usuario_paciente,
              id_psicologo,
              estado
            )
          ''');
        }

        // ==========================================
// MIGRACIÓN 9 -> 10
// ==========================================
if (oldVersion < 10) {
  // Tabla para almacenar las alertas emocionales.
  await db.execute('''
    CREATE TABLE alerta_emocional (
      id_alerta INTEGER PRIMARY KEY AUTOINCREMENT,
      id_usuario_paciente INTEGER NOT NULL,
      id_psicologo INTEGER NOT NULL,
      motivo TEXT NOT NULL,
      descripcion TEXT NOT NULL,
      estado TEXT NOT NULL DEFAULT 'pendiente'
        CHECK (estado IN (
          'pendiente',
          'revisada',
          'atendida'
        )),
      fecha_creacion TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (id_usuario_paciente)
        REFERENCES usuario(id_usuario),
      FOREIGN KEY (id_psicologo)
        REFERENCES psicologo(id_psicologo)
    )
  ''');

  // Facilitar la consulta de alertas por especialista.
  await db.execute('''
    CREATE INDEX idx_alerta_emocional_psicologo
    ON alerta_emocional (id_psicologo, estado)
  ''');

  // Facilitar la consulta de alertas por paciente.
  await db.execute('''
    CREATE INDEX idx_alerta_emocional_paciente
    ON alerta_emocional (id_usuario_paciente, fecha_creacion)
  ''');
}

      },

      // Reactivar las llaves foráneas.
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  static Future<List<String>> getTableNames() async {
    final db = await database;

    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' AND name NOT LIKE 'sqlite_%' "
      "ORDER BY name",
    );

    return result.map((row) => row['name'] as String).toList();
  }

  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
