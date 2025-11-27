import 'package:flutter/material.dart';
import '../../models/workout_plan.dart';
import 'dart:convert';

class WorkoutPlanDetailsPage extends StatefulWidget {
  final WorkoutPlan plan;

  const WorkoutPlanDetailsPage({
    super.key,
    required this.plan,
  });

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
      print('[WORKOUT_DETAILS] 📊 workoutData length: ${widget.plan.workoutData.length}');
      print('[WORKOUT_DETAILS] 📊 workoutData tipo: ${widget.plan.workoutData.runtimeType}');
      print('[WORKOUT_DETAILS] 📄 workoutData content (300 chars): ${widget.plan.workoutData.substring(0, widget.plan.workoutData.length > 300 ? 300 : widget.plan.workoutData.length)}');
      
      if (widget.plan.workoutData.isNotEmpty && widget.plan.workoutData != '{}') {
        String rawData = widget.plan.workoutData;
        
        // PRIMEIRO: Tentar JSON parse direto (backend corrigido deve enviar JSON string válido)
        try {
          print('[WORKOUT_DETAILS] 🎯 Tentando JSON parse direto...');
          _workoutData = json.decode(rawData);
          print('[WORKOUT_DETAILS] ✅ JSON parse direto bem-sucedido!');
          
          // Verificar se days ou workout_schedule existe (days é a estrutura correta)
          List<dynamic>? schedule;
          
          if (_workoutData != null && _workoutData!['days'] != null) {
            schedule = _workoutData!['days'] as List<dynamic>;
            print('[WORKOUT_DETAILS] 🎉 SUCESSO: ${schedule.length} dias encontrados em days!');
          } else if (_workoutData != null && _workoutData!['workout_schedule'] != null) {
            schedule = _workoutData!['workout_schedule'] as List<dynamic>;
            print('[WORKOUT_DETAILS] 🎉 SUCESSO: ${schedule.length} dias encontrados no workout_schedule (legado)!');
            // Converter para days para padronizar
            _workoutData!['days'] = schedule;
            _workoutData!.remove('workout_schedule');
          }
          
          if (schedule != null) {
            // Log detalhado de cada dia
            for (int i = 0; i < schedule.length; i++) {
              var day = schedule[i];
              if (day is Map && day['exercises'] is List) {
                var exercises = day['exercises'] as List;
                print('[WORKOUT_DETAILS] 📅 Dia ${i + 1} (${day['day']}): ${exercises.length} exercícios');
              }
            }
            return; // Sucesso! Não precisa tentar outros métodos
          } else {
            print('[WORKOUT_DETAILS] ⚠️ Nem days nem workout_schedule encontrados no JSON válido');
          }
        } catch (e) {
          print('[WORKOUT_DETAILS] ❌ JSON parse direto falhou: $e');
        }
        
        // SEGUNDO: Tentar converter formato PostgreSQL
        print('[WORKOUT_DETAILS] 🔧 Tentando conversão PostgreSQL para JSON...');
        try {
          String jsonString = _convertPostgreSQLToJson(rawData);
          _workoutData = json.decode(jsonString);
          print('[WORKOUT_DETAILS] ✅ Conversão PostgreSQL bem-sucedida');
          
          if (_workoutData != null && _workoutData!['workout_schedule'] != null) {
            var schedule = _workoutData!['workout_schedule'] as List<dynamic>;
            print('[WORKOUT_DETAILS] 🎉 ${schedule.length} dias encontrados após conversão PostgreSQL!');
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
      print('[WORKOUT_DETAILS] 📄 Dados problemáticos: ${widget.plan.workoutData}');
      
      // Como fallback, tentar criar dados mock para mostrar algo
      _workoutData = {
        'plan_name': widget.plan.planName,
        'plan_summary': 'Dados de treino não puderam ser carregados corretamente.',
        'workout_schedule': [],
        'important_notes': ['Erro ao carregar dados do treino'],
        'progression_tips': 'Recarregue o treino ou entre em contato com o suporte.'
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
          if (_workoutData!['workout_schedule'] != null) ...[
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
                          const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Expanded(child: Text(note, style: const TextStyle(fontSize: 14))),
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
                  color: widget.plan.workoutType == 'home' ? Colors.blue[100] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.plan.workoutType == 'home' ? Icons.home : Icons.fitness_center,
                  color: widget.plan.workoutType == 'home' ? Colors.blue : Colors.orange,
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
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      widget.plan.workoutType == 'home' ? 'Treino em Casa' : 'Treino na Academia',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
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
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWorkoutSchedule() {
    final schedule = _workoutData!['days'] as List<dynamic>;
    
    return schedule.map((dayData) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dia e Foco
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
                    Text(
                      'Dia ${dayData['day']?.toString() ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
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
              
              // NOVO: Mini Manual Didático
              _buildSimpleWorkoutGuide(dayData),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildSimpleWorkoutGuide(Map<String, dynamic> dayData) {
    String focus = dayData['focus']?.toString() ?? '';
    Map<String, dynamic> guide = _generateWorkoutGuide(focus);
    
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
              Icon(Icons.fitness_center, color: Colors.blue[700], size: 24),
              const SizedBox(width: 8),
              Text(
                'Mini Manual do Treino',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            guide['instructions'],
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Grupos Musculares:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: guide['muscle_groups'].map<Widget>((group) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.arrow_right, color: Colors.green[600], size: 16),
                    const SizedBox(width: 4),
                    Expanded(child: Text(group?.toString() ?? '', style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )
            ).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning, color: Colors.orange[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    guide['safety_tips'],
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _generateWorkoutGuide(String focus) {
    String lowerFocus = focus.toLowerCase();
    
    if (lowerFocus.contains('peito') || lowerFocus.contains('trícep')) {
      return {
        'instructions': 'Foque no desenvolvimento do peitoral e tríceps! Faça 3-4 exercícios de peito (como supino, crucifixo) e 2-3 de tríceps. Use cargas que permitam 8-12 repetições com boa execução.',
        'muscle_groups': [
          'Peitoral maior e menor',
          'Tríceps braquial',
          'Deltóide anterior (auxiliar)',
        ],
        'safety_tips': 'Mantenha boa postura, controle a descida do peso e evite trancar completamente os cotovelos. Aguarde 4 horas antes de praticar esportes.',
      };
    } else if (lowerFocus.contains('costa') || lowerFocus.contains('bícep')) {
      return {
        'instructions': 'Trabalhe as costas e bíceps! Faça 3-4 exercícios de costa (como puxada, remada) e 2-3 de bíceps. Foque na retração das escápulas e no controle do movimento.',
        'muscle_groups': [
          'Latíssimo do dorso',
          'Rombóides e trapézio',
          'Bíceps braquial',
          'Músculos posteriores do ombro',
        ],
        'safety_tips': 'Mantenha o core contraído, evite usar o impulso e concentre-se na contração dos músculos alvo. Aguarde 4 horas antes de praticar esportes.',
      };
    } else if (lowerFocus.contains('perna') || lowerFocus.contains('inferior')) {
      return {
        'instructions': 'Dia das pernas! Trabalhe quadríceps, posteriores e glúteos. Faça 2-3 exercícios compostos (agachamento, leg press) e 2-3 exercícios isolados.',
        'muscle_groups': [
          'Quadríceps femoral',
          'Isquiotibiais (posteriores)',
          'Glúteos (máximo, médio)',
          'Panturrilhas',
        ],
        'safety_tips': 'Mantenha joelhos alinhados, desça até onde a flexibilidade permitir e use amplitude completa. Aguarde 4 horas antes de praticar esportes.',
      };
    } else if (lowerFocus.contains('ombro') || lowerFocus.contains('deltóide')) {
      return {
        'instructions': 'Foque no desenvolvimento dos ombros! Faça 3-4 exercícios variados (desenvolvimento, elevações laterais e posteriores). Use cargas moderadas com foco na técnica.',
        'muscle_groups': [
          'Deltóide anterior, medial e posterior',
          'Trapézio superior',
          'Manguito rotador (estabilização)',
        ],
        'safety_tips': 'Evite movimentos bruscos, mantenha ombros longe das orelhas e não force amplitude excessiva. Aguarde 4 horas antes de praticar esportes.',
      };
    } else {
      // Treino geral ou não identificado
      return {
        'instructions': 'Treino completo! Trabalhe os principais grupos musculares de forma equilibrada. Priorize movimentos compostos e mantenha boa execução em todos os exercícios.',
        'muscle_groups': [
          'Músculos do core (abdome e lombar)',
          'Membros superiores',
          'Membros inferiores',
        ],
        'safety_tips': 'Faça aquecimento adequado, mantenha hidratação e respeite seus limites. Aguarde 4 horas antes de praticar esportes.',
      };
    }
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _convertPostgreSQLToJson(String pgString) {
    try {
      print('[WORKOUT_DETAILS] 🔧 Iniciando conversão PostgreSQL para JSON...');
      print('[WORKOUT_DETAILS] 📝 Entrada (primeiros 500 chars): ${pgString.substring(0, pgString.length > 500 ? 500 : pgString.length)}');
      
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
      
      print('[WORKOUT_DETAILS] ✅ JSON convertido (primeiros 500 chars): ${jsonString.substring(0, jsonString.length > 500 ? 500 : jsonString.length)}');
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
          List<Map<String, dynamic>> workoutSchedule = List<Map<String, dynamic>>.from(decoded['workout_schedule']);
          print('[WORKOUT_DETAILS] ✅ JSON decode direto funcionou! ${workoutSchedule.length} dias extraídos');
          return {
            'plan_name': decoded['plan_name'] ?? widget.plan.planName,
            'plan_summary': decoded['plan_summary'] ?? 'Resumo não disponível',
            'workout_schedule': workoutSchedule,
            'important_notes': List<String>.from(decoded['important_notes'] ?? []),
            'progression_tips': decoded['progression_tips'] ?? 'Aumente gradualmente'
          };
        }
      } catch (e) {
        print('[WORKOUT_DETAILS] 🔄 JSON decode falhou: $e');
      }
      
      // Se JSON direto falhou, usar método manual mais robusto
      print('[WORKOUT_DETAILS] 🔧 Tentando extração manual avançada...');
      
      // Extrair dados básicos com regex melhoradas
      final planNameMatch = RegExp(r'plan_name["\s]*:\s*["\s]*([^",}]+)').firstMatch(rawData);
      final planSummaryMatch = RegExp(r'plan_summary["\s]*:\s*["\s]*([^",}]+)').firstMatch(rawData);
      final progressionTipsMatch = RegExp(r'progression_tips["\s]*:\s*["\s]*([^",}]+)').firstMatch(rawData);
      
      // Extrair notas importantes
      List<String> importantNotes = [];
      final notesMatch = RegExp(r'important_notes["\s]*:\s*\[([^\]]*)\]', dotAll: true).firstMatch(rawData);
      if (notesMatch != null) {
        String notesStr = notesMatch.group(1)!;
        // Dividir por vírgulas respeitando aspas
        importantNotes = notesStr.split(',')
            .map((note) => _cleanString(note.trim()))
            .where((note) => note.isNotEmpty)
            .toList();
      }
      
      // Extrair cronograma de treinos - método mais robusto
      List<Map<String, dynamic>> workoutSchedule = [];
      
      // Encontrar todos os blocos de dias usando regex
      final dayPattern = RegExp(r'\{[^{}]*day[^{}]*?exercises[^{}]*?\[[^\]]*?\][^{}]*?\}', dotAll: true);
      final dayMatches = dayPattern.allMatches(rawData);
      
      print('[WORKOUT_DETAILS] 🔍 Encontrados ${dayMatches.length} blocos de dias potenciais');
      
      for (var dayMatch in dayMatches) {
        String dayBlock = dayMatch.group(0)!;
        print('[WORKOUT_DETAILS] 📋 Processando bloco: ${dayBlock.substring(0, dayBlock.length > 100 ? 100 : dayBlock.length)}...');
        
        // Extrair informações do dia
        final dayName = RegExp(r'day["\s]*:\s*["\s]*([^",}]+)').firstMatch(dayBlock)?.group(1)?.trim();
        final focus = RegExp(r'focus["\s]*:\s*["\s]*([^",}]+)').firstMatch(dayBlock)?.group(1)?.trim();
        
        if (dayName != null) {
          print('[WORKOUT_DETAILS] ✅ Dia encontrado: $dayName');
          
          // Extrair exercícios deste dia
          List<Map<String, dynamic>> exercises = [];
          
          // Encontrar a seção de exercícios
          final exercisesMatch = RegExp(r'exercises["\s]*:\s*\[(.*?)\]', multiLine: true, dotAll: true).firstMatch(dayBlock);
          if (exercisesMatch != null) {
            String exercisesStr = exercisesMatch.group(1)!;
            print('[WORKOUT_DETAILS] 🏋️ Processando exercícios: ${exercisesStr.length} chars');
            
            // Extrair cada exercício individual
            final exerciseBlocks = RegExp(r'\{[^{}]*\}', multiLine: true).allMatches(exercisesStr);
            
            for (var exBlock in exerciseBlocks) {
              String exerciseStr = exBlock.group(0)!;
              
              // Extrair campos do exercício
              final nameMatch = RegExp(r'name["\s]*:\s*["\s]*([^",}]+)').firstMatch(exerciseStr);
              
              if (nameMatch != null) {
                final setsMatch = RegExp(r'sets["\s]*:\s*["\s]*([^",}]+)').firstMatch(exerciseStr);
                final repsMatch = RegExp(r'reps["\s]*:\s*["\s]*([^",}]+)').firstMatch(exerciseStr);
                final restMatch = RegExp(r'rest["\s]*:\s*["\s]*([^",}]+)').firstMatch(exerciseStr);
                final instructionsMatch = RegExp(r'instructions["\s]*:\s*["\s]*([^",}]+)').firstMatch(exerciseStr);
                final equipmentMatch = RegExp(r'equipment["\s]*:\s*["\s]*([^",}]+)').firstMatch(exerciseStr);
                
                Map<String, dynamic> exercise = {
                  'name': _cleanString(nameMatch.group(1)!),
                  'sets': setsMatch != null ? _cleanString(setsMatch.group(1)!) : '3',
                  'reps': repsMatch != null ? _cleanString(repsMatch.group(1)!) : '10-15',
                  'rest': restMatch != null ? _cleanString(restMatch.group(1)!) : '60 segundos',
                  'instructions': instructionsMatch != null ? _cleanString(instructionsMatch.group(1)!) : 'Execute conforme orientação',
                  'equipment': equipmentMatch != null ? _cleanString(equipmentMatch.group(1)!) : 'Peso corporal',
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
          
          print('[WORKOUT_DETAILS] 📋 Dia $dayName: ${exercises.length} exercícios extraídos');
        }
      }
      
      print('[WORKOUT_DETAILS] 📊 Total extraído: ${workoutSchedule.length} dias de treino');
      print('[WORKOUT_DETAILS] 📝 Total extraído: ${importantNotes.length} notas importantes');
      
      // Debug detalhado
      for (int i = 0; i < workoutSchedule.length; i++) {
        var day = workoutSchedule[i];
        var exercises = day['exercises'] as List<dynamic>;
        print('[WORKOUT_DETAILS] 📅 ${day['day']}: ${exercises.length} exercícios');
        for (int j = 0; j < exercises.length && j < 3; j++) {
          var exercise = exercises[j] as Map<String, dynamic>;
          print('[WORKOUT_DETAILS]    ${j + 1}. ${exercise['name']}');
        }
        if (exercises.length > 3) {
          print('[WORKOUT_DETAILS]    ... e mais ${exercises.length - 3} exercícios');
        }
      }
      
      return {
        'plan_name': _cleanString(planNameMatch?.group(1) ?? widget.plan.planName),
        'plan_summary': _cleanString(planSummaryMatch?.group(1) ?? 'Resumo não disponível'),
        'workout_schedule': workoutSchedule,
        'important_notes': importantNotes.isEmpty ? ['Dados extraídos com sucesso'] : importantNotes,
        'progression_tips': _cleanString(progressionTipsMatch?.group(1) ?? 'Aumente gradualmente a intensidade')
      };
    } catch (e) {
      print('[WORKOUT_DETAILS] ❌ Erro na extração manual: $e');
      return {
        'plan_name': widget.plan.planName,
        'plan_summary': 'Erro ao carregar dados',
        'workout_schedule': <Map<String, dynamic>>[],
        'important_notes': ['Erro ao carregar dados do treino'],
        'progression_tips': 'Recarregue o treino'
      };
    }
  }
}