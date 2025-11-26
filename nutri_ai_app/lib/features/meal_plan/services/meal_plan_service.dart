import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_plan.dart';
import '../../../core/network/api_service.dart';

class MealPlanService {
  static const String baseUrl = 'http://192.168.0.85:8000';
  final ApiService _apiService = ApiService();

  /// Gera e salva um novo plano alimentar
  Future<Map<String, dynamic>> generateMealPlan() async {
    try {
      return await _apiService.generateMealPlan();
    } catch (e) {
      throw Exception('Erro ao gerar plano alimentar: $e');
    }
  }

  /// Lista todos os planos salvos do usuário
  Future<List<Map<String, dynamic>>> getSavedMealPlans() async {
    try {
      print('[DEBUG] MealPlanService: Chamando getSavedMealPlans...');
      final response = await _apiService.getSavedMealPlans();
      print('[DEBUG] MealPlanService: Response recebida: $response');
      
      if (response['plans'] != null) {
        final plans = List<Map<String, dynamic>>.from(response['plans']);
        print('[DEBUG] MealPlanService: ${plans.length} planos encontrados');
        return plans;
      } else {
        print('[DEBUG] MealPlanService: Nenhum plano encontrado');
        return [];
      }
    } catch (e) {
      print('[ERROR] MealPlanService: $e');
      throw Exception('Erro ao buscar planos salvos: $e');
    }
  }

  /// Obtém detalhes completos de um plano específico
  Future<Map<String, dynamic>> getMealPlanDetails(String planId) async {
    try {
      return await _apiService.getMealPlanDetails(planId);
    } catch (e) {
      throw Exception('Erro ao buscar detalhes do plano: $e');
    }
  }

  /// Deleta um plano salvo
  Future<void> deleteMealPlan(String planId) async {
    try {
      await _apiService.deleteMealPlan(planId);
    } catch (e) {
      throw Exception('Erro ao deletar plano: $e');
    }
  }

  Future<List<MealPlan>> getUserMealPlans(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final response = await http.get(
      Uri.parse('$baseUrl/meal-plans/$userId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
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
