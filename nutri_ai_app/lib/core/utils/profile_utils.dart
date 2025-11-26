import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../network/api_service.dart';

class ProfileUtils {
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final apiService = ApiService();
      await apiService.initialize();
      
      final profile = await apiService.getProfile();
      return profile;
    } catch (e) {
      print('Erro ao buscar perfil: $e');
      return null;
    }
  }

  static Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(profile));
  }

  static Future<Map<String, dynamic>?> getCachedUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileString = prefs.getString('user_profile');
    
    if (profileString != null) {
      return jsonDecode(profileString);
    }
    return null;
  }

  static double calculateBMI(double weight, double height) {
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  static double calculateDailyCalories({
    required String gender,
    required int age,
    required double weight,
    required double height,
    required String activityLevel,
  }) {
    // Calcular BMR usando a fórmula de Harris-Benedict
    double bmr;
    if (gender == 'male') {
      bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }

    // Multiplicadores por nível de atividade
    double multiplier;
    switch (activityLevel) {
      case 'sedentary':
        multiplier = 1.2;
        break;
      case 'light':
        multiplier = 1.375;
        break;
      case 'moderate':
        multiplier = 1.55;
        break;
      case 'active':
        multiplier = 1.725;
        break;
      case 'very_active':
        multiplier = 1.9;
        break;
      default:
        multiplier = 1.2;
    }

    // Retornar com déficit calórico para emagrecimento (500 cal a menos)
    return (bmr * multiplier) - 500;
  }
}