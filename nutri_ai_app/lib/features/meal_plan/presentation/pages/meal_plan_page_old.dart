import 'package:flutter/material.dart';
import '../../../../core/network/api_service.dart';

class MealPlanPage extends StatefulWidget {
  const MealPlanPage({super.key});

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  bool _isLoading = true;
  bool _isGenerating = false;
  Map<String, dynamic>? _mealPlan;

  @override
  void initState() {
    super.initState();
    _loadMealPlan();
  }

  Future<void> _loadMealPlan() async {
    try {
      final plan = await ApiService().getMealPlan();
      
      if (mounted) {
        setState(() {
          _mealPlan = plan;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generateMealPlan() async {
    setState(() => _isGenerating = true);

    try {
      final plan = await ApiService().generateMealPlan();
      
      if (mounted) {
        setState(() {
          _mealPlan = plan;
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plano alimentar gerado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar plano: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_mealPlan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Plano Alimentar')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Nenhum plano alimentar encontrado'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateMealPlan,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: const Text('Gerar Plano Alimentar'),
              ),
            ],
          ),
        ),
      );
    }

    final meals = _mealPlan!['meals'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plano Alimentar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isGenerating ? null : _generateMealPlan,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 7,
        itemBuilder: (context, dayIndex) {
          final dayMeals = meals.where((m) => m['day_number'] == dayIndex + 1).toList();
          return _buildDayCard(context, dayIndex + 1, dayMeals);
        },
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, int day, List<dynamic> meals) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          'Dia $day',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${meals.length} refeições'),
        children: meals.isNotEmpty
            ? meals.map((meal) {
                return _buildMealItem(
                  context,
                  meal['meal_type'] ?? '',
                  meal['name'] ?? '',
                  '${meal['calories'] ?? 0} kcal',
                  _getMealIcon(meal['meal_type'] ?? ''),
                  meal,
                );
              }).toList()
            : [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Nenhuma refeição planejada'),
                ),
              ],
      ),
    );
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'café da manhã':
      case 'breakfast':
        return Icons.breakfast_dining_outlined;
      case 'lanche da manhã':
      case 'morning snack':
        return Icons.fastfood_outlined;
      case 'almoço':
      case 'lunch':
        return Icons.lunch_dining_outlined;
      case 'lanche da tarde':
      case 'afternoon snack':
        return Icons.cookie_outlined;
      case 'jantar':
      case 'dinner':
        return Icons.dinner_dining_outlined;
      default:
        return Icons.restaurant_outlined;
    }
  }

  Widget _buildMealItem(
    BuildContext context,
    String mealType,
    String mealName,
    String calories,
    IconData icon,
    Map<String, dynamic> meal,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
        child: Icon(icon, color: const Color(0xFF6C63FF)),
      ),
      title: Text(mealType),
      subtitle: Text(mealName),
      trailing: Text(
        calories,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF4CAF50),
        ),
      ),
      onTap: () {
        _showMealDetails(context, meal);
      },
    );
  }

  void _showMealDetails(BuildContext context, Map<String, dynamic> meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal['meal_type'] ?? '',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    meal['name'] ?? '',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Macronutrientes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildMacroRow('Proteínas', '${meal['protein'] ?? 0}g', Colors.red),
                  _buildMacroRow('Carboidratos', '${meal['carbs'] ?? 0}g', Colors.orange),
                  _buildMacroRow('Gorduras', '${meal['fats'] ?? 0}g', Colors.blue),
                  const SizedBox(height: 24),
                  const Text(
                    'Ingredientes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(meal['ingredients'] ?? 'Não informado'),
                  const SizedBox(height: 24),
                  const Text(
                    'Modo de Preparo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(meal['instructions'] ?? 'Não informado'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroRow(String name, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(name),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
