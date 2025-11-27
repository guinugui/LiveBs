class WorkoutPlan {
  final String id;
  final String planName;
  final String? planSummary;
  final String workoutData;
  final DateTime createdAt;
  final String userId;
  final String workoutType; // derivado dos dados
  final int daysPerWeek; // derivado dos dados

  WorkoutPlan({
    required this.id,
    required this.planName,
    this.planSummary,
    required this.workoutData,
    required this.createdAt,
    required this.userId,
    this.workoutType = 'home',
    this.daysPerWeek = 3,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    // Tentar extrair workoutType e daysPerWeek dos dados do treino
    String workoutType = 'home';
    int daysPerWeek = 3;

    try {
      String workoutDataString = json['workout_data']?.toString() ?? '{}';

      // Tentar extrair workout_schedule para contar os dias
      RegExp scheduleRegex = RegExp(r'workout_schedule:\s*\[([^\]]+)\]');
      Match? scheduleMatch = scheduleRegex.firstMatch(workoutDataString);
      if (scheduleMatch != null) {
        String scheduleContent = scheduleMatch.group(1) ?? '';
        // Contar quantos objetos de dia existem
        RegExp dayRegex = RegExp(r'\{day:');
        Iterable<Match> dayMatches = dayRegex.allMatches(scheduleContent);
        daysPerWeek = dayMatches.length;
        print(
          '[WORKOUT_PLAN] 📊 Dias encontrados no workoutData: $daysPerWeek',
        );
      }

      // Extrair workout_type de forma mais precisa
      // Primeiro: tentar encontrar no plan_name
      String planName = json['plan_name']?.toString().toLowerCase() ?? '';
      if (planName.contains('gym') || planName.contains('academia')) {
        workoutType = 'gym';
        print('[WORKOUT_PLAN] 🏋️ Tipo detectado pelo plan_name: GYM/Academia');
      } else if (planName.contains('casa') || planName.contains('home')) {
        workoutType = 'home';
        print('[WORKOUT_PLAN] 🏠 Tipo detectado pelo plan_name: Casa/Home');
      } else {
        // Segundo: procurar nos dados do workout
        String lowerData = workoutDataString.toLowerCase();
        if (lowerData.contains('gym') ||
            lowerData.contains('academia') ||
            lowerData.contains('halteres') ||
            lowerData.contains('máquinas') ||
            lowerData.contains('equipamentos')) {
          workoutType = 'gym';
          print(
            '[WORKOUT_PLAN] 🏋️ Tipo detectado pelos dados: GYM (equipamentos)',
          );
        } else if (lowerData.contains('casa') ||
            lowerData.contains('home') ||
            lowerData.contains('peso corporal') ||
            lowerData.contains('flexão')) {
          workoutType = 'home';
          print(
            '[WORKOUT_PLAN] 🏠 Tipo detectado pelos dados: Casa (peso corporal)',
          );
        } else {
          // Padrão: assumir gym se não conseguir detectar
          workoutType = 'gym';
          print('[WORKOUT_PLAN] ⚙️ Tipo padrão aplicado: GYM');
        }
      }
    } catch (e) {
      print('[WORKOUT_PLAN] ⚠️ Erro ao extrair dados: $e');
      // Manter valores padrão
    }

    return WorkoutPlan(
      id: json['id']?.toString() ?? '',
      planName: json['plan_name']?.toString() ?? '',
      planSummary: json['plan_summary']?.toString(),
      workoutData: json['workout_data']?.toString() ?? '{}',
      createdAt: _parseDateTime(json['created_at']),
      userId: json['user_id']?.toString() ?? '',
      workoutType: workoutType,
      daysPerWeek: daysPerWeek,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        // Se não conseguir fazer parse, retorna a data atual
        return DateTime.now();
      }
    }

    if (value is int) {
      try {
        // Assume que é timestamp em milliseconds
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        try {
          // Tenta como timestamp em seconds
          return DateTime.fromMillisecondsSinceEpoch(value * 1000);
        } catch (e) {
          return DateTime.now();
        }
      }
    }

    // Para qualquer outro tipo, retorna a data atual
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_name': planName,
      'plan_summary': planSummary,
      'workout_data': workoutData,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
    };
  }
}

class WorkoutQuestionnaire {
  final bool hasMusculoskeletalProblems;
  final String? musculoskeletalDetails;
  final bool hasRespiratoryProblems;
  final String? respiratoryDetails;
  final bool hasCardiacProblems;
  final String? cardiacDetails;
  final List<String> previousInjuries;
  final String fitnessLevel;
  final List<String> preferredExercises;
  final List<String> exercisesToAvoid;
  final String workoutType; // 'home' ou 'gym'
  final int daysPerWeek;
  final int sessionDuration; // em minutos
  final List<String> availableDays;

  WorkoutQuestionnaire({
    required this.hasMusculoskeletalProblems,
    this.musculoskeletalDetails,
    required this.hasRespiratoryProblems,
    this.respiratoryDetails,
    required this.hasCardiacProblems,
    this.cardiacDetails,
    required this.previousInjuries,
    required this.fitnessLevel,
    required this.preferredExercises,
    required this.exercisesToAvoid,
    required this.workoutType,
    required this.daysPerWeek,
    required this.sessionDuration,
    required this.availableDays,
  });

  Map<String, dynamic> toJson() {
    return {
      'has_musculoskeletal_problems': hasMusculoskeletalProblems,
      'musculoskeletal_details': musculoskeletalDetails,
      'has_respiratory_problems': hasRespiratoryProblems,
      'respiratory_details': respiratoryDetails,
      'has_cardiac_problems': hasCardiacProblems,
      'cardiac_details': cardiacDetails,
      'previous_injuries': previousInjuries,
      'fitness_level': fitnessLevel,
      'preferred_exercises': preferredExercises,
      'exercises_to_avoid': exercisesToAvoid,
      'workout_type': workoutType,
      'days_per_week': daysPerWeek,
      'session_duration': sessionDuration,
      'available_days': availableDays,
    };
  }
}
