import 'package:material_ui/material_ui.dart';

import 'models/nara_user.dart';
import 'screens/home_screen.dart';
import 'screens/trusted_contact_home_screen.dart';
import 'screens/professional_home_screen.dart';

Widget pantallaSegunRol(NaraUser usuario) {
  switch (usuario.tipo) {
    case NaraUserType.usuarioPrincipal:
      return const HomeScreen();

    case NaraUserType.contactoConfianza:
      return const TrustedContactHomeScreen();

    case NaraUserType.profesional:
      return const ProfessionalHomeScreen();
  }
}
