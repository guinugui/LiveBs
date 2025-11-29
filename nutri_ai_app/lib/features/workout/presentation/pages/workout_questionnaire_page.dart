import 'package:flutter/material.dart';
import '../../models/workout_plan.dart';
import '../../services/workout_plan_service.dart';
import 'workout_plan_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutQuestionnairePage extends StatefulWidget {
  const WorkoutQuestionnairePage({super.key});

  @override
  State<WorkoutQuestionnairePage> createState() =>
      _WorkoutQuestionnairePageState();
}

class _WorkoutQuestionnairePageState extends State<WorkoutQuestionnairePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Dados do questionário
  bool _hasMusculoskeletalProblems = false;
  String? _musculoskeletalDetails;
  bool _hasRespiratoryProblems = false;
  String? _respiratoryDetails;
  bool _hasCardiacProblems = false;
  String? _cardiacDetails;
  List<String> _previousInjuries = [];
  String _fitnessLevel = 'iniciante';
  List<String> _preferredExercises = [];
  List<String> _exercisesToAvoid = [];
  String _workoutType = 'home'; // 'home' ou 'gym'
  int _daysPerWeek = 3;
  int _sessionDuration = 45; // em minutos
  List<String> _availableDays = [];

  // Controllers
  final TextEditingController _musculoskeletalController =
      TextEditingController();
  final TextEditingController _respiratoryController = TextEditingController();
  final TextEditingController _cardiacController = TextEditingController();

  // User credentials
  String? _userEmail;
  String? _userPassword;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _musculoskeletalController.dispose();
    _respiratoryController.dispose();
    _cardiacController.dispose();
    super.dispose();
  }

  Future<void> _initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    _userEmail = prefs.getString('email');
    _userPassword = '123123'; // Temporário
  }

  void _nextPage() {
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _generateWorkoutPlan();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _generateWorkoutPlan() async {
    if (_userEmail == null) {
      _showError('Erro de autenticação. Faça login novamente.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final questionnaire = WorkoutQuestionnaire(
        hasMusculoskeletalProblems: _hasMusculoskeletalProblems,
        musculoskeletalDetails: _musculoskeletalDetails,
        hasRespiratoryProblems: _hasRespiratoryProblems,
        respiratoryDetails: _respiratoryDetails,
        hasCardiacProblems: _hasCardiacProblems,
        cardiacDetails: _cardiacDetails,
        previousInjuries: _previousInjuries,
        fitnessLevel: _fitnessLevel,
        preferredExercises: _preferredExercises,
        exercisesToAvoid: _exercisesToAvoid,
        workoutType: _workoutType,
        daysPerWeek: _daysPerWeek,
        sessionDuration: _sessionDuration,
        availableDays: _availableDays,
      );

      final workoutPlan = await WorkoutPlanService.createWorkoutPlan(
        _userEmail!,
        _userPassword!,
        questionnaire,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => WorkoutPlanListPage()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${workoutPlan.planName} criado com sucesso!'),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }
    } catch (e) {
      _showError('Erro ao gerar plano: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
        title: const Text('Personal Virtual'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / 6,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),

          // Page Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildHealthProblemsPage(),
                _buildInjuriesPage(),
                _buildFitnessLevelPage(),
                _buildPreferencesPage(),
                _buildWorkoutTypePage(),
                _buildSchedulePage(),
              ],
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  ElevatedButton(
                    onPressed: _previousPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text('Voltar'),
                  )
                else
                  const SizedBox.shrink(),

                ElevatedButton(
                  onPressed: _isLoading ? null : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_currentPage == 5 ? 'Gerar Treino' : 'Próximo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthProblemsPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏥 Problemas de Saúde',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Você tem algum problema de saúde que devemos considerar?',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),

          // Problemas musculoesqueléticos
          CheckboxListTile(
            title: const Text('Problemas musculoesqueléticos'),
            subtitle: const Text('Articulações, músculos, ossos'),
            value: _hasMusculoskeletalProblems,
            onChanged: (value) {
              setState(() {
                _hasMusculoskeletalProblems = value ?? false;
                if (!_hasMusculoskeletalProblems) {
                  _musculoskeletalDetails = null;
                  _musculoskeletalController.clear();
                }
              });
            },
          ),

          if (_hasMusculoskeletalProblems)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _musculoskeletalController,
                decoration: const InputDecoration(
                  hintText: 'Descreva os problemas...',
                ),
                onChanged: (value) => _musculoskeletalDetails = value,
              ),
            ),

          // Problemas respiratórios
          CheckboxListTile(
            title: const Text('Problemas respiratórios'),
            subtitle: const Text('Asma, bronquite, etc.'),
            value: _hasRespiratoryProblems,
            onChanged: (value) {
              setState(() {
                _hasRespiratoryProblems = value ?? false;
                if (!_hasRespiratoryProblems) {
                  _respiratoryDetails = null;
                  _respiratoryController.clear();
                }
              });
            },
          ),

          if (_hasRespiratoryProblems)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _respiratoryController,
                decoration: const InputDecoration(
                  hintText: 'Descreva os problemas...',
                ),
                onChanged: (value) => _respiratoryDetails = value,
              ),
            ),

          // Problemas cardíacos
          CheckboxListTile(
            title: const Text('Problemas cardíacos'),
            subtitle: const Text('Coração, pressão arterial'),
            value: _hasCardiacProblems,
            onChanged: (value) {
              setState(() {
                _hasCardiacProblems = value ?? false;
                if (!_hasCardiacProblems) {
                  _cardiacDetails = null;
                  _cardiacController.clear();
                }
              });
            },
          ),

          if (_hasCardiacProblems)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _cardiacController,
                decoration: const InputDecoration(
                  hintText: 'Descreva os problemas...',
                ),
                onChanged: (value) => _cardiacDetails = value,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInjuriesPage() {
    final injuries = [
      'Lesão no joelho',
      'Lesão no ombro',
      'Lesão nas costas',
      'Lesão no tornozelo',
      'Lesão no punho',
      'Hérnia',
      'Outras lesões',
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🩹 Lesões Anteriores',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Você já teve alguma lesão que devemos evitar agravar?',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: ListView.builder(
              itemCount: injuries.length,
              itemBuilder: (context, index) {
                final injury = injuries[index];
                return CheckboxListTile(
                  title: Text(injury),
                  value: _previousInjuries.contains(injury),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _previousInjuries.add(injury);
                      } else {
                        _previousInjuries.remove(injury);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFitnessLevelPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💪 Nível de Condicionamento',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Como você classificaria seu nível atual de condicionamento físico?',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),

          RadioListTile<String>(
            title: const Text('Iniciante'),
            subtitle: const Text('Pouca ou nenhuma experiência com exercícios'),
            value: 'iniciante',
            groupValue: _fitnessLevel,
            onChanged: (value) => setState(() => _fitnessLevel = value!),
          ),

          RadioListTile<String>(
            title: const Text('Intermediário'),
            subtitle: const Text(
              'Pratica exercícios regularmente há alguns meses',
            ),
            value: 'intermediario',
            groupValue: _fitnessLevel,
            onChanged: (value) => setState(() => _fitnessLevel = value!),
          ),

          RadioListTile<String>(
            title: const Text('Avançado'),
            subtitle: const Text(
              'Pratica exercícios há mais de 1 ano consistentemente',
            ),
            value: 'avancado',
            groupValue: _fitnessLevel,
            onChanged: (value) => setState(() => _fitnessLevel = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesPage() {
    final exercises = [
      'Musculação',
      'Cardio/Aeróbico',
      'Funcional',
      'Yoga/Pilates',
      'Dança',
      'Artes Marciais',
      'Natação',
      'Corrida',
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '❤️ Preferências',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Que tipos de exercício você gosta ou gostaria de fazer?',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return CheckboxListTile(
                  title: Text(exercise),
                  value: _preferredExercises.contains(exercise),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _preferredExercises.add(exercise);
                      } else {
                        _preferredExercises.remove(exercise);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutTypePage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏠 Local do Treino',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Onde você pretende treinar?',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            child: Card(
              elevation: _workoutType == 'home' ? 8 : 2,
              color: _workoutType == 'home' ? Colors.orange[50] : null,
              child: InkWell(
                onTap: () => setState(() => _workoutType = 'home'),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.home,
                        size: 50,
                        color: _workoutType == 'home'
                            ? Colors.orange
                            : Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Em Casa',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Treinos sem equipamentos ou com itens improvisados',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            child: Card(
              elevation: _workoutType == 'gym' ? 8 : 2,
              color: _workoutType == 'gym' ? Colors.orange[50] : null,
              child: InkWell(
                onTap: () => setState(() => _workoutType = 'gym'),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 50,
                        color: _workoutType == 'gym'
                            ? Colors.orange
                            : Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Na Academia',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Treinos com equipamentos disponíveis na maioria das academias',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulePage() {
    final days = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo',
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📅 Cronograma',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Frequência semanal
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quantos dias por semana?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _daysPerWeek.toDouble(),
                    min: 1,
                    max: 7,
                    divisions: 6,
                    label: '$_daysPerWeek dias',
                    onChanged: (value) =>
                        setState(() => _daysPerWeek = value.round()),
                  ),
                  Text('$_daysPerWeek dias por semana'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Duração da sessão
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Duração de cada treino?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _sessionDuration.toDouble(),
                    min: 15,
                    max: 120,
                    divisions: 21,
                    label: '$_sessionDuration min',
                    onChanged: (value) =>
                        setState(() => _sessionDuration = value.round()),
                  ),
                  Text('$_sessionDuration minutos por treino'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Dias disponíveis
          const Text(
            'Que dias você pode treinar?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                return CheckboxListTile(
                  title: Text(day),
                  value: _availableDays.contains(day),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _availableDays.add(day);
                      } else {
                        _availableDays.remove(day);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
