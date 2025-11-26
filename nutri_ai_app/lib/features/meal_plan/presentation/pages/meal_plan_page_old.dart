import 'package:flutter/material.dart';
<<<<<<< HEAD
import '../../services/direct_meal_plan_service.dart';
import 'meal_plan_details_page.dart';
=======
import '../../../../core/network/api_service.dart';
>>>>>>> 848763521f357a608b376f621f188f225d66593d

class MealPlanPage extends StatefulWidget {
  const MealPlanPage({super.key});

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
<<<<<<< HEAD
  List<Map<String, dynamic>> _savedPlans = [];
  bool _isLoading = false;
  
  // Credenciais fixas para forçar funcionamento
  static const String _userEmail = 'gui@gmail.com';
  static const String _userPassword = '123123';
=======
  bool _isLoading = true;
  bool _isGenerating = false;
  Map<String, dynamic>? _mealPlan;
>>>>>>> 848763521f357a608b376f621f188f225d66593d

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    print('[MEAL_PLAN_PAGE] 🚀 PÁGINA INICIALIZADA - FORÇANDO BUSCA DIRETA');
    _forcedLoadPlans();
  }

  /// MÉTODO PRINCIPAL - Busca planos DIRETAMENTE do banco de dados
  Future<void> _forcedLoadPlans() async {
    try {
      setState(() => _isLoading = true);
      
      print('[🔥 DIRECT ACCESS] =================================');
      print('[🔥 DIRECT ACCESS] BUSCANDO PLANOS DIRETAMENTE...');
      print('[🔥 DIRECT ACCESS] Usuário: $_userEmail');
      print('[🔥 DIRECT ACCESS] =================================');
      
      final plans = await DirectMealPlanService.fetchPlansDirectly(_userEmail, _userPassword);
      
      print('[🎯 RESULTADO] ${plans.length} planos encontrados no banco!');
      
      setState(() {
        _savedPlans = plans;
      });
      
      // Log detalhado de cada plano encontrado
      if (plans.isNotEmpty) {
        print('[📋 PLANOS ENCONTRADOS]:');
        for (int i = 0; i < plans.length; i++) {
          final plan = plans[i];
          print('  ${i + 1}. Nome: ${plan['plan_name']}');
          print('     ID: ${plan['id']}');
          print('     Número: ${plan['plan_number']}');
          print('     Criado: ${plan['created_at']}');
          print('     ---');
        }
        print('[✅ SUCCESS] PLANOS CARREGADOS E PRONTOS PARA EXIBIÇÃO!');
      } else {
        print('[⚠️ EMPTY] Nenhum plano encontrado - criando um de teste...');
        await _createTestPlanIfNeeded();
      }
      
    } catch (e) {
      print('[❌ ERROR] ERRO CRÍTICO AO BUSCAR PLANOS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ERRO: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } finally {
=======
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
>>>>>>> 848763521f357a608b376f621f188f225d66593d
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

<<<<<<< HEAD
  /// Cria um plano de teste se não existir nenhum
  Future<void> _createTestPlanIfNeeded() async {
    try {
      print('[🛠️ CREATE TEST] Criando plano de teste...');
      
      final result = await DirectMealPlanService.createPlanDirectly(_userEmail, _userPassword);
      
      print('[✅ TEST CREATED] Plano criado: ${result['plan_name']}');
      
      // Recarregar lista após criar
      await _forcedLoadPlans();
      
    } catch (e) {
      print('[❌ TEST ERROR] Erro ao criar plano de teste: $e');
    }
  }

  /// Gera um novo plano alimentar
  Future<void> _generateNewPlan() async {
    try {
      setState(() => _isLoading = true);
      
      print('[🚀 NEW PLAN] Gerando novo plano alimentar...');
      
      final result = await DirectMealPlanService.createPlanDirectly(_userEmail, _userPassword);
      
      print('[✅ CREATED] Novo plano: ${result['plan_name']}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['plan_name']} criado!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Recarregar lista
        await _forcedLoadPlans();
      }
    } catch (e) {
      print('[❌ CREATE ERROR] Erro ao gerar plano: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Deleta um plano
  Future<void> _deletePlan(String planId, String planName) async {
    // Confirmação
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar Plano'),
        content: Text('Tem certeza que deseja deletar "$planName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        print('[🗑️ DELETE] Deletando: $planName ($planId)');
        
        await DirectMealPlanService.deletePlanDirectly(_userEmail, _userPassword, planId);
        
        print('[✅ DELETED] Plano deletado com sucesso');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ "$planName" deletado!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Recarregar lista
          await _forcedLoadPlans();
        }
      } catch (e) {
        print('[❌ DELETE ERROR] Erro ao deletar: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao deletar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Navega para os detalhes do plano
  void _viewPlanDetails(String planId, String planName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MealPlanDetailsPage(
          planId: planId,
          planName: planName,
          userEmail: _userEmail,
          userPassword: _userPassword,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planos Alimentares'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _forcedLoadPlans,
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
                    'Buscando planos no banco...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : _savedPlans.isEmpty
              ? _buildEmptyState()
              : _buildPlansList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _generateNewPlan,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Criar Plano',
          style: TextStyle(color: Colors.white),
        ),
=======
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
>>>>>>> 848763521f357a608b376f621f188f225d66593d
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhum plano encontrado',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Crie seu primeiro plano alimentar personalizado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _generateNewPlan,
              icon: const Icon(Icons.add),
              label: const Text('Criar Primeiro Plano'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
=======
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
>>>>>>> 848763521f357a608b376f621f188f225d66593d
              ),
            ),
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildPlansList() {
    return RefreshIndicator(
      onRefresh: _forcedLoadPlans,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _savedPlans.length,
        itemBuilder: (context, index) {
          final plan = _savedPlans[index];
          final planId = plan['id']?.toString() ?? '';
          final planName = plan['plan_name']?.toString() ?? 'Plano sem nome';
          final createdAt = plan['created_at']?.toString() ?? '';
          final planNumber = plan['plan_number']?.toString() ?? '';

          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    planNumber.padLeft(2, '0'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              title: Text(
                planName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  if (createdAt.isNotEmpty)
                    Text(
                      'Criado em: ${_formatDate(createdAt)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: $planId',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              trailing: PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 20),
                        SizedBox(width: 8),
                        Text('Ver Detalhes'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Deletar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      _viewPlanDetails(planId, planName);
                      break;
                    case 'delete':
                      _deletePlan(planId, planName);
                      break;
                  }
                },
              ),
              onTap: () => _viewPlanDetails(planId, planName),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
=======
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
>>>>>>> 848763521f357a608b376f621f188f225d66593d
