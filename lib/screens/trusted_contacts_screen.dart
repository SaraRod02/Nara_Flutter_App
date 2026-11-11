import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/trusted_contact.dart';
import '../models/trusted_contact_store.dart';
import '../theme_controller.dart';
import 'enter_contact_code_screen.dart';

class TrustedContactsScreen extends StatelessWidget {
  final NaraPalette palette;

  const TrustedContactsScreen({super.key, required this.palette});

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado al portapapeles 💜')),
    );
  }

  void _showDemoRequest(BuildContext context) {
    TrustedContactStore.addDemoRequest(
      nombre: 'Alex',
      correo: 'alex@example.com',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Solicitud de prueba agregada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Mi red de apoyo'),
        backgroundColor: palette.surface,
        foregroundColor: palette.text,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EnterContactCodeScreen(palette: palette),
                  ),
                );
              },
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
              'Conecta con personas de confianza que puedan acompañarte cuando lo necesites, ten la oportunidad de buscar apoyo con las personas que te quieren.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.text, height: 1.5),
            ),
            const SizedBox(height: 28),

            // CÓDIGO DE VINCULACIÓN
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
                              onPressed: () => _copyCode(context, code),
                              icon: const Icon(Icons.copy),
                              label: const Text('Copiar'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: TrustedContactStore.renewCode,
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

            // SOLICITUDES
            _sectionTitle('Solicitudes recibidas'),

            ValueListenableBuilder<List<ContactRequest>>(
              valueListenable: TrustedContactStore.requests,
              builder: (context, requests, child) {
                final pendingRequests = requests
                    .where(
                      (request) =>
                          request.estado == ContactRequestStatus.pendiente,
                    )
                    .toList();

                if (pendingRequests.isEmpty) {
                  return _emptyCard(
                    'No tienes solicitudes pendientes.',
                    Icons.mark_email_read_outlined,
                  );
                }

                return Column(
                  children: pendingRequests.map((request) {
                    return Card(
                      color: palette.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.nombre,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: palette.text,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              request.correo,
                              style: TextStyle(color: palette.mutedText),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      TrustedContactStore.respondToRequest(
                                        request,
                                        ContactRequestStatus.rechazada,
                                      );
                                    },
                                    child: const Text('Rechazar'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      TrustedContactStore.respondToRequest(
                                        request,
                                        ContactRequestStatus.aceptada,
                                      );
                                    },
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
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 28),

            // CONTACTOS VINCULADOS
            _sectionTitle('Mis contactos'),

            ValueListenableBuilder<List<TrustedContact>>(
              valueListenable: TrustedContactStore.contacts,
              builder: (context, contacts, child) {
                if (contacts.isEmpty) {
                  return _emptyCard(
                    'Todavía no tienes contactos vinculados.',
                    Icons.people_outline,
                  );
                }

                return Column(
                  children: contacts.map((contact) {
                    return Card(
                      color: palette.surface,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: palette.iconBackground,
                          child: Icon(Icons.person, color: palette.accent),
                        ),
                        title: Text(
                          contact.nombre,
                          style: TextStyle(color: palette.text),
                        ),
                        subtitle: Text(
                          contact.correo,
                          style: TextStyle(color: palette.mutedText),
                        ),
                        trailing: Icon(
                          Icons.check_circle,
                          color: palette.accent,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 28),

            // BOTÓN TEMPORAL PARA PROBAR
            OutlinedButton.icon(
              onPressed: () => _showDemoRequest(context),
              icon: const Icon(Icons.science_outlined),
              label: const Text('Simular solicitud de prueba'),
            ),

            const SizedBox(height: 8),
            Text(
              'La simulación es únicamente para probar la interfaz.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: palette.mutedText),
            ),
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
