import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Textos principais
  String get appTitle =>
      _localizedValues[locale.languageCode]?['app_title'] ?? 'LiveBs';
  String get home => _localizedValues[locale.languageCode]?['home'] ?? 'Início';
  String get profile =>
      _localizedValues[locale.languageCode]?['profile'] ?? 'Perfil';
  String get chat => _localizedValues[locale.languageCode]?['chat'] ?? 'Chat';
  String get mealPlan =>
      _localizedValues[locale.languageCode]?['meal_plan'] ?? 'Plano Alimentar';
  String get workout =>
      _localizedValues[locale.languageCode]?['workout'] ?? 'Treino';

  // Seções da Home
  String get virtualAssistants =>
      _localizedValues[locale.languageCode]?['virtual_assistants'] ??
      '💬 Assistentes Virtuais';
  String get dailyHydration =>
      _localizedValues[locale.languageCode]?['daily_hydration'] ??
      '💧 Hidratação Diária';
  String get personalizedWorkouts =>
      _localizedValues[locale.languageCode]?['personalized_workouts'] ??
      '💪 Treinos Personalizados';
  String get mealPlanSection =>
      _localizedValues[locale.languageCode]?['meal_plan_section'] ??
      '🍽️ Plano Alimentar';

  // Chat
  String get chatNutri =>
      _localizedValues[locale.languageCode]?['chat_nutri'] ?? 'Chat Nutri';
  String get chatPersonal =>
      _localizedValues[locale.languageCode]?['chat_personal'] ??
      'Chat Personal';
  String get foodQuestions =>
      _localizedValues[locale.languageCode]?['food_questions'] ??
      'Dúvidas sobre\\nalimentos';
  String get workoutExercises =>
      _localizedValues[locale.languageCode]?['workout_exercises'] ??
      'Treinos e\\nexercícios';

  // Botões
  String get generateWorkout =>
      _localizedValues[locale.languageCode]?['generate_workout'] ??
      'Gerar Treino';
  String get myWorkouts =>
      _localizedValues[locale.languageCode]?['my_workouts'] ?? 'Meus Treinos';
  String get newPlan =>
      _localizedValues[locale.languageCode]?['new_plan'] ?? 'Novo Plano';
  String get myPlans =>
      _localizedValues[locale.languageCode]?['my_plans'] ?? 'Meus Planos';
  String get addWater =>
      _localizedValues[locale.languageCode]?['add_water'] ?? 'Adicionar 500ml';
  String get newWorkout =>
      _localizedValues[locale.languageCode]?['new_workout'] ?? 'Novo Treino';

  // Perfil
  String get currentWeight =>
      _localizedValues[locale.languageCode]?['current_weight'] ?? 'Peso Atual';
  String get targetWeight =>
      _localizedValues[locale.languageCode]?['target_weight'] ?? 'Meta';
  String get hydration =>
      _localizedValues[locale.languageCode]?['hydration'] ?? 'Hidratação';
  String get language =>
      _localizedValues[locale.languageCode]?['language'] ?? 'Idioma';
  String get darkMode =>
      _localizedValues[locale.languageCode]?['dark_mode'] ?? 'Modo Escuro';
  String get settings =>
      _localizedValues[locale.languageCode]?['settings'] ?? 'Configurações';

  // Treinos
  String get aiWorkoutGenerator =>
      _localizedValues[locale.languageCode]?['ai_workout_generator'] ??
      'Gerador de Treino IA';
  String get workoutsWithAI =>
      _localizedValues[locale.languageCode]?['workouts_with_ai'] ??
      'Treinos com IA 🤖';
  String get generatePersonalizedWorkouts =>
      _localizedValues[locale
          .languageCode]?['generate_personalized_workouts'] ??
      'Gere treinos personalizados com inteligência artificial';

  // Alimentação
  String get healthyEating =>
      _localizedValues[locale.languageCode]?['healthy_eating'] ??
      'Alimentação Saudável 🥗';
  String get generateNutritionalPlan =>
      _localizedValues[locale.languageCode]?['generate_nutritional_plan'] ??
      'Gere seu plano nutricional personalizado';

  // Personal Virtual
  String get personalVirtual =>
      _localizedValues[locale.languageCode]?['personal_virtual'] ??
      'Personal Virtual';

  // Mensagens
  String get waterAdded =>
      _localizedValues[locale.languageCode]?['water_added'] ??
      '+ 500ml de água registrado!';
  String get loadingError =>
      _localizedValues[locale.languageCode]?['loading_error'] ??
      'Erro ao carregar dados';
  String get waterError =>
      _localizedValues[locale.languageCode]?['water_error'] ??
      'Erro ao registrar água';

  static const Map<String, Map<String, String>> _localizedValues = {
    'pt': {
      'app_title': 'LiveBs',
      'home': 'Início',
      'profile': 'Perfil',
      'chat': 'Chat',
      'meal_plan': 'Plano Alimentar',
      'workout': 'Treino',
      'virtual_assistants': '💬 Assistentes Virtuais',
      'daily_hydration': '💧 Hidratação Diária',
      'personalized_workouts': '💪 Treinos Personalizados',
      'meal_plan_section': '🍽️ Plano Alimentar',
      'chat_nutri': 'Chat Nutri',
      'chat_personal': 'Chat Personal',
      'food_questions': 'Dúvidas sobre\\nalimentos',
      'workout_exercises': 'Treinos e\\nexercícios',
      'generate_workout': 'Gerar Treino',
      'my_workouts': 'Meus Treinos',
      'new_plan': 'Novo Plano',
      'my_plans': 'Meus Planos',
      'add_water': 'Adicionar 500ml',
      'new_workout': 'Novo Treino',
      'current_weight': 'Peso Atual',
      'target_weight': 'Meta',
      'hydration': 'Hidratação',
      'language': 'Idioma',
      'dark_mode': 'Modo Escuro',
      'settings': 'Configurações',
      'ai_workout_generator': 'Gerador de Treino IA',
      'workouts_with_ai': 'Treinos com IA 🤖',
      'generate_personalized_workouts':
          'Gere treinos personalizados com inteligência artificial',
      'healthy_eating': 'Alimentação Saudável 🥗',
      'generate_nutritional_plan': 'Gere seu plano nutricional personalizado',
      'personal_virtual': 'Personal Virtual',
      'water_added': '+ 500ml de água registrado!',
      'loading_error': 'Erro ao carregar dados',
      'water_error': 'Erro ao registrar água',
    },
    'en': {
      'app_title': 'LiveBs',
      'home': 'Home',
      'profile': 'Profile',
      'chat': 'Chat',
      'meal_plan': 'Meal Plan',
      'workout': 'Workout',
      'virtual_assistants': '💬 Virtual Assistants',
      'daily_hydration': '💧 Daily Hydration',
      'personalized_workouts': '💪 Personalized Workouts',
      'meal_plan_section': '🍽️ Meal Plan',
      'chat_nutri': 'Nutri Chat',
      'chat_personal': 'Personal Chat',
      'food_questions': 'Food\\nquestions',
      'workout_exercises': 'Workouts and\\nexercises',
      'generate_workout': 'Generate Workout',
      'my_workouts': 'My Workouts',
      'new_plan': 'New Plan',
      'my_plans': 'My Plans',
      'add_water': 'Add 500ml',
      'new_workout': 'New Workout',
      'current_weight': 'Current Weight',
      'target_weight': 'Target',
      'hydration': 'Hydration',
      'language': 'Language',
      'dark_mode': 'Dark Mode',
      'settings': 'Settings',
      'ai_workout_generator': 'AI Workout Generator',
      'workouts_with_ai': 'AI Workouts 🤖',
      'generate_personalized_workouts':
          'Generate personalized workouts with artificial intelligence',
      'healthy_eating': 'Healthy Eating 🥗',
      'generate_nutritional_plan':
          'Generate your personalized nutritional plan',
      'personal_virtual': 'Virtual Personal',
      'water_added': '+ 500ml of water recorded!',
      'loading_error': 'Error loading data',
      'water_error': 'Error recording water',
    },
    'es': {
      'app_title': 'LiveBs',
      'home': 'Inicio',
      'profile': 'Perfil',
      'chat': 'Chat',
      'meal_plan': 'Plan Alimentario',
      'workout': 'Entrenamiento',
      'virtual_assistants': '💬 Asistentes Virtuales',
      'daily_hydration': '💧 Hidratación Diaria',
      'personalized_workouts': '💪 Entrenamientos Personalizados',
      'meal_plan_section': '🍽️ Plan Alimentario',
      'chat_nutri': 'Chat Nutri',
      'chat_personal': 'Chat Personal',
      'food_questions': 'Dudas sobre\\nalimentos',
      'workout_exercises': 'Entrenamientos y\\nejercicios',
      'generate_workout': 'Generar Entrenamiento',
      'my_workouts': 'Mis Entrenamientos',
      'new_plan': 'Nuevo Plan',
      'my_plans': 'Mis Planes',
      'add_water': 'Añadir 500ml',
      'new_workout': 'Nuevo Entrenamiento',
      'current_weight': 'Peso Actual',
      'target_weight': 'Meta',
      'hydration': 'Hidratación',
      'language': 'Idioma',
      'dark_mode': 'Modo Oscuro',
      'settings': 'Configuración',
      'ai_workout_generator': 'Generador de Entrenamiento IA',
      'workouts_with_ai': 'Entrenamientos con IA 🤖',
      'generate_personalized_workouts':
          'Genera entrenamientos personalizados con inteligencia artificial',
      'healthy_eating': 'Alimentación Saludable 🥗',
      'generate_nutritional_plan': 'Genera tu plan nutricional personalizado',
      'personal_virtual': 'Personal Virtual',
      'water_added': '+ 500ml de agua registrados!',
      'loading_error': 'Error al cargar datos',
      'water_error': 'Error al registrar agua',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['pt', 'en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}
