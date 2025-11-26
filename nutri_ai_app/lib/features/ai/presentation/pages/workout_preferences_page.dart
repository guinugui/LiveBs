import 'package:flutter/material.dart';
import '../../../../core/network/ai_service.dart';
import '../../../../core/utils/profile_utils.dart';
import 'workout_plan_display_page.dart';

class WorkoutPreferencesPage extends StatefulWidget {
  const WorkoutPreferencesPage({super.key});

  @override
  State<WorkoutPreferencesPage> createState() => _WorkoutPreferencesPageState();
}

class _WorkoutPreferencesPageState extends State<WorkoutPreferencesPage> {
  int _workoutDaysPerWeek = 3;
  final List<String> _selectedMuscularProblems = [];
  final List<String> _selectedFitnessGoals = [];
  bool _isLoading = false;

  final List<String> _muscularProblemsOptions = [
    'Dor nas costas',
    'Problema no joelho',
    'Dor no ombro',
    'Lesão no tornozelo',
    'Hérnia de disco',
    'Artrite',
    'Tendinite',
    'Outros problemas articulares',
  ];

  final List<String> _fitnessGoalsOptions = [
    'Emagrecimento',
    'Tonificação muscular',
    'Ganho de massa muscular',
    'Melhora do condicionamento',
    'Fortalecimento do core',
    'Melhora da postura',
    'Aumento da flexibilidade',
    'Redução do estresse',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Personal Trainer IA',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Gerando seu plano de treino personalizado...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🏋️‍♂️ Vamos criar seu plano de treino personalizado!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Responda algumas perguntas para receber um plano de exercícios ideal para você.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Dias por semana
                  _buildSectionCard(
                    title: '📅 Quantos dias por semana você pode treinar?',
                    child: Column(
                      children: [
                        Slider(
                          value: _workoutDaysPerWeek.toDouble(),
                          min: 1,
                          max: 7,
                          divisions: 6,
                          activeColor: const Color(0xFF2E7D32),
                          label: '$_workoutDaysPerWeek dias',
                          onChanged: (value) {
                            setState(() {
                              _workoutDaysPerWeek = value.round();
                            });
                          },
                        ),
                        Text(
                          '$_workoutDaysPerWeek dias por semana',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Problemas musculares
                  _buildSectionCard(
                    title: '⚠️ Você tem algum problema muscular ou limitação física?',
                    child: Column(
                      children: _muscularProblemsOptions.map((problem) {
                        return CheckboxListTile(
                          title: Text(problem),
                          value: _selectedMuscularProblems.contains(problem),
                          activeColor: const Color(0xFF2E7D32),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedMuscularProblems.add(problem);
                              } else {
                                _selectedMuscularProblems.remove(problem);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Objetivos fitness
                  _buildSectionCard(
                    title: '🎯 Quais são seus principais objetivos?',
                    child: Column(
                      children: _fitnessGoalsOptions.map((goal) {
                        return CheckboxListTile(
                          title: Text(goal),
                          value: _selectedFitnessGoals.contains(goal),
                          activeColor: const Color(0xFF2E7D32),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedFitnessGoals.add(goal);
                              } else {
                                _selectedFitnessGoals.remove(goal);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Botão Gerar Plano
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _generateWorkoutPlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fitness_center, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Gerar Plano de Treino',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    '💡 Dica: Seja honesto sobre suas limitações para receber um plano seguro e eficaz!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Future<void> _generateWorkoutPlan() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Buscar perfil do usuário
      final userProfile = await ProfileUtils.getUserProfile();
      
      if (userProfile == null) {
        throw Exception('Perfil do usuário não encontrado');
      }

      // Gerar plano de treino
      final aiService = AIService();
      final workoutPlan = await aiService.generateWorkoutPlan(
        userProfile: userProfile,
        workoutDaysPerWeek: _workoutDaysPerWeek,
        muscularProblems: _selectedMuscularProblems,
        fitnessGoals: _selectedFitnessGoals.isEmpty ? ['Emagrecimento geral'] : _selectedFitnessGoals,
      );

      setState(() {
        _isLoading = false;
      });

      // Navegar para página de exibição do plano
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WorkoutPlanDisplayPage(workoutPlan: workoutPlan),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar plano de treino: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}