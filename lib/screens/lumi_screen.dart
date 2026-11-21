
import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import '../models/lumi_activity.dart';

class LumiScreen extends StatefulWidget {
  final Color backgroundColor;
  final Color accentColor;
  final Color textColor;

  const LumiScreen({
    super.key,
    required this.backgroundColor,
    required this.accentColor,
    required this.textColor,
  });

  @override
  State<LumiScreen> createState() => _LumiScreenState();
}

class _LumiScreenState extends State<LumiScreen> {
  final Flutter3DController lumiController = Flutter3DController();
  final List<LumiActivity> dailyActivities = [
  ...lumiActivities,
]..shuffle();

List<LumiActivity> get selectedActivities =>
    dailyActivities.take(3).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Lumi'),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // TARJETA DE LUMI
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // MODELO 3D DE LUMI
                    SizedBox(
                      height: 250,
                      width: 250,
                      child: Flutter3DViewer(
                        controller: lumiController,
                        src: 'assets/models/lumi_animado.glb',

                        onLoad: (modelAddress) {
                          lumiController.playAnimation(loopCount: 0);
                        },

                        onError: (error) {
                          debugPrint('Error al cargar Lumi: $error');
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // NOMBRE DE LUMI
                    Text(
                      '¡Hola! Soy LUMI',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: widget.accentColor,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // MENSAJE MOTIVACIONAL
                    Text(
                      '"Decide intentarlo hoy; tu esfuerzo importa."',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.textColor,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              ...selectedActivities.map((activity) {
  return Container(
    padding: const EdgeInsets.all(18),
    margin: const EdgeInsets.only(bottom: 15),
    decoration: BoxDecoration(
      color: widget.backgroundColor,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Text(
          activity.emoji,
          style: const TextStyle(fontSize: 35),
        ),

        const SizedBox(width: 15),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: widget.accentColor,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                activity.description,
                style: TextStyle(
                  fontSize: 14,
                  color: widget.textColor,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '⭐ Recompensa: ${activity.points} puntos',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.textColor,
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
        ),
      ),
    );
  }
}
