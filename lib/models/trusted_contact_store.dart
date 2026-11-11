
import 'package:flutter/foundation.dart';

import 'trusted_contact.dart';

enum InvitationCodeResult {
  success,
  invalidCode,
  alreadyRequested,
  alreadyLinked,
}

class TrustedContactStore {
  // Código que el usuario puede compartir.
  static final ValueNotifier<String> invitationCode =
      ValueNotifier<String>(TrustedContactCode.generate());

  // Contactos vinculados.
  static final ValueNotifier<List<TrustedContact>> contacts =
      ValueNotifier<List<TrustedContact>>([]);

  // Solicitudes recibidas.
  static final ValueNotifier<List<ContactRequest>> requests =
      ValueNotifier<List<ContactRequest>>([]);

  // Generar un nuevo código.
  static void renewCode() {
    invitationCode.value = TrustedContactCode.generate();
  }

  // Simular una solicitud recibida para probar la aplicación.
  static void addDemoRequest({
    required String nombre,
    required String correo,
  }) {
    final alreadyExists = requests.value.any(
      (request) => request.correo == correo,
    );

    final alreadyContact = contacts.value.any(
      (contact) => contact.correo == correo,
    );

    if (alreadyExists || alreadyContact) return;

    final newRequest = ContactRequest(
      nombre: nombre,
      correo: correo,
    );

    requests.value = [...requests.value, newRequest];
  }

  // Aceptar o rechazar una solicitud.
  static void respondToRequest(
    ContactRequest request,
    ContactRequestStatus status,
  ) {
    final updatedRequest = request.copyWith(estado: status);

    requests.value = requests.value.map((item) {
      return item.correo == request.correo ? updatedRequest : item;
    }).toList();

    if (status == ContactRequestStatus.aceptada) {
      final alreadyExists = contacts.value.any(
        (contact) => contact.correo == request.correo,
      );

      if (!alreadyExists) {
        contacts.value = [
          ...contacts.value,
          TrustedContact(
            nombre: request.nombre,
            correo: request.correo,
          ),
        ];
      }
    }
  }
    // Enviar solicitud usando un código de invitación.
  static InvitationCodeResult requestByCode({
    required String code,
    required String nombre,
    required String correo,
  }) {
    // Comprobar que el código sea correcto.
    if (code != invitationCode.value) {
      return InvitationCodeResult.invalidCode;
    }

    // Evitar solicitudes duplicadas.
    final alreadyRequested = requests.value.any(
      (request) => request.correo == correo,
    );

    if (alreadyRequested) {
      return InvitationCodeResult.alreadyRequested;
    }

    // Evitar vincular dos veces al mismo contacto.
    final alreadyLinked = contacts.value.any(
      (contact) => contact.correo == correo,
    );

    if (alreadyLinked) {
      return InvitationCodeResult.alreadyLinked;
    }

    // Crear una solicitud pendiente.
    requests.value = [
      ...requests.value,
      ContactRequest(
        nombre: nombre,
        correo: correo,
      ),
    ];

    return InvitationCodeResult.success;
  }
}
