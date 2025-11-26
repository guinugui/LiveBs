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
  Map<String, dynamic>? _planDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('[DETAILS] 📋 Carregando detalhes do plano: ${widget.planName} (${widget.planId})');
    _loadPlanDetails();
  }

  Future<void> _loadPlanDetails() async {
    try {
      setState(() => _isLoading = true);
      
      print('[DETAILS] 🔍 Buscando detalhes diretamente...');
      
      final details = await DirectMealPlanService.fetchPlanDetailsDirectly(
        widget.userEmail,
        widget.userPassword,
        widget.planId,
      );
      
      print('[DETAILS] ✅ Detalhes carregados: ${details['plan_name']}');
      
      setState(() {
        _planDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      print('[DETAILS] ❌ Erro ao carregar detalhes: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar detalhes: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.planName),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlanDetails,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'Carregando detalhes...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : _planDetails == null
              ? _buildErrorState()
              : _buildPlanDetails(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar plano',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Não foi possível carregar os detalhes do plano',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPlanDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanDetails() {
    final planData = _planDetails!['plan_data'];
    
    if (planData == null) {
      return const Center(
        child: Text(
          'Dados do plano não encontrados',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlanHeader(),
          const SizedBox(height: 16),
          _buildPlanContent(planData),
        ],
      ),
    );
  }

  Widget _buildPlanHeader() {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[400]!, Colors.green[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🗓️ Plano Modelo para 7 Dias',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Siga este modelo todos os dias, variando os alimentos dentro de cada grupo.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanContent(dynamic planData) {
    print('[DETAILS] 📊 Processando plano: ${planData.runtimeType}');
    
    // Tenta extrair meals do plano
    List<Map<String, dynamic>> meals = [];
    
    try {
      if (planData is Map<String, dynamic> && planData.containsKey('meals')) {
        final mealsData = planData['meals'] as List;
        meals = mealsData.cast<Map<String, dynamic>>();
      } else if (planData is String) {
        // Tenta fazer parse do JSON string
        meals = _extractMealsFromString(planData);
      }
    } catch (e) {
      print('[DETAILS] ❌ Erro ao processar: $e');
    }

    if (meals.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Plano Básico',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                planData.toString(),
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: meals.map((meal) => _buildMealCard(meal)).toList(),
    );
  }

  List<Map<String, dynamic>> _extractMealsFromString(String content) {
    final meals = <Map<String, dynamic>>[];
    
    // Padrões de refeições no novo formato
    final mealTypes = {
      'breakfast': 'Café da Manhã',
      'lunch': 'Almoço', 
      'afternoon_snack': 'Lanche',
      'dinner': 'Jantar',
    };

    for (final entry in mealTypes.entries) {
      final type = entry.key;
      final name = entry.value;
      
      // Procura por este tipo de refeição
      final pattern = RegExp('type:\\s*$type[^}]*(?:\\{[^}]*\\}[^}]*)*', caseSensitive: false);
      final match = pattern.firstMatch(content);
      
      if (match != null) {
        final mealContent = match.group(0) ?? '';
        final foodGroups = _extractFoodGroupsFromMealContent(mealContent);
        
        meals.add({
          'name': name,
          'icon': _getMealIcon(name),
          'foodGroups': foodGroups,
        });
      }
    }

    return meals;
  }

  List<Map<String, dynamic>> _extractFoodGroupsFromMealContent(String content) {
    final foodGroups = <Map<String, dynamic>>[];
    
    final categoryInfo = {
      'carbs_foods': {
        'name': 'Carboidratos',
        'amount': '150-200g',
        'color': Colors.orange[300]!,
        'icon': '🌾',
      },
      'protein_foods': {
        'name': 'Proteínas',
        'amount': '100-150g',
        'color': Colors.red[300]!,
        'icon': '🥩',
      },
      'fat_foods': {
        'name': 'Gorduras Boas',
        'amount': '1-2 colheres',
        'color': Colors.green[300]!,
        'icon': '🥑',
      },
      'vegetables': {
        'name': 'Verduras/Frutas',
        'amount': 'À vontade',
        'color': Colors.green[400]!,
        'icon': '🥬',
      },
    };

    for (final entry in categoryInfo.entries) {
      final category = entry.key;
      final info = entry.value as Map<String, dynamic>;
      
      final regex = RegExp('$category:\\s*\\[([^\\]]+)\\]', caseSensitive: false);
      final match = regex.firstMatch(content);
      
      if (match != null) {
        final foodsStr = match.group(1) ?? '';
        final foods = foodsStr
            .split(',')
            .map((f) => f.trim().replaceAll(RegExp(r'["\']'), ''))
            .where((f) => f.isNotEmpty)
            .take(8) // Limite de 8 alimentos por categoria
            .toList();
            
        if (foods.isNotEmpty) {
          foodGroups.add({
            'name': info['name'],
            'amount': info['amount'],
            'color': info['color'],
            'icon': info['icon'],
            'foods': foods,
          });
        }
      }
    }

    return foodGroups;
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    final name = meal['name'] as String;
    final icon = meal['icon'] as String;
    final foodGroups = (meal['foodGroups'] as List).cast<Map<String, dynamic>>();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...foodGroups.map((group) => _buildFoodGroupCard(group)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodGroupCard(Map<String, dynamic> group) {
    final name = group['name'] as String;
    final amount = group['amount'] as String;
    final color = group['color'] as Color;
    final icon = group['icon'] as String;
    final foods = (group['foods'] as List).cast<String>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  amount,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: foods.map((food) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                food,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  String _getMealIcon(String mealName) {
    switch (mealName.toLowerCase()) {
      case 'café da manhã':
        return '🌅';
      case 'almoço':
        return '🍽️';
      case 'jantar':
        return '🌙';
      case 'lanche':
        return '🥪';
      default:
        return '🍴';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}