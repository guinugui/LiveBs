import 'package:flutter/material.dart';
import '../models/meal_plan.dart';

class MealPlanViewScreen extends StatefulWidget {
  final MealPlan mealPlan;

  const MealPlanViewScreen({super.key, required this.mealPlan});

  @override
  State<MealPlanViewScreen> createState() => _MealPlanViewScreenState();
}

class _MealPlanViewScreenState extends State<MealPlanViewScreen> {
  late PageController _pageController;
  int _currentDay = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seu Plano Alimentar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implementar compartilhamento
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Seletor de dias
          Container(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.mealPlan.days.length, (index) {
                final day = widget.mealPlan.days[index];
                final isSelected = _currentDay == index;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Dia ${day.day}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.totalCalories} kcal',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          // Conteúdo dos dias
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentDay = index;
                });
              },
              itemCount: widget.mealPlan.days.length,
              itemBuilder: (context, dayIndex) {
                final day = widget.mealPlan.days[dayIndex];
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: day.meals.length,
                  itemBuilder: (context, mealIndex) {
                    final meal = day.meals[mealIndex];
                    return _buildMealCard(meal);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(Meal meal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getMealColor(meal.type),
          child: Icon(_getMealIcon(meal.type), color: Colors.white),
        ),
        title: Text(
          meal.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: meal.options.isNotEmpty
            ? Text(
                '${meal.options[0].calories} kcal',
                style: const TextStyle(color: Colors.grey),
              )
            : null,
        children: meal.options.map((option) => _buildMealOption(option)).toList(),
      ),
    );
  }

  Widget _buildMealOption(MealOption option) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Macros
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroInfo('Calorias', '${option.calories}', 'kcal', Colors.orange),
              _buildMacroInfo('Proteína', '${option.protein}', 'g', Colors.red),
              _buildMacroInfo('Carbs', '${option.carbs}', 'g', Colors.blue),
              _buildMacroInfo('Gordura', '${option.fat}', 'g', Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          // Receita
          const Text(
            'Modo de Preparo:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            option.recipe,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroInfo(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          unit,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Color _getMealColor(String type) {
    switch (type) {
      case 'breakfast':
        return Colors.orange;
      case 'morning_snack':
        return Colors.amber;
      case 'lunch':
        return Colors.green;
      case 'afternoon_snack':
        return Colors.lightBlue;
      case 'dinner':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  IconData _getMealIcon(String type) {
    switch (type) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'morning_snack':
      case 'afternoon_snack':
        return Icons.cookie;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant;
    }
  }
}
