import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'theme_controller.dart';
//import 'database/nara_database.dart';

import 'models/nara_user.dart';
import 'models/nara_user_session.dart';
import 'services/auth_service.dart';
import 'role_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NaraApp());
}

class NaraApp extends StatelessWidget {
  const NaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NaraPalette>(
      valueListenable: NaraThemeController.current,
      builder: (context, palette, child) {
        return MaterialApp(
          title: 'NARA',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: palette.background,
            colorScheme:
                ColorScheme.fromSeed(
                  seedColor: palette.accent,
                  brightness: Brightness.light,
                ).copyWith(
                  primary: palette.accent,
                  onPrimary: Colors.white,
                  secondary: palette.secondary,
                  onSecondary: palette.text,
                  surface: palette.surface,
                  onSurface: palette.text,
                ),
            appBarTheme: AppBarTheme(
              backgroundColor: palette.accent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              color: palette.surface,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: palette.surface,
              labelStyle: TextStyle(color: palette.mutedText),
              hintStyle: TextStyle(color: palette.mutedText),
              prefixIconColor: palette.accent,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: palette.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: palette.accent, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          home: const SessionGate(),
        );
      },
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = NaraThemeController.current.value;

    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_rounded, size: 90, color: palette.accent),
            const SizedBox(height: 20),
            Text(
              'NARA',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: palette.accent,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tu espacio para sentirte mejor',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 10),
            const Text(
              'Reconoce tus emociones, encuentra apoyo '
              'y cuida de ti un día a la vez.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Comenzar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late Future<NaraUser?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = _restoreSession();
  }

  Future<NaraUser?> _restoreSession() async {
    final idUsuario = await NaraUserSession.getSavedUserId();

    if (idUsuario == null) {
      return null;
    }

    final usuario = await AuthService.obtenerUsuarioPorId(idUsuario);

    if (usuario != null) {
      await NaraUserSession.setUser(usuario);
    } else {
      await NaraUserSession.clear();
    }

    return usuario;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NaraUser?>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const WelcomeScreen();
        }

        if (snapshot.data != null) {
          return pantallaSegunRol(snapshot.data!);
        }

        return const WelcomeScreen();
      },
    );
  }
}
