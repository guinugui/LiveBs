import 'package:flutter/material.dart';
import '../services/direct_meal_plan_service.dart';
import 'meal_plan_details_page.dart';

class MealPlanPage extends StatefulWidget {
  const MealPlanPage({super.key});

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  List<Map<String, dynamic>> _savedPlans = [];
  bool _isLoading = false;
  
  // Credenciais fixas para forçar funcionamento
  static const String _userEmail = 'gui@gmail.com';
  static const String _userPassword = '123123';

  @override
  void initState() {
    super.initState();
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
      ),
    );
  }

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
              ),
            ),
          ],
        ),
      ),
    );
  }

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