class MealPlanQuestionnaire {
  final List<String> foodPreferences;
  final List<String> dislikedFoods;
  final String cookingTime;
  final int mealFrequency;
  final String budgetLevel;
  final List<String> specialGoals;

  const MealPlanQuestionnaire({
    this.foodPreferences = const [],
    this.dislikedFoods = const [],
    this.cookingTime = 'medium',
    this.mealFrequency = 5,
    this.budgetLevel = 'medium',
    this.specialGoals = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'food_preferences': foodPreferences,
      'disliked_foods': dislikedFoods,
      'cooking_time': cookingTime,
      'meal_frequency': mealFrequency,
      'budget_level': budgetLevel,
      'special_goals': specialGoals,
    };
  }

  factory MealPlanQuestionnaire.fromJson(Map<String, dynamic> json) {
    return MealPlanQuestionnaire(
      foodPreferences: List<String>.from(json['food_preferences'] ?? []),
      dislikedFoods: List<String>.from(json['disliked_foods'] ?? []),
      cookingTime: json['cooking_time'] ?? 'medium',
      mealFrequency: json['meal_frequency'] ?? 5,
      budgetLevel: json['budget_level'] ?? 'medium',
      specialGoals: List<String>.from(json['special_goals'] ?? []),
    );
  }

  MealPlanQuestionnaire copyWith({
    List<String>? foodPreferences,
    List<String>? dislikedFoods,
    String? cookingTime,
    int? mealFrequency,
    String? budgetLevel,
    List<String>? specialGoals,
  }) {
    return MealPlanQuestionnaire(
      foodPreferences: foodPreferences ?? this.foodPreferences,
      dislikedFoods: dislikedFoods ?? this.dislikedFoods,
      cookingTime: cookingTime ?? this.cookingTime,
      mealFrequency: mealFrequency ?? this.mealFrequency,
      budgetLevel: budgetLevel ?? this.budgetLevel,
      specialGoals: specialGoals ?? this.specialGoals,
    );
  }
}
