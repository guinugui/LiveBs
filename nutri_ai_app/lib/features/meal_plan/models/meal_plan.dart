class MealOption {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String recipe;

  MealOption({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.recipe,
  });

  factory MealOption.fromJson(Map<String, dynamic> json) {
    return MealOption(
      name: json['name'] ?? '',
      calories: json['calories'] ?? 0,
      protein: json['protein'] ?? 0,
      carbs: json['carbs'] ?? 0,
      fat: json['fat'] ?? 0,
      recipe: json['recipe'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'recipe': recipe,
    };
  }
}

class Meal {
  final String type;
  final List<MealOption> options;

  Meal({
    required this.type,
    required this.options,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      type: json['type'] ?? '',
      options: (json['options'] as List?)
              ?.map((e) => MealOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'options': options.map((e) => e.toJson()).toList(),
    };
  }

  String get displayName {
    switch (type) {
      case 'breakfast':
        return 'Café da Manhã';
      case 'morning_snack':
        return 'Lanche da Manhã';
      case 'lunch':
        return 'Almoço';
      case 'afternoon_snack':
        return 'Lanche da Tarde';
      case 'dinner':
        return 'Jantar';
      default:
        return type;
    }
  }
}

class DayPlan {
  final int day;
  final List<Meal> meals;

  DayPlan({
    required this.day,
    required this.meals,
  });

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    return DayPlan(
      day: json['day'] ?? 0,
      meals: (json['meals'] as List?)
              ?.map((e) => Meal.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'meals': meals.map((e) => e.toJson()).toList(),
    };
  }

  int get totalCalories {
    return meals.fold(
      0,
      (sum, meal) => sum + (meal.options.isNotEmpty ? meal.options[0].calories : 0),
    );
  }
}

class MealPlan {
  final List<DayPlan> days;

  MealPlan({required this.days});

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      days: (json['days'] as List?)
              ?.map((e) => DayPlan.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'days': days.map((e) => e.toJson()).toList(),
    };
  }
}
