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
      
      // Busca por dias
      final dayPattern = RegExp(r'day:\s*(\d+)', caseSensitive: false);
      final dayMatches = dayPattern.allMatches(cleanText).toList();
      
      if (dayMatches.isNotEmpty) {
        print('[PARSER] 📅 Encontrados ${dayMatches.length} dias');
        
        for (int i = 0; i < dayMatches.length; i++) {
          final match = dayMatches[i];
          final dayNumber = match.group(1) ?? '1';
          
          // Define início e fim do conteúdo do dia
          final dayStart = match.start;
          final dayEnd = i + 1 < dayMatches.length 
              ? dayMatches[i + 1].start 
              : cleanText.length;
              
          final dayContent = cleanText.substring(dayStart, dayEnd);
          print('[PARSER] 📋 Dia $dayNumber: ${dayContent.substring(0, 150)}...');
          
          final meals = _extractMealsFromDayContent(dayContent);
          
          if (meals.isNotEmpty) {
            sections.add({
              'type': 'day',
              'title': '📅 Dia $dayNumber',
              'meals': meals,
            });
          }
        }
      }
      
      // Se não encontrou dias, tenta extrair refeições diretamente
      if (sections.isEmpty) {
        print('[PARSER] 🔍 Buscando refeições sem estrutura de dias...');
        final meals = _extractMealsFromDayContent(cleanText);
        if (meals.isNotEmpty) {
          sections.add({
            'type': 'day',
            'title': '📋 Plano Alimentar',
            'meals': meals,
          });
        }
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
    
    if (type == 'day') {
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
