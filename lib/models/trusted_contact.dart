import 'dart:math';

class TrustedContact {
  final String nombre;
  final String correo;

  TrustedContact({
    required this.nombre,
    required this.correo,
  });
}

enum ContactRequestStatus {
  pendiente,
  aceptada,
  rechazada,
}

class ContactRequest {
  final String nombre;
  final String correo;
  final ContactRequestStatus estado;

  ContactRequest({
    required this.nombre,
    required this.correo,
    this.estado = ContactRequestStatus.pendiente,
  });

  ContactRequest copyWith({
    ContactRequestStatus? estado,
  }) {
    return ContactRequest(
      nombre: nombre,
      correo: correo,
      estado: estado ?? this.estado,
    );
  }
}

class TrustedContactCode {
  static String generate() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }
}