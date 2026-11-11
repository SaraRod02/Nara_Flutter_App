import 'package:flutter/material.dart';

import '../theme_controller.dart';
import '../models/nara_user.dart';
import '../models/nara_user_session.dart';

import 'emotion_screen.dart';
import 'settings_screen.dart';
import 'trusted_contacts_screen.dart';
import 'symptom_screen.dart';
import 'trends_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'NARA',
    'Mi seguimiento',
    'Mi diario',
    'Mi perfil',
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NaraPalette>(
      valueListenable: NaraThemeController.current,
      builder: (context, palette, child) {
        return Scaffold(
          backgroundColor: palette.background,

          appBar: AppBar(
            backgroundColor: palette.surface,
            foregroundColor: palette.text,
            title: Text(
              _titles[_selectedIndex],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: palette.accent,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout),
                onPressed: () {
                  NaraUserSession.clear();

                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
              ),
            ],
          ),

          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _HomeTab(
                palette: palette,
                onSelectTab: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
              _TrackingTab(palette: palette),
              _DiaryTab(palette: palette),
              _ProfileTab(palette: palette),
            ],
          ),

          bottomNavigationBar: NavigationBar(
            backgroundColor: palette.surface,
            indicatorColor: palette.iconBackground,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_outline),
                selectedIcon: Icon(Icons.favorite),
                label: 'Seguimiento',
              ),
              NavigationDestination(
                icon: Icon(Icons.book_outlined),
                selectedIcon: Icon(Icons.book),
                label: 'Diario',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        );
      },
    );
  }
}

// --------------------------------------------------
// PANTALLA DE INICIO
// --------------------------------------------------

class _HomeTab extends StatelessWidget {
  final NaraPalette palette;
  final ValueChanged<int> onSelectTab;

  const _HomeTab({required this.palette, required this.onSelectTab});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),

          Text(
            'Hola, qué gusto tenerte aquí',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: palette.accent,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Este es tu espacio. Ve a tu ritmo y date permiso de sentir.',
            style: TextStyle(fontSize: 15, height: 1.5, color: palette.text),
          ),

          const SizedBox(height: 28),

          // TARJETA DE LUMI
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: palette.secondary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text('☁️', style: TextStyle(fontSize: 62)),

                const SizedBox(height: 10),

                Text(
                  '¡Hola! Soy LUMI',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: palette.accent,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Estoy aquí para acompañarte mientras aprendes '
                  'a escuchar tus emociones.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.text, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'Tus herramientas',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: palette.text,
            ),
          ),

          const SizedBox(height: 12),

          _HomeOption(
            palette: palette,
            icon: Icons.favorite_outline,
            title: '¿Cómo me siento?',
            description: 'Registra tu estado emocional.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmotionScreen()),
              );
            },
          ),

          const SizedBox(height: 12),

          _HomeOption(
            palette: palette,
            icon: Icons.calendar_month_outlined,
            title: 'Mi historial',
            description: 'Consulta tus registros emocionales.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmotionHistoryScreen()),
              );
            },
          ),

          const SizedBox(height: 12),

          _HomeOption(
            palette: palette,
            icon: Icons.book_outlined,
            title: 'Mi diario emocional',
            description: 'Un espacio para escribir lo que sientes.',
            onTap: () => onSelectTab(2),
          ),

          const SizedBox(height: 12),

          _HomeOption(
            palette: palette,
            icon: Icons.person_outline,
            title: 'Mi perfil',
            description: 'Consulta tus datos y preferencias.',
            onTap: () => onSelectTab(3),
          ),

          const SizedBox(height: 12),

          _HomeOption(
            palette: palette,
            icon: Icons.people_alt_outlined,
            title: 'Mi red de apoyo',
            description: 'Conecta con personas de confianza.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrustedContactsScreen(palette: palette),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// PANTALLA DE SEGUIMIENTO
// --------------------------------------------------

class _TrackingTab extends StatelessWidget {
  final NaraPalette palette;

  const _TrackingTab({required this.palette});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mi bienestar emocional',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: palette.accent,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Conoce tus emociones y registra cómo te encuentras.',
            style: TextStyle(color: palette.text, height: 1.5),
          ),

          const SizedBox(height: 24),

          _HomeOption(
            palette: palette,
            icon: Icons.favorite_outline,
            title: 'Registrar estado emocional',
            description: 'Selecciona una emoción y su intensidad.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmotionScreen()),
              );
            },
          ),

          const SizedBox(height: 12),

          _HomeOption(
            palette: palette,
            icon: Icons.monitor_heart_outlined,
            title: 'Registrar síntomas',
            description: 'Identifica los síntomas físicos o emocionales.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SymptomScreen(palette: palette),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          _HomeOption(
            palette: palette,
            icon: Icons.calendar_month_outlined,
            title: 'Historial emocional',
            description: 'Consulta tus registros anteriores.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmotionHistoryScreen()),
              );
            },
          ),

          const SizedBox(height: 12),

          _HomeOption(
            palette: palette,
            icon: Icons.insights_outlined,
            title: 'Mis tendencias',
            description: 'Conoce tus patrones y evolución emocional.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrendsScreen(palette: palette),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// PANTALLA DEL DIARIO
// --------------------------------------------------

class _DiaryTab extends StatelessWidget {
  final NaraPalette palette;

  const _DiaryTab({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 75, color: palette.accent),

            const SizedBox(height: 20),

            Text(
              'Mi diario emocional',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: palette.accent,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Este será un espacio privado para escribir '
              'tus pensamientos, experiencias y emociones.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.text, height: 1.5),
            ),

            const SizedBox(height: 18),

            _ComingSoonLabel(palette: palette),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------
// PANTALLA DE PERFIL
// --------------------------------------------------

class _ProfileTab extends StatelessWidget {
  final NaraPalette palette;

  const _ProfileTab({required this.palette});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NaraUser?>(
      valueListenable: NaraUserSession.currentUser,
      builder: (context, user, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Mi espacio personal',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: palette.accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Administra tu información y las preferencias de NARA.',
                style: TextStyle(color: palette.text, height: 1.5),
              ),
              const SizedBox(height: 24),

              if (user != null) ...[
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: palette.iconBackground,
                        child: Text(
                          user.nombre.isNotEmpty
                              ? user.nombre[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: palette.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user.nombre,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        user.correo,
                        style: TextStyle(color: palette.mutedText),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: palette.iconBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.tipoDescripcion,
                          style: TextStyle(
                            color: palette.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                _HomeOption(
                  palette: palette,
                  icon: Icons.edit_outlined,
                  title: 'Editar mis datos',
                  description: 'Actualiza tu nombre y correo electrónico.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EditProfileScreen(user: user, palette: palette),
                      ),
                    );
                  },
                ),
              ] else ...[
                Card(
                  color: palette.surface,
                  child: const Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'No hay información de usuario disponible. '
                      'Inicia sesión o crea una cuenta para consultar tu perfil.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              _HomeOption(
                palette: palette,
                icon: Icons.palette_outlined,
                title: 'Personalizar NARA',
                description: 'Elige los colores de tu aplicación.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),

              const SizedBox(height: 12),

              _ComingSoonOption(
                palette: palette,
                icon: Icons.lock_outline,
                title: 'Privacidad y permisos',
                description: 'Administra el acceso a tu información.',
              ),

              const SizedBox(height: 12),

              _ComingSoonOption(
                palette: palette,
                icon: Icons.notifications_outlined,
                title: 'Recordatorios',
                description: 'Configura tus notificaciones.',
              ),
            ],
          ),
        );
      },
    );
  }
}

// --------------------------------------------------
// EDITAR DATOS PERSONALES
// --------------------------------------------------

class EditProfileScreen extends StatefulWidget {
  final NaraUser user;
  final NaraPalette palette;

  const EditProfileScreen({
    super.key,
    required this.user,
    required this.palette,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreController;
  late final TextEditingController _correoController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.user.nombre);
    _correoController = TextEditingController(text: widget.user.correo);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  void _guardarCambios() {
    if (_formKey.currentState!.validate()) {
      final usuarioActualizado = widget.user.copyWith(
        nombre: _nombreController.text.trim(),
        correo: _correoController.text.trim(),
      );

      NaraUserSession.updateUser(usuarioActualizado);

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Editar perfil'),
        backgroundColor: palette.surface,
        foregroundColor: palette.text,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Actualiza tu información',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: palette.accent,
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nombreController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Escribe tu nombre.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())) {
                    return 'Ingresa un correo válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tipo de cuenta',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  widget.user.tipoDescripcion,
                  style: TextStyle(color: palette.text),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _guardarCambios,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Guardar cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// TARJETA REUTILIZABLE
// --------------------------------------------------

class _HomeOption extends StatelessWidget {
  final NaraPalette palette;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _HomeOption({
    required this.palette,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: palette.surface,
      elevation: 1,
      shadowColor: palette.border,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: palette.iconBackground,
          child: Icon(icon, color: palette.accent),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: palette.text),
        ),
        subtitle: Text(description, style: TextStyle(color: palette.mutedText)),
        trailing: Icon(Icons.chevron_right, color: palette.accent),
        onTap: onTap,
      ),
    );
  }
}

// --------------------------------------------------
// OPCIONES QUE AÚN NO ESTÁN IMPLEMENTADAS
// --------------------------------------------------

class _ComingSoonOption extends StatelessWidget {
  final NaraPalette palette;
  final IconData icon;
  final String title;
  final String description;

  const _ComingSoonOption({
    required this.palette,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: palette.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: palette.iconBackground,
          child: Icon(icon, color: palette.accent),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: palette.text),
        ),
        subtitle: Text(description, style: TextStyle(color: palette.mutedText)),
        trailing: Text(
          'Próximamente',
          style: TextStyle(fontSize: 11, color: palette.mutedText),
        ),
      ),
    );
  }
}

class _ComingSoonLabel extends StatelessWidget {
  final NaraPalette palette;

  const _ComingSoonLabel({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: palette.iconBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Próximamente',
        style: TextStyle(color: palette.accent, fontWeight: FontWeight.bold),
      ),
    );
  }
}
