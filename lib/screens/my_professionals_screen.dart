import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../services/professional_link_service.dart';
import '../theme_controller.dart';

class MyProfessionalsScreen extends StatefulWidget {
  final int patientId;
  final NaraPalette palette;

  const MyProfessionalsScreen({
    super.key,
    required this.patientId,
    required this.palette,
  });

  @override
  State<MyProfessionalsScreen> createState() => _MyProfessionalsScreenState();
}

class _MyProfessionalsScreenState extends State<MyProfessionalsScreen> {
  final Map<String, String?> _codes = {'psicologo': null, 'psiquiatra': null};

  final Map<String, String?> _expirations = {
    'psicologo': null,
    'psiquiatra': null,
  };

  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _linkedProfessionals = [];

  bool _loading = true;
  String? _error;
  String? _processing;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      for (final type in ['psicologo', 'psiquiatra']) {
        final code = await ProfessionalLinkService.getOrCreateCode(
          widget.patientId,
          type,
        );

        final expiration = await ProfessionalLinkService.getCodeExpiration(
          widget.patientId,
          type,
        );

        _codes[type] = code;
        _expirations[type] = expiration;
      }

      final requests = await ProfessionalLinkService.getPendingRequests(
        widget.patientId,
      );

      final linkedProfessionals = <Map<String, dynamic>>[];

      for (final type in ['psicologo', 'psiquiatra']) {
        final professional =
            await ProfessionalLinkService.getLinkedProfessional(
              widget.patientId,
              type,
            );

        if (professional != null) {
          linkedProfessionals.add(professional);
        }
      }

      if (!mounted) return;

      setState(() {
        _requests = requests;
        _loading = false;
        _error = null;
        _linkedProfessionals = linkedProfessionals;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _professionalName(String type) {
    return type == 'psiquiatra' ? 'Psiquiatra' : 'Psicólogo/a';
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Fecha no disponible';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return 'Fecha no disponible';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Código copiado')));
  }

  Future<void> _renewCode(String type) async {
    try {
      final code = await ProfessionalLinkService.renewCode(
        widget.patientId,
        type,
      );

      final expiration = await ProfessionalLinkService.getCodeExpiration(
        widget.patientId,
        type,
      );

      if (!mounted) return;

      setState(() {
        _codes[type] = code;
        _expirations[type] = expiration;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nuevo código para ${_professionalName(type)}')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo renovar el código: $e')),
      );
    }
  }

  Future<void> _respondToRequest(
    Map<String, dynamic> request,
    bool accept,
  ) async {
    final requestId = request['id_solicitud'] as int;
    final key = requestId.toString();

    setState(() {
      _processing = key;
    });

    try {
      final result = await ProfessionalLinkService.respondToRequest(
        requestId: requestId,
        patientId: widget.patientId,
        accept: accept,
      );

      if (!mounted) return;

      String message;

      switch (result) {
        case ProfessionalLinkResult.success:
          message = accept
              ? 'Especialista vinculado correctamente.'
              : 'Solicitud rechazada.';
          break;
        case ProfessionalLinkResult.alreadyLinked:
          message = 'Ya existe una vinculación con este especialista.';
          break;
        case ProfessionalLinkResult.alreadyHasProfessionalOfType:
          message = 'Ya tienes un profesional vinculado de este tipo.';
          break;
        default:
          message = 'No se pudo procesar la solicitud.';
      }

      setState(() {
        _processing = null;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _processing = null;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ocurrió un error: $e')));
    }
  }

  Widget _buildCodeCard(String type, NaraPalette palette) {
    final code = _codes[type];
    final expiration = _expirations[type];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
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
              Icon(Icons.medical_services_outlined, color: palette.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _professionalName(type),
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
          Text(
            'Comparte este código con tu especialista:',
            style: TextStyle(color: palette.text),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: palette.iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              code ?? '------',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                letterSpacing: 7,
                fontWeight: FontWeight.bold,
                color: palette.accent,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Vence: ${expiration == null ? 'No disponible' : _formatDate(expiration)}',
            style: TextStyle(color: palette.mutedText),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: code == null ? null : () => _copyCode(code),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.accent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _renewCode(type),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Renovar'),
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
  }

  Widget _buildRequestCard(Map<String, dynamic> request, NaraPalette palette) {
    final requestId = request['id_solicitud'] as int;
    final key = requestId.toString();
    final type = request['tipo_profesional']?.toString() ?? 'psicologo';
    final isProcessing = _processing == key;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request['nombre']?.toString() ?? 'Especialista',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: palette.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            request['especialidad']?.toString() ?? _professionalName(type),
            style: TextStyle(color: palette.text),
          ),
          const SizedBox(height: 5),
          Text(
            'Tipo: ${_professionalName(type)}',
            style: TextStyle(color: palette.text),
          ),
          const SizedBox(height: 5),
          Text(
            'Cédula: ${request['cedula_profesional'] ?? 'No disponible'}',
            style: TextStyle(color: palette.text),
          ),
          const SizedBox(height: 5),
          Text(
            'Solicitud: ${_formatDate(request['fecha_solicitud'])}',
            style: TextStyle(color: palette.mutedText),
          ),
          const SizedBox(height: 16),
          if (isProcessing)
            Center(child: CircularProgressIndicator(color: palette.accent))
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respondToRequest(request, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.text,
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respondToRequest(request, true),
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
    );
  }

  Widget _buildLinkedProfessionalCard(
    Map<String, dynamic> professional,
    NaraPalette palette,
  ) {
    final type = professional['tipo_profesional']?.toString() ?? 'psicologo';

    Widget detail(String label, dynamic value) {
      final text = value?.toString().trim() ?? '';

      if (text.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text('$label: $text', style: TextStyle(color: palette.text)),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
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
              Icon(Icons.verified_user_outlined, color: palette.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _professionalName(type),
                  style: TextStyle(
                    color: palette.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            professional['nombre']?.toString() ?? 'Especialista',
            style: TextStyle(
              color: palette.text,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          detail('Especialidad', professional['especialidad']),
          detail('Correo', professional['correo']),
          detail('Teléfono', professional['telefono']),
          detail('Cédula profesional', professional['cedula_profesional']),
          detail('Vinculado desde', _formatDate(professional['fecha_inicio'])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.palette.background,
      appBar: AppBar(
        title: Text(
          'Mis especialistas',
          style: TextStyle(
            color: widget.palette.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: widget.palette.surface,
        foregroundColor: widget.palette.text,
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: widget.palette.accent),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No se pudo cargar la información.',
                      style: TextStyle(
                        color: widget.palette.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: widget.palette.mutedText),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _loading = true;
                          _error = null;
                        });
                        _loadData();
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: widget.palette.accent,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Especialistas vinculados',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: widget.palette.accent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_linkedProfessionals.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: widget.palette.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: widget.palette.border),
                      ),
                      child: Text(
                        'Todavía no tienes especialistas vinculados. '
                        'Cuando aceptes una solicitud, aparecerán aquí.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.palette.text,
                          height: 1.5,
                        ),
                      ),
                    )
                  else
                    ..._linkedProfessionals.map(
                      (professional) => _buildLinkedProfessionalCard(
                        professional,
                        widget.palette,
                      ),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    'Vincula a tus especialistas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: widget.palette.accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Comparte el código correspondiente con tu '
                    'psicólogo/a o psiquiatra para que pueda '
                    'enviarte una solicitud de vinculación.',
                    style: TextStyle(color: widget.palette.text, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  _buildCodeCard('psicologo', widget.palette),
                  _buildCodeCard('psiquiatra', widget.palette),
                  const SizedBox(height: 18),
                  Text(
                    'Solicitudes recibidas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: widget.palette.accent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_requests.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: widget.palette.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: widget.palette.border),
                      ),
                      child: Text(
                        'Todavía no tienes solicitudes pendientes. '
                        'Cuando un especialista utilice tu código, '
                        'podrás revisar su solicitud aquí.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.palette.text,
                          height: 1.5,
                        ),
                      ),
                    )
                  else
                    ..._requests.map(
                      (request) => _buildRequestCard(request, widget.palette),
                    ),
                ],
              ),
            ),
    );
  }
}
