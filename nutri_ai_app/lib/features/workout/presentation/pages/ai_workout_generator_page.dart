import 'package:flutter/material.dart';
import '../../../../core/network/api_service.dart';

class AIWorkoutGeneratorPage extends StatefulWidget {
  const AIWorkoutGeneratorPage({super.key});

  @override
  State<AIWorkoutGeneratorPage> createState() => _AIWorkoutGeneratorPageState();
}

class _AIWorkoutGeneratorPageState extends State<AIWorkoutGeneratorPage> {
  final ApiService _apiService = ApiService();
  final PageController _pageController = PageController();

  int _currentPage = 0;
  bool _isLoading = false;

  // Dados do questionário
  int _age = 25;
  String _gender = 'masculino';
  double _weight = 70.0;
  double _height = 170.0;
  String _objective = '';
  String _location = 'GYM';
  String _equipment = '';
  int _daysPerWeek = 3;
  int _minutesPerDay = 45;
  String _injuries = '';

  // Resultado da IA
  Map<String, dynamic>? _workoutPlan;

  final List<String> _objectives = [
    'Emagrecimento',
    'Ganho de massa muscular',
    'Condicionamento físico',
    'Fortalecimento',
    'Tonificação',
  ];

  final List<String> _equipmentOptions = [
    'Completa (halteres, barras, máquinas)',
    'Básica (halteres e barras)',
    'Limitada (poucos equipamentos)',
    'Nenhum equipamento',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gerador de Treino IA',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _workoutPlan != null
          ? _buildWorkoutResult()
          : _buildQuestionnaire(),
    );
  }

  Widget _buildQuestionnaire() {
    return Column(
      children: [
        // Progress indicator
        Container(
          padding: const EdgeInsets.all(16),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / 3,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),

        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            children: [
              _buildPersonalInfoPage(),
              _buildWorkoutPreferencesPage(),
              _buildGoalsPage(),
            ],
          ),
        ),

        // Navigation buttons
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousPage,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      side: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    child: const Text('Voltar'),
                  ),
                ),
              if (_currentPage > 0) const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_currentPage == 2 ? 'Gerar Treino' : 'Próximo'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '👤 Informações Pessoais',
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.headlineMedium?.color,
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _age.toString(),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'Idade',
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) => _age = int.tryParse(value) ?? _age,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _gender,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'Sexo',
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    border: const OutlineInputBorder(),
                  ),
                  items: ['masculino', 'feminino'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value.capitalize(),
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _gender = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _weight.toString(),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'Peso (kg)',
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) =>
                      _weight = double.tryParse(value) ?? _weight,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: _height.toString(),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'Altura (cm)',
                    labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) =>
                      _height = double.tryParse(value) ?? _height,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextFormField(
            maxLines: 3,
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              labelText: 'Lesões ou limitações (opcional)',
              labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
              border: const OutlineInputBorder(),
              hintText: 'Descreva qualquer lesão ou limitação física...',
              hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
            ),
            onChanged: (value) => _injuries = value,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutPreferencesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏋️ Preferências de Treino',
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.headlineMedium?.color,
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Local de treino:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text(
                    'Academia (GYM)',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  value: 'GYM',
                  groupValue: _location,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (value) => setState(() => _location = value!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text(
                    'Casa (HOME)',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  value: 'HOME',
                  groupValue: _location,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (value) => setState(() => _location = value!),
                ),
              ),
            ],
          ),

          if (_location == 'GYM') ...[
            const SizedBox(height: 16),
            Text(
              'Equipamentos disponíveis:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            ..._equipmentOptions.map(
              (equipment) => RadioListTile<String>(
                title: Text(
                  equipment,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                value: equipment,
                groupValue: _equipment,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (value) => setState(() => _equipment = value!),
              ),
            ),
          ],

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dias por semana:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Slider(
                      value: _daysPerWeek.toDouble(),
                      min: 2,
                      max: 6,
                      divisions: 4,
                      label: '$_daysPerWeek dias',
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (value) =>
                          setState(() => _daysPerWeek = value.round()),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minutos por dia:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Slider(
                      value: _minutesPerDay.toDouble(),
                      min: 30,
                      max: 120,
                      divisions: 9,
                      label: '$_minutesPerDay min',
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (value) =>
                          setState(() => _minutesPerDay = value.round()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎯 Objetivo Principal',
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.headlineMedium?.color,
            ),
          ),
          const SizedBox(height: 24),

          ..._objectives.map(
            (objective) => Card(
              child: RadioListTile<String>(
                title: Text(
                  objective,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                value: objective,
                groupValue: _objective,
                onChanged: (value) => setState(() => _objective = value!),
                activeColor: Theme.of(context).primaryColor,
              ),
            ),
          ),

          if (_objective.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Resumo da Configuração',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• $_age anos, $_gender, ${_weight}kg, ${_height}cm',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  Text(
                    '• Objetivo: $_objective',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  Text(
                    '• Local: $_location',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  if (_location == 'GYM' && _equipment.isNotEmpty)
                    Text(
                      '• Equipamentos: $_equipment',
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                  Text(
                    '• $_daysPerWeek dias por semana, $_minutesPerDay min/dia',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  if (_injuries.isNotEmpty) 
                    Text(
                      '• Limitações: $_injuries',
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkoutResult() {
    final plan = _workoutPlan!;
    final weeklyPlan = plan['weekly_plan'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Guia section
          Card(
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).cardColor
                : Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline, 
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).primaryColor
                            : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Guia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).primaryColor
                              : Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    plan['orientation'] ??
                        'Treino personalizado criado com base nas suas preferências de $_location ($_objective). Siga as orientações específicas para cada dia de treino.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Exercícios do Dia section
          Card(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Exercícios da Semana ($_daysPerWeek)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ...weeklyPlan.entries.map((entry) {
                    final day = entry.key;
                    final exercises = entry.value as String;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${weeklyPlan.keys.toList().indexOf(day) + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                day,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(exercises, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          if (plan['duration'] != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Duração/Intensidade'),
                subtitle: Text(plan['duration']),
              ),
            ),
          ],

          if (plan['progression'] != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.trending_up),
                title: const Text('Progressão Sugerida'),
                subtitle: Text(plan['progression']),
              ),
            ),
          ],

          if (plan['precautions'] != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: Icon(Icons.warning, color: Colors.red.shade700),
                title: const Text('Cuidados'),
                subtitle: Text(plan['precautions']),
              ),
            ),
          ],

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _workoutPlan = null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  child: const Text('Gerar Novo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Salvar Treino'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _generateWorkout();
    }
  }

  Future<void> _generateWorkout() async {
    setState(() => _isLoading = true);

    try {
      final prompt = _buildWorkoutPrompt();
      print(
        '[WORKOUT] 🚀 Gerando treino com IA (separado do chat personal)...',
      );

      // Usar função específica para treinos que não salva no chat personal
      final response = await _apiService.generateWorkoutWithAI(prompt);

      print(
        '[WORKOUT] ✅ Resposta recebida: ${response.toString().substring(0, 100)}...',
      );

      // Parse the AI response to extract structured data
      final aiResponse = response['message'] as String;
      Map<String, dynamic> parsedPlan;

      if (aiResponse.contains('Timeout') || aiResponse.length < 50) {
        print('[WORKOUT] ⚠️ Resposta inválida, gerando plano offline');
        parsedPlan = _createOfflinePlan();
      } else {
        parsedPlan = _parseAIResponse(aiResponse);
        // SALVAR A RESPOSTA ORIGINAL COMO MARKDOWN
        parsedPlan['original_markdown'] = aiResponse;
      }

      print('[WORKOUT] 📋 Plano parseado: ${parsedPlan.keys}');

      setState(() {
        _workoutPlan = parsedPlan;
        _isLoading = false;
      });
    } catch (e) {
      print('[WORKOUT] ❌ Erro: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao gerar treino: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _buildWorkoutPrompt() {
    return '''
🏋️‍♂️ PROMPT – Gerador de Treino (GYM & HOME)

Você é um Gerador de Treinos Personalizados, capaz de criar treinos para academia (GYM) ou para casa (HOME).
Seu objetivo é montar rotinas semanais completas, sempre seguindo as instruções abaixo.

🎯 REGRAS PRINCIPAIS
• Você nunca entrega exercícios finais.
• Apenas diz quantos exercícios por grupo muscular e quais grupos devem ser treinados por dia.
• Você pode dar exemplos de exercícios, mas apenas como referência.

Se o treino for HOME (em casa):
• Assuma que NÃO há equipamentos.
• Monte treinos em formato de circuito.
• Sempre indicar: Quantos circuitos, Quantos exercícios por circuito, Tempo de execução e descanso

Se o treino for GYM (academia):
• Divisão por grupos musculares padrão.
• Indicar quantos exercícios por grupo (ex.: 4 peito + 2 tríceps).
• Pode dar exemplos dos exercícios para referência.

DADOS DO USUÁRIO:
• Idade: $_age anos
• Sexo: $_gender
• Peso: ${_weight}kg
• Altura: ${_height}cm
• Objetivo: $_objective
• Local: $_location
• ${_location == 'GYM' ? 'Equipamentos: $_equipment' : 'Sem equipamentos'}
• Dias de treino por semana: $_daysPerWeek
• Minutos por dia: $_minutesPerDay
• ${_injuries.isNotEmpty ? 'Lesões/limitações: $_injuries' : 'Sem lesões conhecidas'}

Sempre responder organizado no formato:
📅 DIVISÃO SEMANAL
💪 ORIENTAÇÃO DO TREINO
📌 EXEMPLOS DE EXERCÍCIOS (REFERÊNCIA)
⏱️ DURAÇÃO / INTENSIDADE
💥 PROGRESSÃO SUGERIDA
⚠️ CUIDADOS
''';
  }

  Map<String, dynamic> _parseAIResponse(String response) {
    print('[WORKOUT] 🔍 Iniciando parsing da resposta...');

    final lines = response.split('\n');
    Map<String, dynamic> result = {};
    Map<String, String> weeklyPlan = {};

    String currentSection = '';
    List<String> currentContent = [];

    // Se não conseguir fazer parse estruturado, criar um plano básico
    bool hasStructuredData = response.contains('📅') && response.contains('💪');

    if (!hasStructuredData) {
      print('[WORKOUT] ⚠️ Resposta não estruturada, criando plano básico...');
      return _createBasicPlan(response);
    }

    for (String line in lines) {
      final trimmedLine = line.trim();

      if (trimmedLine.startsWith('📅')) {
        _saveSection(result, currentSection, currentContent, weeklyPlan);
        currentSection = 'weekly_plan';
        currentContent = [];
      } else if (trimmedLine.startsWith('💪')) {
        _saveSection(result, currentSection, currentContent, weeklyPlan);
        currentSection = 'orientation';
        currentContent = [];
      } else if (trimmedLine.startsWith('📌')) {
        _saveSection(result, currentSection, currentContent, weeklyPlan);
        currentSection = 'examples';
        currentContent = [];
      } else if (trimmedLine.startsWith('⏱️')) {
        _saveSection(result, currentSection, currentContent, weeklyPlan);
        currentSection = 'duration';
        currentContent = [];
      } else if (trimmedLine.startsWith('💥')) {
        _saveSection(result, currentSection, currentContent, weeklyPlan);
        currentSection = 'progression';
        currentContent = [];
      } else if (trimmedLine.startsWith('⚠️')) {
        _saveSection(result, currentSection, currentContent, weeklyPlan);
        currentSection = 'precautions';
        currentContent = [];
      } else if (trimmedLine.isNotEmpty) {
        if (currentSection == 'weekly_plan') {
          // Detectar dias da semana e exercícios
          if (_isDayLine(trimmedLine)) {
            final dayInfo = _extractDayInfo(trimmedLine);
            if (dayInfo != null) {
              weeklyPlan[dayInfo['day']!] = dayInfo['exercises']!;
            }
          }
        } else {
          currentContent.add(trimmedLine);
        }
      }
    }

    // Save the last section
    _saveSection(result, currentSection, currentContent, weeklyPlan);

    if (weeklyPlan.isNotEmpty) {
      result['weekly_plan'] = weeklyPlan;
    } else {
      // Se não encontrou divisão semanal, criar uma básica
      result['weekly_plan'] = _createDefaultWeeklyPlan();
    }

    print('[WORKOUT] ✅ Parsing concluído: ${result.keys}');
    return result;
  }

  void _saveSection(
    Map<String, dynamic> result,
    String section,
    List<String> content,
    Map<String, String> weeklyPlan,
  ) {
    if (section == 'weekly_plan' && weeklyPlan.isNotEmpty) {
      result['weekly_plan'] = Map<String, String>.from(weeklyPlan);
    } else if (section.isNotEmpty && content.isNotEmpty) {
      result[section] = content.join(' ').trim();
    }
  }

  bool _isDayLine(String line) {
    final dayKeywords = [
      'segunda',
      'terça',
      'quarta',
      'quinta',
      'sexta',
      'sábado',
      'domingo',
      'dia 1',
      'dia 2',
      'dia 3',
      'dia 4',
      'dia 5',
      'dia 6',
    ];
    final lowerLine = line.toLowerCase();
    return dayKeywords.any((day) => lowerLine.contains(day)) &&
        line.contains(':');
  }

  Map<String, String>? _extractDayInfo(String line) {
    final colonIndex = line.indexOf(':');
    if (colonIndex == -1) return null;

    final day = line.substring(0, colonIndex).trim();
    final exercises = line.substring(colonIndex + 1).trim();

    return {'day': day, 'exercises': exercises};
  }

  Map<String, String> _createDefaultWeeklyPlan() {
    if (_location == 'HOME') {
      final Map<String, String> plan = {
        'Segunda-feira': 'Full Body Circuit - 5 exercícios, 30s cada, 3 voltas',
        'Quarta-feira':
            'Inferior + Core - 4 exercícios pernas + 2 abdome, 40s cada',
      };

      if (_daysPerWeek >= 3) {
        plan['Sexta-feira'] =
            'Superior + Cardio - 4 exercícios braços + 2 cardio';
      }
      if (_daysPerWeek >= 4) {
        plan['Terça-feira'] = 'HIIT Training - 6 exercícios alta intensidade';
      }
      if (_daysPerWeek >= 5) {
        plan['Quinta-feira'] = 'Funcional - Movimentos compostos corpo inteiro';
      }
      if (_daysPerWeek >= 6) {
        plan['Sábado'] = 'Alongamento + Core - Exercícios de flexibilidade';
      }

      return plan;
    } else {
      final Map<String, String> plan = {
        'Segunda-feira':
            'Peito + Tríceps - 4 exercícios peito + 2 tríceps (3-4 séries)',
        'Quarta-feira':
            'Costas + Bíceps - 4 exercícios costas + 2 bíceps (3-4 séries)',
      };

      if (_daysPerWeek >= 3) {
        plan['Sexta-feira'] =
            'Pernas + Ombros - 4 exercícios pernas + 2 ombros';
      }
      if (_daysPerWeek >= 4) {
        plan['Terça-feira'] = 'Ombros + Core - 4 exercícios ombros + 2 abdome';
      }
      if (_daysPerWeek >= 5) {
        plan['Quinta-feira'] = 'Braços Completos - 3 bíceps + 3 tríceps';
      }
      if (_daysPerWeek >= 6) {
        plan['Sábado'] = 'Posterior + Glúteos - 4 exercícios específicos';
      }

      return plan;
    }
  }

  Map<String, dynamic> _createBasicPlan(String response) {
    return {
      'orientation':
          'Treino personalizado gerado com base nas suas informações. Siga as orientações abaixo.',
      'weekly_plan': _createDefaultWeeklyPlan(),
      'duration':
          '$_minutesPerDay minutos por sessão, $_daysPerWeek dias por semana',
      'progression': 'Aumente gradualmente a intensidade a cada 2 semanas',
      'precautions': _injuries.isNotEmpty
          ? 'Atenção às limitações: $_injuries'
          : 'Mantenha boa forma em todos os exercícios',
      'raw_response': response,
    };
  }

  Map<String, dynamic> _createOfflinePlan() {
    final orientationText = _location == 'HOME'
        ? 'Treino em casa personalizado para $_objective. Não são necessários equipamentos.'
        : 'Treino na academia personalizado para $_objective. Use os equipamentos disponíveis.';

    return {
      'orientation': orientationText,
      'weekly_plan': _createDefaultWeeklyPlan(),
      'duration':
          '$_minutesPerDay minutos por sessão, $_daysPerWeek dias por semana',
      'progression': _location == 'HOME'
          ? 'A cada 2 semanas: +5 segundos nos exercícios, +1 volta nos circuitos'
          : 'A cada 2 semanas: +1 série ou +10% de carga nos exercícios',
      'precautions': _injuries.isNotEmpty
          ? 'IMPORTANTE: Respeite suas limitações: $_injuries. Consulte um profissional se necessário.'
          : 'Mantenha sempre a forma correta. Aqueça antes e alongue depois dos treinos.',
      'examples': _location == 'HOME'
          ? 'Exemplos: flexões, agachamentos, pranchas, burpees, mountain climbers'
          : 'Exemplos: supino, agachamento livre, remada, desenvolvimento, rosca direta',
    };
  }

  Future<void> _saveWorkout() async {
    if (_workoutPlan == null) return;

    try {
      final plan = _workoutPlan!;

      // SALVAR COMO MARKDOWN PURO (igual ao Personal Virtual)
      String workoutContent;

      if (plan.containsKey('original_markdown')) {
        // Usar resposta original da IA (markdown formatado)
        workoutContent = plan['original_markdown'] as String;
        print('💾 Salvando treino como MARKDOWN original');
      } else {
        // Para planos offline, criar markdown manualmente
        workoutContent = _convertToMarkdown(plan);
        print('💾 Salvando treino como MARKDOWN convertido');
      }

      // Estrutura simplificada - só enviar o markdown
      final workoutData = {
        'workout_type': _location == 'GYM' ? 'gym' : 'home',
        'days_per_week': _daysPerWeek,
        'session_duration': _minutesPerDay,
        'fitness_level': 'intermediario',
        'objective': _objective,
        'markdown_content': workoutContent, // CONTEÚDO PRINCIPAL EM MARKDOWN
      };

      print(
        '💾 Salvando treino via API: ${workoutData['workout_type']} (${workoutContent.length} chars)',
      );

      // Salvar via API
      final apiService = ApiService();
      await apiService.saveWorkoutPlan(workoutData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '✅ Treino salvo com sucesso! Confira em "Meus Treinos".',
            ),
            backgroundColor: Theme.of(context).primaryColor,
            duration: const Duration(seconds: 3),
          ),
        );

        // Não navegar automaticamente - deixar o usuário decidir
        // O usuário pode usar o botão "Gerar Novo" ou voltar manualmente
      }
    } catch (e) {
      print('❌ Erro ao salvar treino: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _convertToMarkdown(Map<String, dynamic> plan) {
    final buffer = StringBuffer();

    // Título principal
    buffer.writeln(
      '# 🏆 Treino ${_location == 'GYM' ? 'na Academia' : 'em Casa'}',
    );
    buffer.writeln('');

    // Resumo
    buffer.writeln('## 📊 Resumo do Plano');
    buffer.writeln('- **Local:** ${_location == 'GYM' ? 'Academia' : 'Casa'}');
    buffer.writeln('- **Objetivo:** $_objective');
    buffer.writeln('- **Frequência:** $_daysPerWeek dias por semana');
    buffer.writeln('- **Duração:** $_minutesPerDay minutos por sessão');
    buffer.writeln('');

    // Plano semanal
    if (plan['weekly_plan'] != null) {
      buffer.writeln('## 📅 **DIVISÃO SEMANAL**');
      final weeklyPlan = plan['weekly_plan'] as Map<String, dynamic>;
      weeklyPlan.forEach((day, exercises) {
        buffer.writeln('- **$day:** $exercises');
      });
      buffer.writeln('');
    }

    // Orientações
    if (plan['orientation'] != null) {
      buffer.writeln('## 💪 **ORIENTAÇÃO DO TREINO**');
      buffer.writeln(plan['orientation']);
      buffer.writeln('');
    }

    // Exemplos
    if (plan['examples'] != null) {
      buffer.writeln('## 📌 **EXEMPLOS DE EXERCÍCIOS (REFERÊNCIA)**');
      buffer.writeln(plan['examples']);
      buffer.writeln('');
    }

    // Duração
    if (plan['duration'] != null) {
      buffer.writeln('## ⏱️ **DURAÇÃO/INTENSIDADE**');
      buffer.writeln(plan['duration']);
      buffer.writeln('');
    }

    // Progressão
    if (plan['progression'] != null) {
      buffer.writeln('## 💪 **PROGRESSÃO SUGERIDA**');
      buffer.writeln(plan['progression']);
      buffer.writeln('');
    }

    // Cuidados
    if (plan['precautions'] != null) {
      buffer.writeln('## ⚠️ **CUIDADOS**');
      buffer.writeln(plan['precautions']);
    }

    return buffer.toString();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
