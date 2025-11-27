import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/workout_plan.dart';

class WorkoutPlanService {
  static const String baseUrl = 'http://192.168.0.85:8001';

  /// Busca planos de treino do usuário
  static Future<List<WorkoutPlan>> fetchWorkoutPlans(
    String userEmail,
    String password,
  ) async {
    try {
      print('[WORKOUT] 🏋️ Buscando planos de treino para: $userEmail');

      // 1. Fazer login
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': userEmail, 'password': password}),
      );

      if (loginResponse.statusCode != 200) {
        throw Exception('Login falhou: ${loginResponse.body}');
      }

      final loginData = json.decode(loginResponse.body);
      final token = loginData['access_token'];

      // 2. Buscar planos de treino
      final plansResponse = await http.get(
        Uri.parse('$baseUrl/workout-plan/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (plansResponse.statusCode != 200) {
        throw Exception('Erro ao buscar planos: ${plansResponse.body}');
      }

      final plansData = json.decode(plansResponse.body) as List;
      return plansData.map((plan) => WorkoutPlan.fromJson(plan)).toList();
    } catch (e) {
      print('[❌ WORKOUT ERROR] Erro ao buscar planos: $e');
      throw Exception('Erro ao buscar planos de treino: $e');
    }
  }

  /// Cria novo plano de treino baseado no questionário
  static Future<WorkoutPlan> createWorkoutPlan(
    String userEmail,
    String password,
    WorkoutQuestionnaire questionnaire,
  ) async {
    try {
      print('[WORKOUT] 🚀 Criando plano de treino...');

      // 1. Fazer login
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': userEmail, 'password': password}),
      );

      if (loginResponse.statusCode != 200) {
        throw Exception('Login falhou: ${loginResponse.body}');
      }

      final loginData = json.decode(loginResponse.body);
      final token = loginData['access_token'];

      // 2. Criar plano de treino
      final createResponse = await http.post(
        Uri.parse('$baseUrl/workout-plan/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(questionnaire.toJson()),
      );

      if (createResponse.statusCode != 201) {
        throw Exception('Erro ao criar plano: ${createResponse.body}');
      }

      final planData = json.decode(createResponse.body);
      return WorkoutPlan.fromJson(planData);
    } catch (e) {
      print('[❌ WORKOUT ERROR] Erro ao criar plano: $e');
      throw Exception('Erro ao criar plano de treino: $e');
    }
  }

  static Future<void> deleteWorkoutPlan(
    String email,
    String password,
    String planId,
  ) async {
    try {
      // Login first
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        body: {'username': email, 'password': password},
      );

      if (loginResponse.statusCode != 200) {
        throw Exception('Erro no login');
      }

      final loginData = json.decode(loginResponse.body);
      final token = loginData['access_token'];

      // Delete workout plan
      final response = await http.delete(
        Uri.parse('$baseUrl/workout-plan/$planId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao deletar plano de treino');
      }
    } catch (e) {
      throw Exception('Erro: $e');
    }
  }
}
