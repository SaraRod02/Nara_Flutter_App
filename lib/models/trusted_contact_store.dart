
import 'package:flutter/foundation.dart';

import 'nara_user.dart';
import 'nara_user_session.dart';
import 'trusted_contact.dart';
import '../services/trusted_contact_service.dart';

enum InvitationCodeResult {
  success,
  invalidCode,
  alreadyRequested,
  alreadyLinked,
}

class TrustedContactStore {
  static final ValueNotifier<String> invitationCode =
      ValueNotifier<String>('------');

  static final ValueNotifier<List<TrustedContact>> contacts =
      ValueNotifier<List<TrustedContact>>([]);

  static final ValueNotifier<List<ContactRequest>> requests =
      ValueNotifier<List<ContactRequest>>([]);

  // Cargar o recuperar el código del usuario principal.
  static Future<void> loadCode() async {
    final user = NaraUserSession.currentUser.value;

    if (user == null ||
        user.tipo != NaraUserType.usuarioPrincipal ||
        user.idUsuario == null) {
      return;
    }

    invitationCode.value =
        await TrustedContactService.getOrCreateCode(user.idUsuario!);
  }

  // Generar un nuevo código y guardarlo en SQLite.
  static Future<void> renewCode() async {
    final user = NaraUserSession.currentUser.value;

    if (user == null ||
        user.tipo != NaraUserType.usuarioPrincipal ||
        user.idUsuario == null) {
      return;
    }

    invitationCode.value =
        await TrustedContactService.renewCode(user.idUsuario!);
  }

  // Función temporal de demostración.
  // La retiraremos cuando conectemos las solicitudes reales.
  static void addDemoRequest({
    required String nombre,
    required String correo,
  }) {
    final alreadyExists =
        requests.value.any((r) => r.correo == correo);
    final alreadyContact =
        contacts.value.any((c) => c.correo == correo);

    if (alreadyExists || alreadyContact) return;

    requests.value = [
      ...requests.value,
      ContactRequest(nombre: nombre, correo: correo),
    ];
  }

  // Función temporal de demostración.
  static void respondToRequest(
    ContactRequest request,
    ContactRequestStatus status,
  ) {
    final updatedRequest = request.copyWith(estado: status);

    requests.value = requests.value.map((item) {
      return item.correo == request.correo
          ? updatedRequest
          : item;
    }).toList();

    if (status == ContactRequestStatus.aceptada) {
      final alreadyExists =
          contacts.value.any((c) => c.correo == request.correo);

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

  static Future<InvitationCodeResult> requestByCode({
    required String code,
    required String nombre,
    required String correo,
  }) async {
    final user = NaraUserSession.currentUser.value;

    if (user == null ||
        user.tipo != NaraUserType.contactoConfianza ||
        user.idUsuario == null) {
      return InvitationCodeResult.invalidCode;
    }

    final result = await TrustedContactService.requestByCode(
      code: code,
      contactId: user.idUsuario!,
    );

    switch (result) {
      case TrustedContactRequestResult.success:
        return InvitationCodeResult.success;
      case TrustedContactRequestResult.invalidCode:
      case TrustedContactRequestResult.selfRequest:
      case TrustedContactRequestResult.wrongRole:
        return InvitationCodeResult.invalidCode;
      case TrustedContactRequestResult.alreadyRequested:
        return InvitationCodeResult.alreadyRequested;
      case TrustedContactRequestResult.alreadyLinked:
        return InvitationCodeResult.alreadyLinked;
    }
  }

}
