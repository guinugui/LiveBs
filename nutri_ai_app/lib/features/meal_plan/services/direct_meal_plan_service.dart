import 'package:http/http.dart' as http;
import 'dart:convert';

class DirectMealPlanService {
  static const String baseUrl = 'http://192.168.0.85:8000';
  
  /// Busca planos diretamente via HTTP sem depender do ApiService
  static Future<List<Map<String, dynamic>>> fetchPlansDirectly(String userEmail, String password) async {
    try {
      print('[DIRECT] 🔍 Buscando planos para: $userEmail');
      
      // 1. Fazer login direto
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': userEmail,
          'password': password,
        }),
      );
      
      if (loginResponse.statusCode != 200) {
        throw Exception('Login falhou: ${loginResponse.body}');
      }
      
      final loginData = json.decode(loginResponse.body);
      final token = loginData['access_token'];
      
      print('[DIRECT] ✅ Login bem-sucedido');
      
      // 2. Buscar planos
      final plansResponse = await http.get(
        Uri.parse('$baseUrl/meal-plan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (plansResponse.statusCode != 200) {
        throw Exception('Erro ao buscar planos: ${plansResponse.body}');
      }
      
      final plansData = json.decode(plansResponse.body);
      final plans = List<Map<String, dynamic>>.from(plansData['plans'] ?? []);
      
      print('[DIRECT] 📋 ${plans.length} planos encontrados');
      for (final plan in plans) {
        print('[DIRECT]   - ${plan['plan_name']} (ID: ${plan['id']})');
      }
      
      return plans;
      
    } catch (e) {
      print('[DIRECT] ❌ Erro: $e');
      rethrow;
    }
  }
  
  /// Cria novo plano diretamente
  static Future<Map<String, dynamic>> createPlanDirectly(String userEmail, String password) async {
    try {
      print('[DIRECT] 🚀 Criando novo plano para: $userEmail');
      
      // 1. Fazer login direto
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': userEmail,
          'password': password,
        }),
      );
      
      if (loginResponse.statusCode != 200) {
        throw Exception('Login falhou: ${loginResponse.body}');
      }
      
      final loginData = json.decode(loginResponse.body);
      final token = loginData['access_token'];
      
      // 2. Criar plano
      final createResponse = await http.post(
        Uri.parse('$baseUrl/meal-plan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (createResponse.statusCode != 201) {
        throw Exception('Erro ao criar plano: ${createResponse.body}');
      }
      
      final result = json.decode(createResponse.body);
      print('[DIRECT] ✅ Plano criado: ${result['plan_name']}');
      
      return result;
      
    } catch (e) {
      print('[DIRECT] ❌ Erro ao criar: $e');
      rethrow;
    }
  }
  
  /// Deleta plano diretamente
  static Future<void> deletePlanDirectly(String userEmail, String password, String planId) async {
    try {
      print('[DIRECT] 🗑️ Deletando plano: $planId');
      
      // 1. Fazer login direto
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': userEmail,
          'password': password,
        }),
      );
      
      if (loginResponse.statusCode != 200) {
        throw Exception('Login falhou: ${loginResponse.body}');
      }
      
      final loginData = json.decode(loginResponse.body);
      final token = loginData['access_token'];
      
      // 2. Deletar plano
      final deleteResponse = await http.delete(
        Uri.parse('$baseUrl/meal-plan/$planId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (deleteResponse.statusCode != 200) {
        throw Exception('Erro ao deletar plano: ${deleteResponse.body}');
      }
      
      print('[DIRECT] ✅ Plano deletado');
      
    } catch (e) {
      print('[DIRECT] ❌ Erro ao deletar: $e');
      rethrow;
    }
  }
  
  /// Busca detalhes do plano diretamente
  static Future<Map<String, dynamic>> fetchPlanDetailsDirectly(String userEmail, String password, String planId) async {
    try {
      print('[DIRECT] 📋 Buscando detalhes do plano: $planId');
      
      // 1. Fazer login direto
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': userEmail,
          'password': password,
        }),
      );
      
      if (loginResponse.statusCode != 200) {
        throw Exception('Login falhou: ${loginResponse.body}');
      }
      
      final loginData = json.decode(loginResponse.body);
      final token = loginData['access_token'];
      
      // 2. Buscar detalhes
      final detailsResponse = await http.get(
        Uri.parse('$baseUrl/meal-plan/$planId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (detailsResponse.statusCode != 200) {
        throw Exception('Erro ao buscar detalhes: ${detailsResponse.body}');
      }
      
      final result = json.decode(detailsResponse.body);
      print('[DIRECT] ✅ Detalhes carregados: ${result['plan_name']}');
      
      return result;
      
    } catch (e) {
      print('[DIRECT] ❌ Erro ao buscar detalhes: $e');
      rethrow;
    }
  }
}