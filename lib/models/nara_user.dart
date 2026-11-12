
enum NaraUserType {
  usuarioPrincipal,
  contactoConfianza,
  profesional,
}

class NaraUser {
  final int? idUsuario;
  final String nombre;
  final String correo;
  final NaraUserType tipo;

  NaraUser({
    this.idUsuario,
    required this.nombre,
    required this.correo,
    required this.tipo,
  });

  NaraUser copyWith({
    int? idUsuario,
    String? nombre,
    String? correo,
    NaraUserType? tipo,
  }) {
    return NaraUser(
      idUsuario: idUsuario ?? this.idUsuario,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      tipo: tipo ?? this.tipo,
    );
  }

  String get tipoDescripcion {
    switch (tipo) {
      case NaraUserType.usuarioPrincipal:
        return 'Usuario principal';
      case NaraUserType.contactoConfianza:
        return 'Contacto de confianza';
      case NaraUserType.profesional:
        return 'Profesional de apoyo';
    }
  }
}
