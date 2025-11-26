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
    print(
      '[DETAILS] 📋 Carregando detalhes do plano: ${widget.planName} (${widget.planId})',
    );
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
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
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
              style: TextStyle(color: Colors.grey[600]),
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
          // Header do plano
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _planDetails!['plan_name'] ?? 'Plano Alimentar',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Plano #${_planDetails!['plan_number'] ?? ''}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            if (_planDetails!['created_at'] != null)
                              Text(
                                'Criado em: ${_formatDate(_planDetails!['created_at'])}',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
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
          ),

          const SizedBox(height: 16),

          // Conteúdo do plano
          _buildPlanContent(planData),
        ],
      ),
    );
  }

  Widget _buildPlanContent(dynamic planData) {
    print('[DETAILS] 📊 Renderizando dados do plano: ${planData.runtimeType}');
    print('[DETAILS] 📄 Conteúdo: ${planData.toString().substring(0, 200)}...');
    
    // Converte qualquer tipo de dado para string para análise
    String planText = '';
    if (planData is String) {
      planText = planData;
    } else if (planData is Map || planData is List) {
      planText = planData.toString();
    } else {
      planText = planData.toString();
    }

    // Parse inteligente do plano
    final parsedSections = _parseSmartMealPlan(planText);
    
    if (parsedSections.isEmpty) {
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
                    'Plano em Processamento',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'O plano alimentar está sendo preparado. Tente novamente em alguns instantes.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: parsedSections.map((section) => _buildPlanSection(section)).toList(),
    );
  }

  List<Map<String, dynamic>> _parseSmartMealPlan(String planText) {
    final sections = <Map<String, dynamic>>[];
    
    try {
      // Limpa o texto de escapes
      String cleanText = planText
          .replaceAll(RegExp(r'\\n'), '\n')
          .replaceAll(RegExp(r'\\_'), '_')
          .replaceAll(RegExp(r'\\'), '')
          .trim();
          
      print('[PARSER] 🧹 Texto limpo: ${cleanText.substring(0, 300)}...');
      
      // Cria um plano modelo unificado para 7 dias
      final modelMeals = _extractModelMealsFromContent(cleanText);
      
      if (modelMeals.isNotEmpty) {
        sections.add({
          'type': 'model_plan',
          'title': '🗓️ Plano Modelo para 7 Dias',
          'description': 'Siga este modelo todos os dias, variando os alimentos dentro de cada grupo.',
          'meals': modelMeals,
        });
      }
      
      // Fallback: exibe como texto formatado
      if (sections.isEmpty) {
        sections.add({
          'type': 'text',
          'title': '📄 Conteúdo do Plano',
          'content': _formatRawText(planText),
        });
      }
      
    } catch (e) {
      print('[PARSER] ❌ Erro no parsing: $e');
      sections.add({
        'type': 'error',
        'title': '⚠️ Erro de Processamento',
        'content': 'Não foi possível processar os dados do plano.',
      });
    }
    
    return sections;
  }
  
  List<Map<String, dynamic>> _extractModelMealsFromContent(String content) {
    final meals = <Map<String, dynamic>>[];
    
    try {
      // Tenta fazer parse do JSON diretamente se o conteúdo já estiver estruturado
      Map<String, dynamic>? planData;
      
      if (content.startsWith('{')) {
        try {
          planData = _parseJsonFromString(content);
        } catch (e) {
          print('[PARSER] ❌ Erro no parse JSON: $e');
        }
      }
      
      if (planData != null && planData.containsKey('meals')) {
        final mealsData = planData['meals'] as List;
        
        for (final mealData in mealsData) {
          final mealMap = mealData as Map<String, dynamic>;
          final type = mealMap['type'] as String;
          
          final mealName = _getMealNameFromType(type);
          final foodGroups = _extractFoodGroupsFromMealMap(mealMap);
          
          if (foodGroups.isNotEmpty) {
            meals.add({
              'name': mealName,
              'icon': _getMealIcon(mealName),
              'foodGroups': foodGroups,
              'instructions': _getMealInstructions(mealName),
            });
            print('[PARSER] 🍽️ $mealName: ${foodGroups.length} grupos alimentares');
          }
        }
      } else {
        // Fallback para regex se não conseguir fazer parse JSON
        final mealPatterns = {
          'Café da Manhã': RegExp(r'type:\s*breakfast[^}]*}', caseSensitive: false),
          'Almoço': RegExp(r'type:\s*lunch[^}]*}', caseSensitive: false),
          'Lanche': RegExp(r'type:\s*afternoon_snack[^}]*}', caseSensitive: false),
          'Jantar': RegExp(r'type:\s*dinner[^}]*}', caseSensitive: false),
        };
        
        for (final entry in mealPatterns.entries) {
          final mealName = entry.key;
          final pattern = entry.value;
          final match = pattern.firstMatch(content);
          
          if (match != null) {
            final mealContent = match.group(0) ?? '';
            final foodGroups = _extractFoodGroupsFromMeal(mealContent);
            
            if (foodGroups.isNotEmpty) {
              meals.add({
                'name': mealName,
                'icon': _getMealIcon(mealName),
                'foodGroups': foodGroups,
                'instructions': _getMealInstructions(mealName),
              });
            }
          }
        }
      }
    } catch (e) {
      print('[PARSER] ❌ Erro geral: $e');
    }
    
    return meals;
  }
  
  List<Map<String, dynamic>> _extractMealsFromDayContent(String content) {
    final meals = <Map<String, dynamic>>[];
    
    // Padrões de refeições
    final mealPatterns = {
      'Café da Manhã': RegExp(r'type:\s*breakfast[^}]*}', caseSensitive: false),
      'Almoço': RegExp(r'type:\s*lunch[^}]*}', caseSensitive: false),
      'Jantar': RegExp(r'type:\s*dinner[^}]*}', caseSensitive: false),
      'Lanche': RegExp(r'type:\s*afternoon_snack[^}]*}', caseSensitive: false),
    };
    
    for (final entry in mealPatterns.entries) {
      final mealName = entry.key;
      final pattern = entry.value;
      final matches = pattern.allMatches(content);
      
      for (final match in matches) {
        final mealContent = match.group(0) ?? '';
        final foods = _extractFoodsFromMealContent(mealContent);
        
        if (foods.isNotEmpty) {
          meals.add({
            'name': mealName,
            'icon': _getMealIcon(mealName),
            'foods': foods,
          });
          print('[PARSER] 🍽️ $mealName: ${foods.length} alimentos');
        }
      }
    }
    
    return meals;
  }
  
  Map<String, dynamic>? _parseJsonFromString(String jsonString) {
    try {
      // Remove quebras de linha e escapes desnecessários
      final cleanJson = jsonString
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .trim();
      
      // Tenta encontrar o JSON dentro da string
      final startIndex = cleanJson.indexOf('{');
      final lastIndex = cleanJson.lastIndexOf('}');
      
      if (startIndex != -1 && lastIndex != -1 && lastIndex > startIndex) {
        final jsonPart = cleanJson.substring(startIndex, lastIndex + 1);
        
        // Converte para Map usando eval simples
        return _evaluateMapString(jsonPart);
      }
    } catch (e) {
      print('[PARSER] ❌ Erro no parse: $e');
    }
    return null;
  }
  
  Map<String, dynamic>? _evaluateMapString(String mapString) {
    try {
      // Remove chaves externas
      String content = mapString.trim();
      if (content.startsWith('{') && content.endsWith('}')) {
        content = content.substring(1, content.length - 1);
      }
      
      final result = <String, dynamic>{};
      
      // Procura por 'meals:' seguido de uma lista
      final mealsMatch = RegExp(r'meals:\s*\[(.*?)\]\s*}?\s*$', dotAll: true).firstMatch(content);
      if (mealsMatch != null) {
        final mealsContent = mealsMatch.group(1) ?? '';
        result['meals'] = _parseMealsList(mealsContent);
      }
      
      return result.isNotEmpty ? result : null;
    } catch (e) {
      print('[PARSER] ❌ Erro no eval: $e');
      return null;
    }
  }
  
  List<Map<String, dynamic>> _parseMealsList(String mealsContent) {
    final meals = <Map<String, dynamic>>[];
    
    // Encontra cada meal individual usando regex
    final mealPattern = RegExp(r'\{([^{}]+(?:\{[^{}]*\}[^{}]*)*)\}', multiLine: true);
    final mealMatches = mealPattern.allMatches(mealsContent);
    
    for (final match in mealMatches) {
      final mealContent = match.group(1) ?? '';
      final mealMap = _parseSingleMeal(mealContent);
      if (mealMap.isNotEmpty) {
        meals.add(mealMap);
      }
    }
    
    return meals;
  }
  
  Map<String, dynamic> _parseSingleMeal(String mealContent) {
    final meal = <String, dynamic>{};
    
    // Extrai type
    final typeMatch = RegExp(r'type:\s*([^,}]+)').firstMatch(mealContent);
    if (typeMatch != null) {
      meal['type'] = typeMatch.group(1)?.trim();
    }
    
    // Extrai arrays de alimentos
    final arrayPatterns = {
      'carbs_foods': RegExp(r'carbs_foods:\s*\[([^\]]+)\]'),
      'protein_foods': RegExp(r'protein_foods:\s*\[([^\]]+)\]'),
      'fat_foods': RegExp(r'fat_foods:\s*\[([^\]]+)\]'),
      'vegetables': RegExp(r'vegetables:\s*\[([^\]]+)\]'),
    };
    
    for (final entry in arrayPatterns.entries) {
      final match = entry.value.firstMatch(mealContent);
      if (match != null) {
        final items = match.group(1)?.split(',').map((e) => e.trim().replaceAll(RegExp(r'["\']'), '')).toList() ?? [];
        meal[entry.key] = items.where((item) => item.isNotEmpty).toList();
      }
    }
    
    return meal;
  }
  
  String _getMealNameFromType(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return 'Café da Manhã';
      case 'lunch':
        return 'Almoço';
      case 'afternoon_snack':
        return 'Lanche';
      case 'dinner':
        return 'Jantar';
      default:
        return type;
    }
  }
  
  List<Map<String, dynamic>> _extractFoodGroupsFromMealMap(Map<String, dynamic> mealMap) {
    final foodGroups = <Map<String, dynamic>>[];
    
    final categoryInfo = {
      'carbs_foods': {
        'name': 'Carboidratos',
        'amount': '150-200g',
        'color': 0xFFFFB74D, // Laranja
      },
      'protein_foods': {
        'name': 'Proteínas',
        'amount': '100-150g',
        'color': 0xFFE57373, // Vermelho
      },
      'fat_foods': {
        'name': 'Gorduras Boas',
        'amount': '1-2 colheres',
        'color': 0xFF81C784, // Verde
      },
      'vegetables': {
        'name': 'Verduras/Frutas',
        'amount': 'À vontade',
        'color': 0xFF66BB6A, // Verde escuro
      },
    };
    
    for (final entry in categoryInfo.entries) {
      final category = entry.key;
      final info = entry.value as Map<String, dynamic>;
      
      if (mealMap.containsKey(category)) {
        final foods = mealMap[category] as List?;
        if (foods != null && foods.isNotEmpty) {
          foodGroups.add({
            'category': category,
            'name': info['name'],
            'amount': info['amount'],
            'examples': foods,
            'color': info['color'],
          });
        }
      }
    }
    
    return foodGroups;
  }
  
  List<Map<String, dynamic>> _extractFoodGroupsFromMeal(String content) {
    final foodGroups = <Map<String, dynamic>>[];
    
    final categoryInfo = {
      'carbs_foods': {
        'name': 'Carboidratos',
        'amount': _getMealPortionSize('carbs'),
        'examples': ['arroz', 'feijão', 'batata', 'macarrão', 'pão integral', 'aveia'],
        'color': 0xFFFFB74D,
      },
      'protein_foods': {
        'name': 'Proteínas',
        'amount': _getMealPortionSize('protein'),
        'examples': ['frango', 'peixe', 'ovo', 'carne', 'queijo', 'iogurte'],
        'color': 0xFFE57373,
      },
      'fat_foods': {
        'name': 'Gorduras Boas',
        'amount': _getMealPortionSize('fat'),
        'examples': ['azeite', 'abacate', 'castanhas', 'amendoim', 'azeite de oliva'],
        'color': 0xFF81C784,
      },
      'vegetables': {
        'name': 'Verduras/Legumes',
        'amount': _getMealPortionSize('vegetables'),
        'examples': ['alface', 'tomate', 'cenoura', 'brócolis', 'abobrinha', 'pepino'],
        'color': 0xFF66BB6A,
      },
    };
    
    for (final entry in categoryInfo.entries) {
      final category = entry.key;
      final info = entry.value as Map<String, dynamic>;
      
      final regex = RegExp(
        '$category:\\s*\\[([^\\]]+)\\]',
        caseSensitive: false,
      );
      
      final match = regex.firstMatch(content);
      if (match != null) {
        foodGroups.add({
          'category': category,
          'name': info['name'],
          'amount': info['amount'],
          'examples': info['examples'],
          'color': info['color'],
        });
      }
    }
    
    return foodGroups;
  }
  
  List<String> _extractFoodsFromMealContent(String content) {
    final foods = <String>[];
    
    // Padrões para categorias de alimentos
    final foodCategories = [
      'fat_foods', 'protein_foods', 'carbs_foods',
      'vegetables', 'fruits', 'dairy_foods'
    ];
    
    for (final category in foodCategories) {
      final regex = RegExp(
        '$category:\\s*\\[([^\\]]+)\\]',
        caseSensitive: false,
      );
      
      final matches = regex.allMatches(content);
      for (final match in matches) {
        final foodList = match.group(1) ?? '';
        final individualFoods = foodList
            .split(',')
            .map((f) => f.trim().replaceAll(RegExp(r'["\s]'), ''))
            .where((f) => f.isNotEmpty)
            .toList();
            
        foods.addAll(individualFoods);
      }
    }
    
    return foods;
  }
  
  String _getMealPortionSize(String category) {
    switch (category) {
      case 'carbs':
        return '150-200g';
      case 'protein':
        return '100-150g';
      case 'fat':
        return '1-2 colheres';
      case 'vegetables':
        return 'À vontade';
      case 'fruits':
        return '1-2 unidades';
      default:
        return 'A gosto';
    }
  }
  
  String _getMealInstructions(String mealName) {
    switch (mealName) {
      case 'Café da Manhã':
        return 'Refeição importante para começar o dia com energia.';
      case 'Almoço':
        return 'Refeição principal. Combine todos os grupos alimentares.';
      case 'Lanche':
        return 'Mantenha a energia entre as refeições principais.';
      case 'Jantar':
        return 'Refeição mais leve, priorizando proteínas e vegetais.';
      default:
        return 'Siga as porções recomendadas para cada grupo alimentar.';
    }
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
  
  String _formatRawText(String text) {
    return text
        .replaceAll(RegExp(r'\{[^:]*:'), '\n• ')
        .replaceAll(RegExp(r'[{}\[\]]'), '')
        .replaceAll(',', '\n• ')
        .replaceAll(RegExp(r'\n\s*\n'), '\n')
        .trim();
  }
  
  Widget _buildPlanSection(Map<String, dynamic> section) {
    final type = section['type'] as String;
    final title = section['title'] as String;
    
    if (type == 'model_plan') {
      final meals = section['meals'] as List<Map<String, dynamic>>;
      final description = section['description'] as String;
      return _buildModelPlanSection(title, description, meals);
    } else if (type == 'day') {
      final meals = section['meals'] as List<Map<String, dynamic>>;
      return _buildDaySection(title, meals);
    } else if (type == 'text') {
      final content = section['content'] as String;
      return _buildTextSection(title, content);
    } else if (type == 'error') {
      final content = section['content'] as String;
      return _buildErrorSection(title, content);
    }
    
    return const SizedBox();
  }
  
  Widget _buildModelPlanSection(String title, String description, List<Map<String, dynamic>> meals) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            ...meals.map((meal) => _buildModelMealCard(meal)).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDaySection(String title, List<Map<String, dynamic>> meals) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            ...meals.map((meal) => _buildMealCard(meal)).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildModelMealCard(Map<String, dynamic> meal) {
    final name = meal['name'] as String;
    final icon = meal['icon'] as String;
    final foodGroups = meal['foodGroups'] as List<Map<String, dynamic>>;
    final instructions = meal['instructions'] as String;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[25]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    Text(
                      instructions,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...foodGroups.map((group) => _buildFoodGroupCard(group)).toList(),
        ],
      ),
    );
  }
  
  Widget _buildFoodGroupCard(Map<String, dynamic> group) {
    final name = group['name'] as String? ?? 'Grupo Alimentar';
    final amount = group['amount'] as String? ?? 'Varia';
    final examples = (group['examples'] as List?)?.cast<String>() ?? <String>[];
    final colorValue = group['color'] as int? ?? 0xFF81C784;
    final color = Color(colorValue);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  amount,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
          if (examples.isNotEmpty) ..[
            const SizedBox(height: 6),
            Text(
              'Exemplos: ${examples.take(6).join(', ')}${examples.length > 6 ? '...' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildMealCard(Map<String, dynamic> meal) {
    final name = meal['name'] as String;
    final icon = meal['icon'] as String;
    final foods = meal['foods'] as List<String>;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: foods.map((food) => Chip(
              label: Text(
                food,
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: Colors.white,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            )).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextSection(String title, String content) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorSection(String title, String content) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
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
