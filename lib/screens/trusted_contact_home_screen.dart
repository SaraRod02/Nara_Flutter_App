import 'package:material_ui/material_ui.dart';

import '../models/nara_user_session.dart';
import '../theme_controller.dart';
import 'enter_contact_code_screen.dart';
import '../services/trusted_contact_service.dart';

class TrustedContactHomeScreen extends StatelessWidget {
  const TrustedContactHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NaraPalette>(
      valueListenable: NaraThemeController.current,
      builder: (context, palette, child) {
        final usuario = NaraUserSession.currentUser.value;

        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            title: Text(
              'Mi acompañamiento',
              style: TextStyle(
                color: palette.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: palette.surface,
            foregroundColor: palette.text,
            actions: [
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await NaraUserSession.clear();

                  if (!context.mounted) return;

                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Icon(
                  Icons.volunteer_activism_outlined,
                  size: 70,
                  color: palette.accent,
                ),
                const SizedBox(height: 18),
                Text(
                  '¡Hola${usuario == null ? '' : ', ${usuario.nombre}'}!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Gracias por formar parte de una red de apoyo. '
                  'Tu presencia puede hacer la diferencia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 28),

                // VINCULARSE CON UN USUARIO PRINCIPAL
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EnterContactCodeScreen(palette: palette),
                      ),
                    );
                  },
                  icon: const Icon(Icons.vpn_key_outlined),
                  label: const Text('Vincularme con un código'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                const SizedBox(height: 24),

                _SupportedUsersCard(
                  palette: palette,
                  contactId: usuario?.idUsuario,
                ),
                const SizedBox(height: 14),
                _InfoCard(
                  palette: palette,
                  icon: Icons.notifications_active_outlined,
                  title: 'Avisos y alertas',
                  description:
                      'Aquí recibirás los avisos que cada persona '
                      'haya autorizado compartir contigo.',
                ),
                const SizedBox(height: 14),
                _InfoCard(
                  palette: palette,
                  icon: Icons.favorite_outline,
                  title: '¿Cómo puedo ayudar?',
                  description:
                      'Acompaña con empatía, escucha sin juzgar y '
                      'respeta los tiempos y decisiones de la otra persona.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SupportedUsersCard extends StatefulWidget {
  final NaraPalette palette;
  final int? contactId;

  const _SupportedUsersCard({required this.palette, required this.contactId});

  @override
  State<_SupportedUsersCard> createState() => _SupportedUsersCardState();
}

class _SupportedUsersCardState extends State<_SupportedUsersCard> {
  late Future<List<Map<String, Object?>>> _supportedUsers;

  NaraPalette get palette => widget.palette;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    final id = widget.contactId;

    _supportedUsers = id == null
        ? Future.value([])
        : TrustedContactService.getSupportedUsers(id);
  }

  Future<void> _unlinkUser(Map<String, Object?> persona) async {
    final nombre = persona['nombre']?.toString() ?? 'esta persona';
    final linkId = persona['id_vinculacion'] as int?;
    final contactId = widget.contactId;

    if (linkId == null || contactId == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Dejar de acompañar?'),
        content: Text(
          '¿Deseas desvincularte de $nombre? '
          'No se eliminarán las cuentas ni sus registros.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sí, desvincular'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await TrustedContactService.revokeLink(linkId: linkId, userId: contactId);

      if (!mounted) return;

      setState(_loadUsers);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vinculación finalizada correctamente.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo finalizar la vinculación.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contactId == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<Map<String, Object?>>>(
      future: _supportedUsers,
      builder: (context, snapshot) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people_outline, size: 30, color: palette.accent),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Personas que acompaño',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: palette.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasError)
                Text(
                  'No se pudieron cargar las personas vinculadas.',
                  style: TextStyle(color: palette.text),
                )
              else if (!snapshot.hasData || snapshot.data!.isEmpty)
                Text(
                  'Aquí aparecerán las personas que hayan aceptado '
                  'vincularse contigo.',
                  style: TextStyle(color: palette.text),
                )
              else
                ...snapshot.data!.map((persona) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: palette.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.account_circle_outlined,
                          size: 35,
                          color: palette.accent,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                persona['nombre']?.toString() ?? 'Sin nombre',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: palette.text,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                persona['correo']?.toString() ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: palette.text,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '✓ Vinculación aceptada',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: palette.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () => _unlinkUser(persona),
                                icon: const Icon(
                                  Icons.link_off,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Dejar de acompañar',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final NaraPalette palette;
  final IconData icon;
  final String title;
  final String description;

  const _InfoCard({
    required this.palette,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 30, color: palette.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  description,
                  style: TextStyle(height: 1.4, color: palette.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
