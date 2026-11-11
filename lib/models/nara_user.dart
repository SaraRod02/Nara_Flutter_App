
enum NaraUserType {
  usuarioPrincipal,
  contactoConfianza,
  profesional,
}

class NaraUser {
  final String nombre;
  final String correo;
  final NaraUserType tipo;

  NaraUser({
    required this.nombre,
    required this.correo,
    required this.tipo,
  });

  NaraUser copyWith({
    String? nombre,
    String? correo,
    NaraUserType? tipo,
  }) {
    return NaraUser(
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
