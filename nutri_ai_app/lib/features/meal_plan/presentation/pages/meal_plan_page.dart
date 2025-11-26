import 'package:flutter/material.dart';
import '../../services/direct_meal_plan_service.dart';
import 'meal_plan_details_page.dart';

class MealPlanPage extends StatefulWidget {
  const MealPlanPage({super.key});

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _savedPlans = [];
  bool _isLoading = true;
  bool _isCreating = false;
  
  // Credenciais do usuário logado
  static const String _userEmail = 'gui@gmail.com';
  static const String _userPassword = '123123';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Configurar animações
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Buscar planos ao inicializar
    _loadMealPlans();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 🔍 BUSCA TODOS OS PLANOS DO USUÁRIO NO BANCO DE DADOS
  Future<void> _loadMealPlans() async {
    setState(() => _isLoading = true);
    
    try {
      print('🔍 [MEAL_PLANS] Buscando planos para: $_userEmail');
      
      final plans = await DirectMealPlanService.fetchPlansDirectly(_userEmail, _userPassword);
      
      print('📊 [MEAL_PLANS] ${plans.length} planos encontrados');
      
      // Ordenar por data de criação (mais recente primeiro)
      plans.sort((a, b) {
        final aDate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
        final bDate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
        return bDate.compareTo(aDate);
      });
      
      setState(() {
        _savedPlans = plans;
        _isLoading = false;
      });
      
      // Iniciar animação quando os dados carregarem
      _animationController.forward();
      
      // Log dos planos encontrados
      for (int i = 0; i < plans.length; i++) {
        final plan = plans[i];
        print('📋 [PLAN_${i + 1}] ${plan['plan_name']} (${plan['id']})');
      }
      
    } catch (e) {
      print('❌ [ERROR] Erro ao buscar planos: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        _showErrorSnackBar('Erro ao carregar planos: $e');
      }
    }
  }

  /// ➕ CRIAR NOVO PLANO ALIMENTAR
  Future<void> _createNewMealPlan() async {
    setState(() => _isCreating = true);
    
    try {
      print('🚀 [CREATE] Criando novo plano alimentar...');
      
      final result = await DirectMealPlanService.createPlanDirectly(_userEmail, _userPassword);
      
      print('✅ [CREATE] Plano criado: ${result['plan_name']}');
      
      // Mostrar sucesso
      if (mounted) {
        _showSuccessSnackBar('${result['plan_name']} criado com sucesso!');
      }
      
      // Recarregar lista
      await _loadMealPlans();
      
    } catch (e) {
      print('❌ [CREATE_ERROR] Erro ao criar plano: $e');
      if (mounted) {
        _showErrorSnackBar('Erro ao criar plano: $e');
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }

  /// 🗑️ DELETAR PLANO
  Future<void> _deleteMealPlan(Map<String, dynamic> plan) async {
    final planId = plan['id']?.toString() ?? '';
    final planName = plan['plan_name']?.toString() ?? 'Plano';
    
    // Confirmar deleção
    final confirmed = await _showDeleteConfirmation(planName);
    if (!confirmed) return;
    
    try {
      print('🗑️ [DELETE] Deletando: $planName ($planId)');
      
      await DirectMealPlanService.deletePlanDirectly(_userEmail, _userPassword, planId);
      
      print('✅ [DELETE] Plano deletado com sucesso');
      
      if (mounted) {
        _showSuccessSnackBar('$planName deletado!');
      }
      
      // Recarregar lista
      await _loadMealPlans();
      
    } catch (e) {
      print('❌ [DELETE_ERROR] Erro ao deletar: $e');
      if (mounted) {
        _showErrorSnackBar('Erro ao deletar plano: $e');
      }
    }
  }

  /// 👁️ VER DETALHES DO PLANO
  void _viewPlanDetails(Map<String, dynamic> plan) {
    final planId = plan['id']?.toString() ?? '';
    final planName = plan['plan_name']?.toString() ?? 'Plano';
    
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
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildCreateButton(),
    );
  }

  /// 📱 APP BAR
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Meus Planos Alimentares',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.green[600],
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _isLoading ? null : _loadMealPlans,
          tooltip: 'Atualizar',
        ),
      ],
    );
  }

  /// 📄 CORPO DA PÁGINA
  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_savedPlans.isEmpty) {
      return _buildEmptyState();
    }
    
    return _buildPlansList();
  }

  /// ⏳ ESTADO DE CARREGAMENTO
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Buscando seus planos...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Conectando ao banco de dados',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 ESTADO VAZIO
  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  size: 64,
                  color: Colors.green[400],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Nenhum plano criado ainda',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Crie seu primeiro plano alimentar personalizado com IA',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _isCreating ? null : _createNewMealPlan,
                icon: _isCreating 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(_isCreating ? 'Criando...' : 'Criar Primeiro Plano'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 LISTA DE PLANOS
  Widget _buildPlansList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadMealPlans,
        color: Colors.green[600],
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _savedPlans.length + 1, // +1 para o header
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildListHeader();
            }
            
            final plan = _savedPlans[index - 1];
            return _buildPlanCard(plan, index - 1);
          },
        ),
      ),
    );
  }

  /// 📊 CABEÇALHO DA LISTA
  Widget _buildListHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[400]!, Colors.green[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seus Planos Alimentares',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_savedPlans.length} plano${_savedPlans.length != 1 ? 's' : ''} encontrado${_savedPlans.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 CARD DE PLANO INDIVIDUAL
  Widget _buildPlanCard(Map<String, dynamic> plan, int index) {
    final planName = plan['plan_name']?.toString() ?? 'Plano sem nome';
    final planNumber = plan['plan_number']?.toString() ?? '0';
    final createdAt = plan['created_at']?.toString() ?? '';
    final planId = plan['id']?.toString() ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _viewPlanDetails(plan),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Número do plano
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[400]!, Colors.green[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      planNumber.padLeft(2, '0'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Informações do plano
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (createdAt.isNotEmpty)
                        Text(
                          'Criado em ${_formatDate(createdAt)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: $planId',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Menu de ações
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 20, color: Colors.blue),
                          SizedBox(width: 12),
                          Text('Ver Detalhes'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Deletar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'view':
                        _viewPlanDetails(plan);
                        break;
                      case 'delete':
                        _deleteMealPlan(plan);
                        break;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ➕ BOTÃO DE CRIAR NOVO PLANO
  Widget _buildCreateButton() {
    return FloatingActionButton.extended(
      onPressed: _isCreating || _isLoading ? null : _createNewMealPlan,
      backgroundColor: Colors.green[600],
      icon: _isCreating 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.add, color: Colors.white),
      label: Text(
        _isCreating ? 'Criando...' : 'Novo Plano',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 🗑️ CONFIRMAÇÃO DE DELEÇÃO
  Future<bool> _showDeleteConfirmation(String planName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Deletar Plano',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Tem certeza que deseja deletar "$planName"?\n\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Deletar'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// ✅ SNACKBAR DE SUCESSO
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// ❌ SNACKBAR DE ERRO
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// 📅 FORMATAÇÃO DE DATA
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'hoje às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'ontem';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} dias atrás';
      } else {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
}