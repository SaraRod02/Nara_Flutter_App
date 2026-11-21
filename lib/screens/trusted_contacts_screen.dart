import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/nara_user_session.dart';
import '../models/trusted_contact_store.dart';
import '../services/trusted_contact_service.dart';
import '../theme_controller.dart';
import 'enter_contact_code_screen.dart';

class TrustedContactsScreen extends StatefulWidget {
  final NaraPalette palette;

  const TrustedContactsScreen({super.key, required this.palette});

  @override
  State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  List<Map<String, Object?>> _pendingRequests = [];
  List<Map<String, Object?>> _linkedContacts = [];

  bool _isLoading = true;
  String? _errorMessage;

  NaraPalette get palette => widget.palette;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = NaraUserSession.currentUser.value;

    if (user?.idUsuario == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No se encontró una sesión activa.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await TrustedContactStore.loadCode();

      final requests = await TrustedContactService.getPendingRequests(
        user!.idUsuario!,
      );

      final contacts = await TrustedContactService.getLinkedContacts(
        user.idUsuario!,
      );

      if (!mounted) return;

      setState(() {
        _pendingRequests = requests;
        _linkedContacts = contacts;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'No se pudo cargar tu red de apoyo.';
      });
    }
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado al portapapeles 💜')),
    );
  }

  Future<void> _renewCode() async {
    try {
      await TrustedContactStore.renewCode();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu código se renovó correctamente.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo renovar el código.')),
      );
    }
  }

  Future<void> _respondToRequest(
    Map<String, Object?> request,
    String status,
  ) async {
    final user = NaraUserSession.currentUser.value;
    final requestId = request['id_vinculacion'] as int?;

    if (user?.idUsuario == null || requestId == null) return;

    try {
      await TrustedContactService.respondToRequest(
        requestId: requestId,
        principalId: user!.idUsuario!,
        status: status,
      );

      await _loadData();

      if (!mounted) return;

      final message = status == 'aceptada'
          ? 'Contacto agregado a tu red de apoyo 💜'
          : 'Solicitud rechazada.';

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo actualizar la solicitud. Inténtalo de nuevo.',
          ),
        ),
      );
    }
  }

  Future<void> _openCodeScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnterContactCodeScreen(palette: palette),
      ),
    );

    if (!mounted) return;
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Mi red de apoyo'),
        backgroundColor: palette.surface,
        foregroundColor: palette.text,
        actions: [
          IconButton(
            onPressed: _loadData,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _openCodeScreen,
              icon: const Icon(Icons.vpn_key_outlined),
              label: const Text('Tengo un código de invitación'),
            ),

            Icon(Icons.people_alt_outlined, size: 65, color: palette.accent),
            const SizedBox(height: 12),

            Text(
              'Puedes con todo, pero no con todo al mismo tiempo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: palette.accent,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'Conecta con personas de confianza que puedan acompañarte '
              'cuando lo necesites. También puedes buscar apoyo en las '
              'personas que te quieren.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.text, height: 1.5),
            ),
            const SizedBox(height: 28),

            _sectionTitle('Tu código de vinculación'),

            ValueListenableBuilder<String>(
              valueListenable: TrustedContactStore.invitationCode,
              builder: (context, code, child) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        code,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                          color: palette.accent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Comparte este código con la persona '
                        'que deseas vincular.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: code == '------'
                                  ? null
                                  : () => _copyCode(code),
                              icon: const Icon(Icons.copy),
                              label: const Text('Copiar'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _renewCode,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Nuevo código'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: palette.accent,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            _sectionTitle('Solicitudes recibidas'),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              _emptyCard(_errorMessage!, Icons.error_outline)
            else if (_pendingRequests.isEmpty)
              _emptyCard(
                'No tienes solicitudes pendientes.',
                Icons.mark_email_read_outlined,
              )
            else
              ..._pendingRequests.map((request) {
                final nombre = request['nombre']?.toString() ?? 'Sin nombre';
                final correo = request['correo']?.toString() ?? '';

                return Card(
                  color: palette.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: palette.text,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          correo,
                          style: TextStyle(color: palette.mutedText),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final confirmar = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) {
                                      return AlertDialog(
                                        title: const Text('¿Estás seguro?'),
                                        content: const Text(
                                          '¿Deseas rechazar esta solicitud de contacto '
                                          'de confianza? Esta persona no quedará vinculada '
                                          'a tu cuenta.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(
                                                dialogContext,
                                                false,
                                              );
                                            },
                                            child: const Text('Cancelar'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(
                                                dialogContext,
                                                true,
                                              );
                                            },
                                            child: const Text('Sí, rechazar'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (confirmar == true && mounted) {
                                    await _respondToRequest(
                                      request,
                                      'rechazada',
                                    );
                                  }
                                },
                                child: const Text('Rechazar'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    _respondToRequest(request, 'aceptada'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: palette.accent,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Aceptar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 28),

            _sectionTitle('Mis contactos'),

            if (_isLoading)
              const SizedBox.shrink()
            else if (_linkedContacts.isEmpty)
              _emptyCard(
                'Todavía no tienes contactos vinculados.',
                Icons.people_outline,
              )
            else
              ..._linkedContacts.map((contact) {
                final nombre = contact['nombre']?.toString() ?? 'Sin nombre';
                final correo = contact['correo']?.toString() ?? '';

                return Card(
                  color: palette.surface,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: palette.iconBackground,
                      child: Icon(Icons.person, color: palette.accent),
                    ),
                    title: Text(nombre, style: TextStyle(color: palette.text)),
                    subtitle: Text(
                      correo,
                      style: TextStyle(color: palette.mutedText),
                    ),
                    trailing: IconButton(
                      tooltip: 'Desvincular contacto',
                      icon: const Icon(Icons.link_off, color: Colors.redAccent),
                      onPressed: () async {
                        final confirmar = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('¿Desvincular contacto?'),
                            content: Text(
                              '¿Deseas dejar de compartir tu red de apoyo con $nombre? '
                              'Esta acción no eliminará ninguna cuenta ni sus registros.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: const Text('Sí, desvincular'),
                              ),
                            ],
                          ),
                        );

                        if (confirmar != true || !mounted) return;

                        final userId =
                            NaraUserSession.currentUser.value?.idUsuario;
                        final linkId = contact['id_vinculacion'] as int?;

                        if (userId == null || linkId == null) return;

                        try {
                          await TrustedContactService.revokeLink(
                            linkId: linkId,
                            userId: userId,
                          );

                          if (!mounted) return;

                          await _loadData();

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Contacto desvinculado correctamente.',
                              ),
                            ),
                          );
                        } catch (error) {
                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No se pudo desvincular el contacto.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              }),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: palette.text,
        ),
      ),
    );
  }

  Widget _emptyCard(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 35, color: palette.mutedText),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.mutedText),
          ),
        ],
      ),
    );
  }
}
