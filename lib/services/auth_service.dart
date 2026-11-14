import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../database/nara_database.dart';
import '../models/nara_user.dart';

class AuthService {
  static final _algorithm = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 310000,
    bits: 256,
  );

  static Future<String> _crearHash(String password) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));

    final secretKey = await _algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    final hash = await secretKey.extractBytes();

    return '${base64Encode(salt)}:${base64Encode(hash)}';
  }

  static Future<bool> _verificarHash(String password, String storedHash) async {
    try {
      final parts = storedHash.split(':');

      if (parts.length != 2) return false;

      final salt = base64Decode(parts[0]);
      final originalHash = base64Decode(parts[1]);

      final secretKey = await _algorithm.deriveKey(
        secretKey: SecretKey(utf8.encode(password)),
        nonce: salt,
      );

      final newHash = await secretKey.extractBytes();

      if (newHash.length != originalHash.length) {
        return false;
      }

      var difference = 0;

      for (var i = 0; i < newHash.length; i++) {
        difference |= newHash[i] ^ originalHash[i];
      }

      return difference == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<NaraUser> registrarUsuario({
    required String nombre,
    required String correo,
    required String password,
    required NaraUserType tipo,
  }) async {
    final db = await NaraDatabase.database;

    final correoNormalizado = correo.trim().toLowerCase();

    final existentes = await db.query(
      'usuario',
      where: 'correo = ?',
      whereArgs: [correoNormalizado],
      limit: 1,
    );

    if (existentes.isNotEmpty) {
      throw Exception('Este correo ya está registrado.');
    }

    final roles = {
      NaraUserType.usuarioPrincipal: 'paciente',
      NaraUserType.contactoConfianza: 'contacto_confianza',
      NaraUserType.profesional: 'psicologo',
    };

    final passwordHash = await _crearHash(password);

    final idUsuario = await db.insert('usuario', {
      'nombre': nombre.trim(),
      'correo': correoNormalizado,
      'contraseña_hash': passwordHash,
      'rol': roles[tipo]!,
    });

    if (tipo == NaraUserType.profesional) {
      await db.insert('psicologo', {'id_psicologo': idUsuario});
    }

    return NaraUser(
      idUsuario: idUsuario,
      nombre: nombre.trim(),
      correo: correoNormalizado,
      tipo: tipo,
    );
  }

  static Future<NaraUser> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    final db = await NaraDatabase.database;

    final resultados = await db.query(
      'usuario',
      where: 'correo = ? AND estado_cuenta = ?',
      whereArgs: [correo.trim().toLowerCase(), 'activa'],
      limit: 1,
    );


    if (resultados.isEmpty) {
      throw Exception('Correo o contraseña incorrectos.');
    }

    final usuario = resultados.first;

    final hashGuardado = usuario['contraseña_hash'] as String;

    final passwordCorrecta = await _verificarHash(password, hashGuardado);


    if (!passwordCorrecta) {
      throw Exception('Correo o contraseña incorrectos.');
    }

    final tipo = switch (usuario['rol']) {
      'paciente' => NaraUserType.usuarioPrincipal,
      'contacto_confianza' => NaraUserType.contactoConfianza,
      'psicologo' => NaraUserType.profesional,
      _ => throw Exception('Tipo de cuenta no permitido.'),
    };

    return NaraUser(
      idUsuario: usuario['id_usuario'] as int,
      nombre: usuario['nombre'] as String,
      correo: usuario['correo'] as String,
      tipo: tipo,
    );
  }

  static Future<NaraUser?> obtenerUsuarioPorId(int idUsuario) async {
    final db = await NaraDatabase.database;

    final resultados = await db.query(
      'usuario',
      where: 'id_usuario = ? AND estado_cuenta = ?',
      whereArgs: [idUsuario, 'activa'],
      limit: 1,
    );

    if (resultados.isEmpty) {
      return null;
    }

    final usuario = resultados.first;

    final tipo = switch (usuario['rol']) {
      'paciente' => NaraUserType.usuarioPrincipal,
      'contacto_confianza' => NaraUserType.contactoConfianza,
      'psicologo' => NaraUserType.profesional,
      _ => null,
    };

    if (tipo == null) {
      return null;
    }

    return NaraUser(
      idUsuario: usuario['id_usuario'] as int,
      nombre: usuario['nombre'] as String,
      correo: usuario['correo'] as String,
      tipo: tipo,
    );
  }

}
