import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal_plan.dart';

class MealPlanService {
  static const String baseUrl = 'http://192.168.0.85:8000';

  Future<MealPlan> generateMealPlan({
    required double weight,
    required double height,
    required int age,
    required double targetWeight,
    required String activityLevel,
    required int dailyCalories,
    List<String>? dietaryRestrictions,
    List<String>? dietaryPreferences,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/meal-plan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'weight': weight,
        'height': height,
        'age': age,
        'target_weight': targetWeight,
        'activity_level': activityLevel,
        'daily_calories': dailyCalories,
        'dietary_restrictions': dietaryRestrictions ?? [],
        'dietary_preferences': dietaryPreferences ?? [],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return MealPlan.fromJson(data);
    } else {
      throw Exception('Erro ao gerar plano alimentar: ${response.body}');
    }
  }

  Future<List<MealPlan>> getUserMealPlans(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/meal-plans/$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => MealPlan.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar planos alimentares');
    }
  }

  int calculateDailyCalories({
    required double weight,
    required double height,
    required int age,
    required String gender,
    required String activityLevel,
    required String goal,
  }) {
    // Fórmula de Harris-Benedict
    double bmr;
    if (gender == 'male') {
      bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }

    // Multiplicador de atividade
    double activityMultiplier;
    switch (activityLevel) {
      case 'sedentary':
        activityMultiplier = 1.2;
        break;
      case 'light':
        activityMultiplier = 1.375;
        break;
      case 'moderate':
        activityMultiplier = 1.55;
        break;
      case 'active':
        activityMultiplier = 1.725;
        break;
      case 'very_active':
        activityMultiplier = 1.9;
        break;
      default:
        activityMultiplier = 1.2;
    }

    double tdee = bmr * activityMultiplier;

    // Ajuste para objetivo
    if (goal == 'lose_weight') {
      tdee -= 500; // Déficit de 500 calorias
    } else if (goal == 'gain_weight') {
      tdee += 300; // Superávit de 300 calorias
    }

    return tdee.round();
  }
}
