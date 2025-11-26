class WorkoutPlan {
  final String id;
  final String planName;
  final String planNumber;
  final String workoutType; // 'home' ou 'gym'
  final int daysPerWeek;
  final Map<String, dynamic> planContent;
  final DateTime createdAt;
  final String userId;

  WorkoutPlan({
    required this.id,
    required this.planName,
    required this.planNumber,
    required this.workoutType,
    required this.daysPerWeek,
    required this.planContent,
    required this.createdAt,
    required this.userId,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id']?.toString() ?? '',
      planName: json['plan_name']?.toString() ?? '',
      planNumber: json['plan_number']?.toString() ?? '',
      workoutType: json['workout_type']?.toString() ?? 'home',
      daysPerWeek: json['days_per_week'] ?? 5,
      planContent: json['plan_content'] ?? {},
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      userId: json['user_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_name': planName,
      'plan_number': planNumber,
      'workout_type': workoutType,
      'days_per_week': daysPerWeek,
      'plan_content': planContent,
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