import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_service.dart';
import '../../models/workout_plan.dart';
import '../../services/workout_plan_service.dart';
import 'workout_plan_details_page.dart';
import 'ai_workout_generator_page.dart';

class WorkoutPlanListPage extends StatefulWidget {
  const WorkoutPlanListPage({super.key});

  @override
  State<WorkoutPlanListPage> createState() => _WorkoutPlanListPageState();
}

class _WorkoutPlanListPageState extends State<WorkoutPlanListPage> {
  List<WorkoutPlan> _workoutPlans = [];
  bool _isLoading = true;

  String? _userEmail;
  String? _userPassword;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userEmail = prefs.getString('email');
      _userPassword = '123123'; // Temporário

      if (_userEmail != null) {
        await _loadWorkoutPlans();
      } else {
        _showError('Erro de autenticação. Faça login novamente.');
      }
    } catch (e) {
      _showError('Erro ao inicializar usuário: $e');
    }
  }

  Future<void> _loadWorkoutPlans() async {
    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final plansData = await apiService.getWorkoutPlans();

      final plans = <WorkoutPlan>[];
      for (final planData in plansData) {
        try {
          final workoutPlan = WorkoutPlan.fromJson(planData);
          plans.add(workoutPlan);
        } catch (e) {
          print('Erro ao converter plano: $e');
        }
      }

      setState(() {
        _workoutPlans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erro ao carregar planos: $e');
    }
  }

  Future<void> _createNewWorkoutPlan() async {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const AIWorkoutGeneratorPage(),
          ),
        )
        .then((_) => _loadWorkoutPlans());
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Treinos'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWorkoutPlans,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Carregando planos de treino...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : _workoutPlans.isEmpty
          ? _buildEmptyState()
          : _buildPlansList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _createNewWorkoutPlan,
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Treino', style: TextStyle(color: Colors.white)),
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
            Icon(Icons.fitness_center, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'Nenhum treino encontrado',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Crie seu primeiro plano de treino personalizado com nossa Personal Virtual',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _createNewWorkoutPlan,
              icon: const Icon(Icons.fitness_center),
              label: const Text('Gerar Treino com IA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansList() {
    return RefreshIndicator(
      onRefresh: _loadWorkoutPlans,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _workoutPlans.length,
        itemBuilder: (context, index) {
          final plan = _workoutPlans[index];
          return _buildWorkoutCard(plan);
        },
      ),
    );
  }

  Widget _buildWorkoutCard(WorkoutPlan plan) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openWorkoutDetails(plan),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.withOpacity(0.1)
                          : Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      plan.workoutType == 'home'
                          ? Icons.home
                          : Icons.fitness_center,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey
                          : Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.workoutType == 'home' ? 'Casa' : 'Academia',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 20,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 8),
                            Text('Ver Detalhes'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Deletar',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          _openWorkoutDetails(plan);
                          break;
                        case 'delete':
                          _confirmDelete(plan);
                          break;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Criado em ${_formatDate(plan.createdAt)}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openWorkoutDetails(WorkoutPlan plan) {
    print('[WORKOUT_LIST] 🔄 Abrindo detalhes do plano: ${plan.planName}');
    print(
      '[WORKOUT_LIST] 📊 Dados do plano: ${plan.workoutData.length} caracteres',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutPlanDetailsPage(plan: plan),
      ),
    );
  }

  Future<void> _confirmDelete(WorkoutPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar Treino'),
        content: Text('Tem certeza que deseja deletar "${plan.planName}"?'),
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

    if (confirmed == true && _userEmail != null && _userPassword != null) {
      try {
        await WorkoutPlanService.deleteWorkoutPlan(
          _userEmail!,
          _userPassword!,
          plan.id,
        );

        _loadWorkoutPlans();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ "${plan.planName}" deletado!'),
              backgroundColor: Theme.of(context).primaryColor,
            ),
          );
        }
      } catch (e) {
        _showError('Erro ao deletar treino: $e');
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
