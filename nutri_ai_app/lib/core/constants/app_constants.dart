class AppConstants {
  // API
  static const String appName = 'LiveBs';
  static const String apiVersion = 'v1';

  // Defaults
  static const int defaultCalorieGoal = 2000;
  static const double defaultWaterGoal = 2.0; // litros

  // Activity Levels
  static const Map<String, double> activityMultipliers = {
    'sedentary': 1.2,
    'light': 1.375,
    'moderate': 1.55,
    'active': 1.725,
    'very_active': 1.9,
  };

  // Macros Distribution (%)
  static const Map<String, double> macrosDistribution = {
    'protein': 0.30,
    'carbs': 0.40,
    'fat': 0.30,
  };

  // Chat
  static const int maxChatHistoryLength = 50;
  static const String aiNutritionistName = 'Dr. Nutri';
}
