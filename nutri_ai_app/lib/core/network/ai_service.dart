import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final _dio = Dio(BaseOptions(
    baseUrl: kApiBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  // Personal Trainer IA
  Future<Map<String, dynamic>> generateWorkoutPlan({
    required Map<String, dynamic> userProfile,
    required int workoutDaysPerWeek,
    required List<String> muscularProblems,
    required List<String> fitnessGoals,
  }) async {
    
    try {
      // Chamada para o backend local ao invés da API OpenAI diretamente
      final response = await _dio.post(
        '/workout-plans/',
        data: {
          'user_profile': userProfile,
          'workout_days_per_week': workoutDaysPerWeek,
          'muscular_problems': muscularProblems,
          'fitness_goals': fitnessGoals,
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('Erro ao gerar plano de treino: $e');
    }
  }

  // Nutricionista IA  
  Future<Map<String, dynamic>> generateMealPlan({
    required Map<String, dynamic> userProfile,
    required List<String> allergies,
    required List<String> dislikes,
    required List<String> dietaryPreferences,
    required String dietaryStyle,
  }) async {
    
    try {
      // Chamada para o backend local ao invés da API OpenAI diretamente
      final response = await _dio.post(
        '/meal-plans/',
        data: {
          'user_profile': userProfile,
          'allergies': allergies,
          'dislikes': dislikes,
          'dietary_preferences': dietaryPreferences,
          'dietary_style': dietaryStyle,
        },
      );

      return response.data;
    } catch (e) {
      throw Exception('Erro ao gerar plano alimentar: $e');
    }
  }
}