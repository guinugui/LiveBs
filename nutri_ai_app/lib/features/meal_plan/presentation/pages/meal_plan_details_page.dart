import 'package:flutter/material.dart';
import '../../services/direct_meal_plan_service.dart';

class MealPlanDetailsPage extends StatefulWidget {
  final String planId;
  final String planName;
  final String userEmail;
  final String userPassword;

  const MealPlanDetailsPage({
    super.key,
    required this.planId,
    required this.planName,
    required this.userEmail,
    required this.userPassword,
  });

  @override
  State<MealPlanDetailsPage> createState() => _MealPlanDetailsPageState();
}

class _MealPlanDetailsPageState extends State<MealPlanDetailsPage> {
  Map<String, dynamic>? planData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadPlanData();
  }

  Future<void> _loadPlanData() async {
    try {
      final data = await DirectMealPlanService.fetchPlanDetailsDirectly(
        widget.userEmail,
        widget.userPassword,
        widget.planId,
      );
      setState(() {
        planData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.planName),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Erro: $error', style: const TextStyle(color: Colors.red)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    print('[NEW] 📊 Plan data keys: ${planData?.keys.toList()}');
    print('[NEW] 📊 Full plan data: $planData');
    
    if (planData == null) {
      return const Center(child: Text('Dados não encontrados'));
    }

    // Verificar estrutura dos dados
    List<dynamic> meals = [];
    
    if (planData!.containsKey('meals')) {
      meals = planData!['meals'] as List<dynamic>;
    } else if (planData!.containsKey('plan_data')) {
      final planDataContent = planData!['plan_data'];
      if (planDataContent is Map && planDataContent.containsKey('meals')) {
        meals = planDataContent['meals'] as List<dynamic>;
      }
    }
    
    print('[NEW] 🍽️ Found ${meals.length} meals');
    
    if (meals.isEmpty) {
      return const Center(child: Text('Nenhuma refeição encontrada'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              children: [
                Icon(Icons.restaurant_menu, color: Colors.white, size: 40),
                SizedBox(height: 12),
                Text(
                  '🍽️ Plano Modelo para 7 Dias',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Siga este modelo todos os dias, variando os alimentos dentro de cada grupo.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Meals
          ...meals.map<Widget>((meal) => _buildMealCard(meal)).toList(),
        ],
      ),
    );
  }

  Widget _buildMealCard(dynamic mealData) {
    final meal = mealData as Map<String, dynamic>;
    final type = meal['type'] as String;
    
    String title;
    IconData icon;
    Color color;
    
    switch (type) {
      case 'breakfast':
        title = '☀️ Café da Manhã';
        icon = Icons.wb_sunny;
        color = const Color(0xFFFF9800);
        break;
      case 'lunch':
        title = '🍽️ Almoço';
        icon = Icons.restaurant;
        color = const Color(0xFF2196F3);
        break;
      case 'afternoon_snack':
        title = '☕ Lanche da Tarde';
        icon = Icons.local_cafe;
        color = const Color(0xFF9C27B0);
        break;
      case 'dinner':
        title = '🌙 Jantar';
        icon = Icons.nights_stay;
        color = const Color(0xFF673AB7);
        break;
      default:
        title = '🍴 Refeição';
        icon = Icons.fastfood;
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Food Groups
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Carboidratos
                _buildFoodGroupRow(
                  '🌾 Carboidratos',
                  '150-200g',
                  meal['carbs_foods'] as List<dynamic>? ?? [],
                  const Color(0xFFFF9800),
                ),
                const SizedBox(height: 16),

                // Proteínas
                _buildFoodGroupRow(
                  '🥩 Proteínas',
                  '100-150g',
                  meal['protein_foods'] as List<dynamic>? ?? [],
                  const Color(0xFFF44336),
                ),
                const SizedBox(height: 16),

                // Gorduras
                _buildFoodGroupRow(
                  '🫒 Gorduras',
                  '1-2 colheres',
                  meal['fat_foods'] as List<dynamic>? ?? [],
                  const Color(0xFF9C27B0),
                ),

                // Verduras/Frutas (se houver)
                if ((meal['vegetables'] as List<dynamic>? ?? []).isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildFoodGroupRow(
                    '🥬 Verduras/Frutas',
                    'À vontade',
                    meal['vegetables'] as List<dynamic>? ?? [],
                    const Color(0xFF4CAF50),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodGroupRow(String title, String quantity, List<dynamic> foods, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Quantity
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  quantity,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Food List
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: foods.map<Widget>((food) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  food.toString(),
                  style: TextStyle(
                    fontSize: 13,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}