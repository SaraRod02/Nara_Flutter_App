
import 'package:material_ui/material_ui.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import '../models/lumi_activity.dart';
import 'package:shared_preferences/shared_preferences.dart';


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
  final Set<String> completedActivities = {};
  List<LumiActivity> selectedActivities = [];
  final List<String> motivationalMessages = [
  '¡¡Hoy has hecho algo bueno por ti!',
  '¡Estoy orgulloso de cada paso que das!',
  '¡Eres más fuerte de lo que imaginas!',
  '¡Me alegra verte muy feliz!',
  '¡Siempre serás importante para mí!',
  '¡Nunca olvides lo mucho que vales!',
  '¡Cada día tienes una nueva oportunidad!',
  '¡Sigue adelante, creo mucho en ti!',
  '¡Estoy aquí para acompañarte siempre!',

];
String currentMessage = 'Este espacio es para ti';

void showMotivationalMessage() {
  setState(() {
    motivationalMessages.shuffle();
    currentMessage = motivationalMessages.first;
  });
}

  int get totalPoints {
  return selectedActivities
      .where((activity) =>
          completedActivities.contains(activity.title))
      .fold(0, (total, activity) => total + activity.points);
}
int get completedCount => completedActivities
    .where((title) =>
        selectedActivities.any((activity) => activity.title == title))
    .length;

double get dailyProgress =>
    selectedActivities.isEmpty ? 0 : completedCount / selectedActivities.length;
  
  @override
void initState() {
  super.initState();
  loadDailyActivities();
}
Future<void> loadDailyActivities() async {
  final prefs = await SharedPreferences.getInstance();

  final today = DateTime.now().toString().split(' ')[0];
  final savedDate = prefs.getString('activity_date');

  if (savedDate == today) {
    final savedTitles = prefs.getStringList('daily_activities');

    if (savedTitles != null) {
      final savedCompleted =
    prefs.getStringList('completed_activities') ?? [];

setState(() {
  selectedActivities = lumiActivities
      .where((activity) => savedTitles.contains(activity.title))
      .toList();

  completedActivities
    ..clear()
    ..addAll(savedCompleted);
});
      return;
    }
  }

  final shuffledActivities = [...lumiActivities]..shuffle();
  final newActivities = shuffledActivities.take(3).toList();

  await prefs.setString('activity_date', today);
  await prefs.setStringList(
    'daily_activities',
    newActivities.map((activity) => activity.title).toList(),
  );

  setState(() {
    selectedActivities = newActivities;
  });
}

Future<void> saveCompletedActivities() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setStringList(
    'completed_activities',
    completedActivities.toList(),
  );
}

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
  height: 220,
  width: 250,
  child: Stack(
    clipBehavior: Clip.none,
    alignment: Alignment.center,
    children: [
      // Modelo 3D de Lumi
      Positioned(
        left: 0,
        child: SizedBox(
          height: 200,
          width: 200,
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
      ),

      // Ventana de diálogo
      Positioned(
  left:165,
  top: 5,
  child: SizedBox(
    width: 125,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        // Cuerpo de la ventana
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Text(
            currentMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),

        // Punta del globo
        Positioned(
          left: -9,
          top: 20,
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    ),
  ),
),
    ],
  ),
),
                    
                    const SizedBox(height: 5),

                  ],
                ),
              ),

const SizedBox(height: 20),

Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: widget.backgroundColor,
    borderRadius: BorderRadius.circular(20),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        '⭐ Mis puntos',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        '$totalPoints puntos',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: widget.accentColor,
        ),
      ),
    ],
  ),
),
              const SizedBox(height: 30),

              Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: widget.backgroundColor,
    borderRadius: BorderRadius.circular(20),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Progreso diario',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '$completedCount/${selectedActivities.length}',
            style: TextStyle(
              color: widget.accentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      LinearProgressIndicator(
        value: dailyProgress,
        minHeight: 10,
        backgroundColor: Colors.white,
        valueColor: AlwaysStoppedAnimation<Color>(
          widget.accentColor,
        ),
        borderRadius: BorderRadius.circular(10),
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
       Checkbox(
  value: completedActivities.contains(activity.title),
  activeColor: widget.accentColor,
  onChanged: (value) {
  setState(() {
    if (value == true) {
      completedActivities.add(activity.title);
    } else {
      completedActivities.remove(activity.title);
    }
  });

  if (value == true) {
    showMotivationalMessage();
  }

  saveCompletedActivities();
},
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
