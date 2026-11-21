import 'package:flutter/material.dart';

import '../models/nara_user_session.dart';
import '../database/nara_database.dart';
import '../theme_controller.dart';

class ProfessionalProfileScreen extends StatefulWidget {
  const ProfessionalProfileScreen({super.key});

  @override
  State<ProfessionalProfileScreen> createState() =>
      _ProfessionalProfileScreenState();
}

class _ProfessionalProfileScreenState extends State<ProfessionalProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _especialidadController = TextEditingController();
  final _cedulaController = TextEditingController();

  bool _editando = false;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final usuario = NaraUserSession.currentUser.value;

    if (usuario == null || usuario.idUsuario == null) {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
      return;
    }

    try {
      final db = await NaraDatabase.database;

      final resultado = await db.rawQuery(
        '''
      SELECT
        usuario.nombre,
        usuario.correo,
        psicologo.telefono,
        psicologo.especialidad,
        psicologo.cedula_profesional
      FROM usuario
      INNER JOIN psicologo
        ON psicologo.id_psicologo = usuario.id_usuario
      WHERE usuario.id_usuario = ?
      LIMIT 1
    ''',
        [usuario.idUsuario],
      );

      if (resultado.isNotEmpty) {
        final datos = resultado.first;

        _nombreController.text = datos['nombre']?.toString() ?? '';
        _correoController.text = datos['correo']?.toString() ?? '';
        _telefonoController.text = datos['telefono']?.toString() ?? '';
        _especialidadController.text = datos['especialidad']?.toString() ?? '';
        _cedulaController.text = datos['cedula_profesional']?.toString() ?? '';
      }
    } catch (e) {
      debugPrint('Error al cargar perfil profesional: $e');
    }

    if (mounted) {
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _guardarPerfil() async {
    final usuario = NaraUserSession.currentUser.value;

    if (usuario == null || usuario.idUsuario == null) {
      return;
    }

    try {
      final db = await NaraDatabase.database;

      await db.transaction((txn) async {
        await txn.update(
          'usuario',
          {
            'nombre': _nombreController.text.trim(),
            'correo': _correoController.text.trim(),
          },
          where: 'id_usuario = ?',
          whereArgs: [usuario.idUsuario],
        );

        await txn.update(
          'psicologo',
          {
            'telefono': _telefonoController.text.trim(),
            'especialidad': _especialidadController.text.trim(),
            'cedula_profesional': _cedulaController.text.trim(),
          },
          where: 'id_psicologo = ?',
          whereArgs: [usuario.idUsuario],
        );
      });

      final usuarioActualizado = usuario.copyWith(
        nombre: _nombreController.text.trim(),
        correo: _correoController.text.trim(),
      );

      await NaraUserSession.updateUser(usuarioActualizado);

      if (!mounted) return;

      setState(() {
        _editando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente 💜')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el perfil: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _especialidadController.dispose();
    _cedulaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NaraPalette>(
      valueListenable: NaraThemeController.current,
      builder: (context, palette, child) {
        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            title: Text(
              'Mi perfil profesional',
              style: TextStyle(
                color: palette.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: palette.surface,
            foregroundColor: palette.text,
          ),
          body: _cargando
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.account_circle_outlined,
                          size: 85,
                          color: palette.accent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Información profesional',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: palette.accent,
                          ),
                        ),
                        const SizedBox(height: 28),

                        _campo(
                          'Nombre completo',
                          _nombreController,
                          Icons.person_outline,
                          palette,
                          obligatorio: true,
                        ),
                        _campo(
                          'Correo electrónico',
                          _correoController,
                          Icons.email_outlined,
                          palette,
                          obligatorio: true,
                        ),
                        _campo(
                          'Teléfono',
                          _telefonoController,
                          Icons.phone_outlined,
                          palette,
                        ),
                        _campo(
                          'Especialidad',
                          _especialidadController,
                          Icons.medical_services_outlined,
                          palette,
                        ),
                        _campo(
                          'Cédula profesional',
                          _cedulaController,
                          Icons.badge_outlined,
                          palette,
                        ),

                        const SizedBox(height: 24),

                        if (!_editando)
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _editando = true;
                              });
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar perfil'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: palette.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(15),
                            ),
                          )
                        else ...[
                          ElevatedButton.icon(
                            onPressed: () async {
                              if (!_formKey.currentState!.validate()) {
                                return;
                              }

                              await _guardarPerfil();
                            },
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Guardar cambios'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: palette.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(15),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _cargarPerfil();
                                _editando = false;
                              });
                            },
                            child: Text(
                              'Cancelar',
                              style: TextStyle(color: palette.accent),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _campo(
    String etiqueta,
    TextEditingController controller,
    IconData icono,
    NaraPalette palette, {
    bool obligatorio = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        readOnly: !_editando,
        decoration: InputDecoration(
          labelText: etiqueta,
          prefixIcon: Icon(icono, color: palette.accent),
          filled: true,
          fillColor: palette.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: palette.border),
          ),
        ),
        validator: (value) {
          if (obligatorio && (value == null || value.trim().isEmpty)) {
            return 'Este campo es obligatorio.';
          }
          return null;
        },
      ),
    );
  }
}
