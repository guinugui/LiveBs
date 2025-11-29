import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/workout_plan.dart';
import 'dart:convert';

class WorkoutPlanDetailsPage extends StatefulWidget {
  final WorkoutPlan plan;

  const WorkoutPlanDetailsPage({super.key, required this.plan});

  @override
  State<WorkoutPlanDetailsPage> createState() => _WorkoutPlanDetailsPageState();
}

class _WorkoutPlanDetailsPageState extends State<WorkoutPlanDetailsPage> {
  Map<String, dynamic>? _workoutData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _parseWorkoutData();
  }

  void _parseWorkoutData() {
    try {
      print('[WORKOUT_DETAILS] 📋 Dados do plano: ${widget.plan.planName}');
      print(
        '[WORKOUT_DETAILS] 📊 workoutData length: ${widget.plan.workoutData.length}',
      );
      print(
        '[WORKOUT_DETAILS] 📊 workoutData tipo: ${widget.plan.workoutData.runtimeType}',
      );

      String dataPreview = widget.plan.workoutData.length > 300
          ? widget.plan.workoutData.substring(0, 300)
          : widget.plan.workoutData;
      print('[WORKOUT_DETAILS] 📄 workoutData preview: $dataPreview');

      if (widget.plan.workoutData.isNotEmpty &&
          widget.plan.workoutData != '{}') {
        String rawData = widget.plan.workoutData;

        // Verificar se é markdown (começa com #, *, ou tem formatação típica)
        bool isMarkdown =
            rawData.contains('##') ||
            rawData.contains('**') ||
            rawData.contains('📅') ||
            rawData.contains('###') ||
            rawData.startsWith('# ') ||
            rawData.contains('💪') ||
            rawData.contains('🎯') ||
            rawData.contains('- **') ||
            (rawData.contains('**DIVISÃO') || rawData.contains('**ORIENTAÇÃO'));

        if (isMarkdown) {
          print('[WORKOUT_DETAILS] 📝 Detectado formato markdown');
          _workoutData = {'markdown_content': rawData};
          setState(() => _isLoading = false);
          return;
        }

        // PRIMEIRO: Tentar JSON parse direto
        try {
          print('[WORKOUT_DETAILS] 🎯 Tentando JSON parse direto...');
          _workoutData = json.decode(rawData);
          print('[WORKOUT_DETAILS] ✅ JSON parse direto bem-sucedido!');

          // Verificar se days ou workout_schedule existe
          List<dynamic>? schedule;

          if (_workoutData != null && _workoutData!['days'] != null) {
            schedule = _workoutData!['days'] as List<dynamic>;
            print(
              '[WORKOUT_DETAILS] 🎉 SUCESSO: ${schedule.length} dias encontrados em days!',
            );
          } else if (_workoutData != null &&
              _workoutData!['workout_schedule'] != null) {
            schedule = _workoutData!['workout_schedule'] as List<dynamic>;
            print(
              '[WORKOUT_DETAILS] 🎉 SUCESSO: ${schedule.length} dias encontrados no workout_schedule!',
            );
            _workoutData!['days'] = schedule;
            _workoutData!.remove('workout_schedule');
          }

          if (schedule != null) {
            for (int i = 0; i < schedule.length; i++) {
              var day = schedule[i];
              if (day is Map && day['exercises'] is List) {
                var exercises = day['exercises'] as List;
                print(
                  '[WORKOUT_DETAILS] 📅 Dia ${i + 1} (${day['day']}): ${exercises.length} exercícios',
                );
              }
            }
            setState(() => _isLoading = false);
            return;
          }
        } catch (e) {
          print('[WORKOUT_DETAILS] ❌ JSON parse direto falhou: $e');
        }

        // SEGUNDO: Tentar converter formato PostgreSQL
        print(
          '[WORKOUT_DETAILS] 🔧 Tentando conversão PostgreSQL para JSON...',
        );
        try {
          String jsonString = _convertPostgreSQLToJson(rawData);
          _workoutData = json.decode(jsonString);
          print('[WORKOUT_DETAILS] ✅ Conversão PostgreSQL bem-sucedida');

          if (_workoutData != null &&
              _workoutData!['workout_schedule'] != null) {
            var schedule = _workoutData!['workout_schedule'] as List<dynamic>;
            print(
              '[WORKOUT_DETAILS] 🎉 ${schedule.length} dias encontrados após conversão PostgreSQL!',
            );
            return;
          }
        } catch (e) {
          print('[WORKOUT_DETAILS] ❌ Conversão PostgreSQL falhou: $e');
        }

        // TERCEIRO: Método de extração manual como último recurso
        print('[WORKOUT_DETAILS] 🔧 Usando método de extração manual...');
        _workoutData = _extractDataManually(rawData);

        print('[WORKOUT_DETAILS] ✅ Extração manual concluída');
      } else {
        print('[WORKOUT_DETAILS] ❌ workoutData vazio ou inválido');
      }
    } catch (e) {
      print('[WORKOUT_DETAILS] ❌ Erro ao fazer parse: $e');
      print(
        '[WORKOUT_DETAILS] 📄 Dados problemáticos: ${widget.plan.workoutData}',
      );

      // Como fallback, tentar criar dados mock para mostrar algo
      _workoutData = {
        'plan_name': widget.plan.planName,
        'plan_summary':
            'Dados de treino não puderam ser carregados corretamente.',
        'workout_schedule': [],
        'important_notes': ['Erro ao carregar dados do treino'],
        'progression_tips':
            'Recarregue o treino ou entre em contato com o suporte.',
      };
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan.planName),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _workoutData == null
          ? _buildErrorState()
          : _buildWorkoutDetails(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Erro ao carregar detalhes do treino',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Plano: ${widget.plan.planName}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Dados: ${widget.plan.workoutData.length} caracteres',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _parseWorkoutData();
              },
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutDetails() {
    // Se for conteúdo markdown, exibir com markdown
    if (_workoutData!.containsKey('markdown_content')) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do Plano
            _buildPlanHeader(),
            const SizedBox(height: 24),

            // Conteúdo Markdown
            _buildCard(
              child: Markdown(
                data: _workoutData!['markdown_content'],
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                styleSheet: MarkdownStyleSheet(
                  h1: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                  h2: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                  h3: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                  p: const TextStyle(fontSize: 16, height: 1.5),
                  strong: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do Plano
          _buildPlanHeader(),
          const SizedBox(height: 24),

          // Resumo do Plano
          if (_workoutData!['plan_summary'] != null) ...[
            _buildSectionTitle('Resumo do Plano'),
            const SizedBox(height: 8),
            _buildCard(
              child: Text(
                _workoutData!['plan_summary'],
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Cronograma de Treinos
          if (_workoutData!['days'] != null ||
              _workoutData!['workout_schedule'] != null) ...[
            _buildSectionTitle('Cronograma de Treinos'),
            const SizedBox(height: 12),
            ..._buildWorkoutSchedule(),
            const SizedBox(height: 24),
          ],

          // Notas Importantes
          if (_workoutData!['important_notes'] != null) ...[
            _buildSectionTitle('Notas Importantes'),
            const SizedBox(height: 8),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (String note in _workoutData!['important_notes'])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              note,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Dicas de Progressão
          if (_workoutData!['progression_tips'] != null) ...[
            _buildSectionTitle('Dicas de Progressão'),
            const SizedBox(height: 8),
            _buildCard(
              child: Text(
                _workoutData!['progression_tips'],
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanHeader() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.plan.workoutType == 'home'
                      ? Colors.blue[100]
                      : Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.plan.workoutType == 'home'
                      ? Icons.home
                      : Icons.fitness_center,
                  color: widget.plan.workoutType == 'home'
                      ? Colors.blue
                      : Colors.orange,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.plan.planName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.plan.daysPerWeek} dias por semana',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    Text(
                      widget.plan.workoutType == 'home'
                          ? 'Treino em Casa'
                          : 'Treino na Academia',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Criado em ${_formatDate(widget.plan.createdAt)}',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWorkoutSchedule() {
    // Verificar se existe 'days' ou 'workout_schedule'
    List<dynamic> schedule;
    if (_workoutData!['days'] != null) {
      schedule = _workoutData!['days'] as List<dynamic>;
    } else if (_workoutData!['workout_schedule'] != null) {
      schedule = _workoutData!['workout_schedule'] as List<dynamic>;
    } else {
      print('[WORKOUT_DETAILS] ❌ Nenhuma estrutura de cronograma encontrada!');
      return [
        _buildCard(
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Nenhum cronograma de treino encontrado.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      ];
    }

    // Filtrar apenas os dias que devem ser mostrados baseado no daysPerWeek do usuário
    int maxDays = widget.plan.daysPerWeek;
    List<dynamic> filteredSchedule = schedule.take(maxDays).toList();

    return filteredSchedule.asMap().entries.map((entry) {
      int index = entry.key;
      var dayData = entry.value;

      // Cores alternadas: par = cinza claro, ímpar = branco
      Color cardBackgroundColor = index % 2 == 0
          ? Colors.grey[100]!
          : Colors.white;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dia e Foco - com label simplificado
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dia ${dayData['day']?.toString() ?? (index + 1).toString()}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          // Label simplificado
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.plan.workoutType == 'home'
                                  ? Colors.blue[100]
                                  : Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.plan.workoutType == 'home'
                                  ? 'Casa'
                                  : 'Academia',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: widget.plan.workoutType == 'home'
                                    ? Colors.blue[700]
                                    : Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (dayData['focus'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          dayData['focus']?.toString() ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Guia do Treino
                _buildWorkoutGuide(dayData),

                const SizedBox(height: 16),

                // Lista de Exercícios do Dia
                _buildDayExercises(dayData),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildWorkoutGuide(Map<String, dynamic> dayData) {
    String dayName = dayData['day']?.toString() ?? 'Dia';
    String focus = dayData['focus']?.toString() ?? '';

    // Verificar se é treino de casa ou academia baseado no tipo do plano
    bool isHomeWorkout = widget.plan.workoutType == 'home';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
              const SizedBox(width: 8),
              Text(
                'Guia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Nome do dia
          Text(
            dayName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 8),

          if (isHomeWorkout) ...[
            // Para treino em casa: mostrar exercícios específicos
            _buildHomeWorkoutGuide(dayData),
          ] else ...[
            // Para academia: mostrar grupos musculares e quantidades
            _buildGymWorkoutGuide(focus),
          ],
        ],
      ),
    );
  }

  Widget _buildHomeWorkoutGuide(Map<String, dynamic> dayData) {
    List<String> homeExercises = [
      'Flexão de braços',
      'Abdominal',
      'Polichinelo',
      'Agachamento',
      'Prancha',
      'Burpee',
      'Mountain Climber',
      'Caminhada',
    ];

    // Tentar pegar exercícios dos dados reais se existirem
    if (dayData['exercises'] != null) {
      List<dynamic> exercises = dayData['exercises'] as List<dynamic>;
      List<String> exerciseNames = exercises
          .map((ex) => ex['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .take(6) // Máximo 6 exercícios
          .toList();

      if (exerciseNames.isNotEmpty) {
        homeExercises = exerciseNames;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: homeExercises
          .take(6)
          .map(
            (exercise) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    exercise,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildGymWorkoutGuide(String focus) {
    print('[DEBUG] Focus recebido: "$focus"'); // Debug
    String focusLower = focus.toLowerCase();

    // Mapeamento mais abrangente para detectar grupos musculares
    Map<String, String> gymGuides = {
      'peito':
          'Peito e Tríceps\n• 3 exercícios para peito\n• 2 exercícios para tríceps',
      'tricep':
          'Peito e Tríceps\n• 3 exercícios para peito\n• 2 exercícios para tríceps',
      'costas':
          'Costas e Bíceps\n• 4 exercícios para costas\n• 2 exercícios para bíceps',
      'costa':
          'Costas e Bíceps\n• 4 exercícios para costas\n• 2 exercícios para bíceps',
      'bicep':
          'Costas e Bíceps\n• 4 exercícios para costas\n• 2 exercícios para bíceps',
      'pernas':
          'Pernas e Glúteos\n• 4 exercícios para pernas\n• 2 exercícios para glúteos',
      'perna':
          'Pernas e Glúteos\n• 4 exercícios para pernas\n• 2 exercícios para glúteos',
      'quadricep':
          'Pernas e Glúteos\n• 4 exercícios para pernas\n• 2 exercícios para glúteos',
      'gluteo':
          'Pernas e Glúteos\n• 4 exercícios para pernas\n• 2 exercícios para glúteos',
      'ombros':
          'Ombros e Core\n• 3 exercícios para ombros\n• 2 exercícios para core',
      'ombro':
          'Ombros e Core\n• 3 exercícios para ombros\n• 2 exercícios para core',
      'deltoid':
          'Ombros e Core\n• 3 exercícios para ombros\n• 2 exercícios para core',
      'corpo':
          'Corpo Inteiro\n• 2 exercícios superiores\n• 2 exercícios inferiores\n• 1 exercício cardio',
      'full':
          'Corpo Inteiro\n• 2 exercícios superiores\n• 2 exercícios inferiores\n• 1 exercício cardio',
      'cardio':
          'Cardio e Core\n• 3 exercícios de cardio\n• 2 exercícios de core',
      'abdom':
          'Core e Abdômen\n• 4 exercícios para core\n• 2 exercícios funcionais',
      // Adicionar mais opções baseadas nos dados que você mostrou
      'treino a':
          'Peito e Tríceps\n• 3 exercícios para peito\n• 2 exercícios para tríceps',
      'treino b':
          'Costas e Bíceps\n• 4 exercícios para costas\n• 2 exercícios para bíceps',
      'treino c':
          'Pernas e Glúteos\n• 4 exercícios para pernas\n• 2 exercícios para glúteos',
    };

    String guideText =
        'Peito e Tríceps\n• 3 exercícios para peito\n• 2 exercícios para tríceps'; // Default para academia

    // Tentar encontrar o guia específico
    for (String key in gymGuides.keys) {
      if (focusLower.contains(key)) {
        guideText = gymGuides[key]!;
        print('[DEBUG] Match encontrado: $key -> ${gymGuides[key]}');
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: guideText
          .split('\n')
          .map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                line,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: line.startsWith('•')
                      ? FontWeight.normal
                      : FontWeight.w600,
                  color: line.startsWith('•')
                      ? Colors.grey[700]
                      : Colors.green[700],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _convertPostgreSQLToJson(String pgString) {
    try {
      print('[WORKOUT_DETAILS] 🔧 Iniciando conversão PostgreSQL para JSON...');
      print(
        '[WORKOUT_DETAILS] 📝 Entrada (primeiros 500 chars): ${pgString.substring(0, pgString.length > 500 ? 500 : pgString.length)}',
      );

      // Se já é um JSON válido, retornar como está
      try {
        json.decode(pgString);
        print('[WORKOUT_DETAILS] ✅ Já é JSON válido!');
        return pgString;
      } catch (e) {
        print('[WORKOUT_DETAILS] 🔄 Não é JSON válido, tentando converter...');
      }

      String jsonString = pgString;

      // Normalizar espaços e quebras de linha
      jsonString = jsonString.replaceAll(RegExp(r'\s+'), ' ');

      // Adicionar aspas duplas nas chaves
      jsonString = jsonString.replaceAllMapped(
        RegExp(r'(\w+)\s*:'),
        (match) => '"${match.group(1)}":',
      );

      // Corrigir valores de string
      jsonString = jsonString.replaceAllMapped(
        RegExp(r':\s*([^"\[\{][^,\]\}]*?)(?=[,\]\}])'),
        (match) {
          String value = match.group(1)!.trim();
          // Se for número, boolean ou null, não adicionar aspas
          if (RegExp(r'^[\d.]+$').hasMatch(value) ||
              value == 'true' ||
              value == 'false' ||
              value == 'null' ||
              value.startsWith('[') ||
              value.startsWith('{')) {
            return ': $value';
          }
          return ': "$value"';
        },
      );

      // Limpar possíveis aspas duplas desnecessárias
      jsonString = jsonString.replaceAll('""', '"');

      print(
        '[WORKOUT_DETAILS] ✅ JSON convertido (primeiros 500 chars): ${jsonString.substring(0, jsonString.length > 500 ? 500 : jsonString.length)}',
      );
      return jsonString;
    } catch (e) {
      print('[WORKOUT_DETAILS] ❌ Erro na conversão PostgreSQL: $e');
      return pgString;
    }
  }

  String _cleanString(String value) {
    // Remove aspas no início e no fim
    String result = value.trim();
    if ((result.startsWith('"') && result.endsWith('"')) ||
        (result.startsWith("'") && result.endsWith("'"))) {
      return result.substring(1, result.length - 1);
    }
    return result;
  }

  Map<String, dynamic> _extractDataManually(String rawData) {
    try {
      print('[WORKOUT_DETAILS] 🛠️ Extraindo dados manualmente...');
      print('[WORKOUT_DETAILS] 📏 Tamanho dos dados: ${rawData.length} chars');

      // Primeiro, tentar extrair usando JSON decode direto
      try {
        var decoded = json.decode(rawData);
        if (decoded['workout_schedule'] != null) {
          List<Map<String, dynamic>> workoutSchedule =
              List<Map<String, dynamic>>.from(decoded['workout_schedule']);
          print(
            '[WORKOUT_DETAILS] ✅ JSON decode direto funcionou! ${workoutSchedule.length} dias extraídos',
          );
          return {
            'plan_name': decoded['plan_name'] ?? widget.plan.planName,
            'plan_summary': decoded['plan_summary'] ?? 'Resumo não disponível',
            'workout_schedule': workoutSchedule,
            'important_notes': List<String>.from(
              decoded['important_notes'] ?? [],
            ),
            'progression_tips':
                decoded['progression_tips'] ?? 'Aumente gradualmente',
          };
        }
      } catch (e) {
        print('[WORKOUT_DETAILS] 🔄 JSON decode falhou: $e');
      }

      // Se JSON direto falhou, usar método manual mais robusto
      print('[WORKOUT_DETAILS] 🔧 Tentando extração manual avançada...');

      // Extrair dados básicos com regex melhoradas
      final planNameMatch = RegExp(
        r'plan_name["\s]*:\s*["\s]*([^",}]+)',
      ).firstMatch(rawData);
      final planSummaryMatch = RegExp(
        r'plan_summary["\s]*:\s*["\s]*([^",}]+)',
      ).firstMatch(rawData);
      final progressionTipsMatch = RegExp(
        r'progression_tips["\s]*:\s*["\s]*([^",}]+)',
      ).firstMatch(rawData);

      // Extrair notas importantes
      List<String> importantNotes = [];
      final notesMatch = RegExp(
        r'important_notes["\s]*:\s*\[([^\]]*)\]',
        dotAll: true,
      ).firstMatch(rawData);
      if (notesMatch != null) {
        String notesStr = notesMatch.group(1)!;
        // Dividir por vírgulas respeitando aspas
        importantNotes = notesStr
            .split(',')
            .map((note) => _cleanString(note.trim()))
            .where((note) => note.isNotEmpty)
            .toList();
      }

      // Extrair cronograma de treinos - método mais robusto
      List<Map<String, dynamic>> workoutSchedule = [];

      // Encontrar todos os blocos de dias usando regex
      final dayPattern = RegExp(
        r'\{[^{}]*day[^{}]*?exercises[^{}]*?\[[^\]]*?\][^{}]*?\}',
        dotAll: true,
      );
      final dayMatches = dayPattern.allMatches(rawData);

      print(
        '[WORKOUT_DETAILS] 🔍 Encontrados ${dayMatches.length} blocos de dias potenciais',
      );

      for (var dayMatch in dayMatches) {
        String dayBlock = dayMatch.group(0)!;
        print(
          '[WORKOUT_DETAILS] 📋 Processando bloco: ${dayBlock.substring(0, dayBlock.length > 100 ? 100 : dayBlock.length)}...',
        );

        // Extrair informações do dia
        final dayName = RegExp(
          r'day["\s]*:\s*["\s]*([^",}]+)',
        ).firstMatch(dayBlock)?.group(1)?.trim();
        final focus = RegExp(
          r'focus["\s]*:\s*["\s]*([^",}]+)',
        ).firstMatch(dayBlock)?.group(1)?.trim();

        if (dayName != null) {
          print('[WORKOUT_DETAILS] ✅ Dia encontrado: $dayName');

          // Extrair exercícios deste dia
          List<Map<String, dynamic>> exercises = [];

          // Encontrar a seção de exercícios
          final exercisesMatch = RegExp(
            r'exercises["\s]*:\s*\[(.*?)\]',
            multiLine: true,
            dotAll: true,
          ).firstMatch(dayBlock);
          if (exercisesMatch != null) {
            String exercisesStr = exercisesMatch.group(1)!;
            print(
              '[WORKOUT_DETAILS] 🏋️ Processando exercícios: ${exercisesStr.length} chars',
            );

            // Extrair cada exercício individual
            final exerciseBlocks = RegExp(
              r'\{[^{}]*\}',
              multiLine: true,
            ).allMatches(exercisesStr);

            for (var exBlock in exerciseBlocks) {
              String exerciseStr = exBlock.group(0)!;

              // Extrair campos do exercício
              final nameMatch = RegExp(
                r'name["\s]*:\s*["\s]*([^",}]+)',
              ).firstMatch(exerciseStr);

              if (nameMatch != null) {
                final setsMatch = RegExp(
                  r'sets["\s]*:\s*["\s]*([^",}]+)',
                ).firstMatch(exerciseStr);
                final repsMatch = RegExp(
                  r'reps["\s]*:\s*["\s]*([^",}]+)',
                ).firstMatch(exerciseStr);
                final restMatch = RegExp(
                  r'rest["\s]*:\s*["\s]*([^",}]+)',
                ).firstMatch(exerciseStr);
                final instructionsMatch = RegExp(
                  r'instructions["\s]*:\s*["\s]*([^",}]+)',
                ).firstMatch(exerciseStr);
                final equipmentMatch = RegExp(
                  r'equipment["\s]*:\s*["\s]*([^",}]+)',
                ).firstMatch(exerciseStr);

                Map<String, dynamic> exercise = {
                  'name': _cleanString(nameMatch.group(1)!),
                  'sets': setsMatch != null
                      ? _cleanString(setsMatch.group(1)!)
                      : '3',
                  'reps': repsMatch != null
                      ? _cleanString(repsMatch.group(1)!)
                      : '10-15',
                  'rest': restMatch != null
                      ? _cleanString(restMatch.group(1)!)
                      : '60 segundos',
                  'instructions': instructionsMatch != null
                      ? _cleanString(instructionsMatch.group(1)!)
                      : 'Execute conforme orientação',
                  'equipment': equipmentMatch != null
                      ? _cleanString(equipmentMatch.group(1)!)
                      : 'Peso corporal',
                };

                exercises.add(exercise);
                print('[WORKOUT_DETAILS] 💪 Exercício: ${exercise['name']}');
              }
            }
          }

          workoutSchedule.add({
            'day': _cleanString(dayName),
            'focus': focus != null ? _cleanString(focus) : 'Treino completo',
            'exercises': exercises,
          });

          print(
            '[WORKOUT_DETAILS] 📋 Dia $dayName: ${exercises.length} exercícios extraídos',
          );
        }
      }

      print(
        '[WORKOUT_DETAILS] 📊 Total extraído: ${workoutSchedule.length} dias de treino',
      );
      print(
        '[WORKOUT_DETAILS] 📝 Total extraído: ${importantNotes.length} notas importantes',
      );

      // Debug detalhado
      for (int i = 0; i < workoutSchedule.length; i++) {
        var day = workoutSchedule[i];
        var exercises = day['exercises'] as List<dynamic>;
        print(
          '[WORKOUT_DETAILS] 📅 ${day['day']}: ${exercises.length} exercícios',
        );
        for (int j = 0; j < exercises.length && j < 3; j++) {
          var exercise = exercises[j] as Map<String, dynamic>;
          print('[WORKOUT_DETAILS]    ${j + 1}. ${exercise['name']}');
        }
        if (exercises.length > 3) {
          print(
            '[WORKOUT_DETAILS]    ... e mais ${exercises.length - 3} exercícios',
          );
        }
      }

      return {
        'plan_name': _cleanString(
          planNameMatch?.group(1) ?? widget.plan.planName,
        ),
        'plan_summary': _cleanString(
          planSummaryMatch?.group(1) ?? 'Resumo não disponível',
        ),
        'workout_schedule': workoutSchedule,
        'important_notes': importantNotes.isEmpty
            ? ['Dados extraídos com sucesso']
            : importantNotes,
        'progression_tips': _cleanString(
          progressionTipsMatch?.group(1) ??
              'Aumente gradualmente a intensidade',
        ),
      };
    } catch (e) {
      print('[WORKOUT_DETAILS] ❌ Erro na extração manual: $e');
      return {
        'plan_name': widget.plan.planName,
        'plan_summary': 'Erro ao carregar dados',
        'workout_schedule': <Map<String, dynamic>>[],
        'important_notes': ['Erro ao carregar dados do treino'],
        'progression_tips': 'Recarregue o treino',
      };
    }
  }

  Widget _buildDayExercises(Map<String, dynamic> dayData) {
    // Verificar se há exercícios no dia
    if (dayData['exercises'] == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Nenhum exercício específico encontrado para este dia.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    List<dynamic> exercises = dayData['exercises'] as List<dynamic>;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: Colors.green[700], size: 24),
              const SizedBox(width: 8),
              Text(
                'Exercícios do Dia (${exercises.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista de exercícios
          ...exercises.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> exercise = entry.value as Map<String, dynamic>;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome do exercício
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[600],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          exercise['name']?.toString() ??
                              'Exercício ${index + 1}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Detalhes do exercício
                  if (exercise['sets'] != null || exercise['reps'] != null) ...[
                    Row(
                      children: [
                        if (exercise['sets'] != null) ...[
                          Icon(Icons.repeat, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${exercise['sets']} séries',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                        if (exercise['sets'] != null &&
                            exercise['reps'] != null)
                          const SizedBox(width: 16),
                        if (exercise['reps'] != null) ...[
                          Icon(
                            Icons.fitness_center,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${exercise['reps']} rep.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Equipamento
                  if (exercise['equipment'] != null) ...[
                    Row(
                      children: [
                        Icon(Icons.build, size: 16, color: Colors.orange[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Equipamento: ${exercise['equipment']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Instruções
                  if (exercise['instructions'] != null) ...[
                    Text(
                      'Como fazer:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise['instructions']?.toString() ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],

                  // Descanso
                  if (exercise['rest'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer, size: 14, color: Colors.purple[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Descanso: ${exercise['rest']}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.purple[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
