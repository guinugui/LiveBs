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
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPlanDetails();
  }

  Future<void> _loadPlanDetails() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final plan = await DirectMealPlanService.fetchPlanDetailsDirectly(
        widget.userEmail,
        widget.userPassword,
        widget.planId,
      );

      setState(() {
        planData = plan;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      print('Erro ao carregar detalhes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.planName),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlanDetails,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : errorMessage != null
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar plano',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPlanDetails,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (planData == null) {
      return const Center(child: Text('Dados não encontrados'));
    }

    print('🔍 [DEBUG] Estrutura completa dos dados: ${planData.toString()}');

    // Estrutura real: { plan_data: { days: [ { day: 1, meals: [ {type: "breakfast", ...}, ... ] } ] } }
    List<dynamic>? mealsList;

    try {
      // O backend retorna: { plan_data: { days: [ { day: 1, meals: [...] } ] } }
      if (planData!.containsKey('plan_data')) {
        final planContent = planData!['plan_data'];
        print('🔍 [DEBUG] plan_data encontrado: ${planContent.runtimeType}');

        if (planContent is Map && planContent.containsKey('days')) {
          final days = planContent['days'] as List<dynamic>;
          print('🔍 [DEBUG] days encontrado: ${days.length} dias');

          if (days.isNotEmpty &&
              days[0] is Map &&
              days[0].containsKey('meals')) {
            mealsList = days[0]['meals'] as List<dynamic>;
            print('🔍 [DEBUG] meals encontrado: ${mealsList.length} refeições');
          }
        }
      }

      // Fallback: se não encontrou acima, verificar outras estruturas possíveis
      if (mealsList == null) {
        if (planData!.containsKey('meals')) {
          mealsList = planData!['meals'] as List<dynamic>;
        } else if (planData!.containsKey('days')) {
          final days = planData!['days'] as List<dynamic>;
          if (days.isNotEmpty &&
              days[0] is Map &&
              days[0].containsKey('meals')) {
            mealsList = days[0]['meals'] as List<dynamic>;
          }
        }
      }
    } catch (e) {
      print('❌ [ERROR] Erro ao processar estrutura de dados: $e');
    }

    if (mealsList == null || mealsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.orange[300]),
            const SizedBox(height: 16),
            const Text('Nenhuma refeição encontrada'),
            const SizedBox(height: 8),
            Text('Estrutura de dados: ${planData.toString()}'),
          ],
        ),
      );
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
                  '🍽️ Plano Alimentar Personalizado',
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

          // Meals - agora usando mealsList
          ...mealsList.map<Widget>((meal) => _buildMealCard(meal)).toList(),
        ],
      ),
    );
  }

  Widget _buildMealCard(dynamic mealData) {
    final meal = mealData as Map<String, dynamic>;
    final mealName = meal['name']?.toString() ?? 'Refeição';
    final mealTime = meal['time']?.toString() ?? '';

    String title;
    IconData icon;
    Color color;

    // Determinar ícone e cor baseado no nome da refeição
    String lowerName = mealName.toLowerCase();
    if (lowerName.contains('café') || lowerName.contains('manhã')) {
      title = '☀️ $mealName';
      icon = Icons.wb_sunny;
      color = Colors.orange;
    } else if (lowerName.contains('almoço')) {
      title = '🌞 $mealName';
      icon = Icons.lunch_dining;
      color = Colors.green;
    } else if (lowerName.contains('lanche') && lowerName.contains('tarde')) {
      title = '🥪 $mealName';
      icon = Icons.local_cafe;
      color = Colors.purple;
    } else if (lowerName.contains('jantar')) {
      title = '🌙 $mealName';
      icon = Icons.dinner_dining;
      color = Colors.indigo;
    } else if (lowerName.contains('lanche') && lowerName.contains('manhã')) {
      title = '🥯 $mealName';
      icon = Icons.bakery_dining;
      color = Colors.amber;
    } else if (lowerName.contains('ceia')) {
      title = '🌃 $mealName';
      icon = Icons.nightlight;
      color = Colors.deepPurple;
    } else {
      title = '🍴 $mealName';
      icon = Icons.restaurant;
      color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mealTime.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          mealTime,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildAllFoods(meal['foods'] as List<dynamic>?),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllFoods(List<dynamic>? foods) {
    if (foods == null || foods.isEmpty)
      return const Text('Nenhum alimento encontrado');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🍽️ Alimentos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.deepOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.deepOrange.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: foods.map<Widget>((food) {
              if (food is Map<String, dynamic>) {
                final name = food['name']?.toString() ?? 'Alimento';
                final quantity = food['quantity']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 8,
                        color: Colors.deepOrange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$name - $quantity',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    food.toString(),
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }
            }).toList(),
          ),
        ),
      ],
    );
  }
}
