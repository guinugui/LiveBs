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
      print('[WORKOUT_DETAILS] 📄 workoutData content: ${widget.plan.workoutData}');
      
      if (widget.plan.workoutData.isNotEmpty && widget.plan.workoutData != '{}') {
        String jsonString = widget.plan.workoutData;
        
        print('[WORKOUT_DETAILS] 🔧 Tentando corrigir JSON malformado do PostgreSQL...');
        
        // Converter formato PostgreSQL para JSON válido
        jsonString = _convertPostgreSQLToJson(jsonString);
        
        try {
          _workoutData = json.decode(jsonString);
        } catch (e) {
          print('[WORKOUT_DETAILS] 🔄 Parse direto falhou, tentando método alternativo...');
          
          // Se ainda não funcionar, tentar extrair dados manualmente
          _workoutData = _extractDataManually(widget.plan.workoutData);
        }
        
        print('[WORKOUT_DETAILS] ✅ Parse bem-sucedido: ${_workoutData?.keys}');
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
    final schedule = _workoutData!['workout_schedule'] as List<dynamic>;
    
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
                      dayData['day'] ?? 'Dia do Treino',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    if (dayData['focus'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        dayData['focus'],
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
              
              // Lista de Exercícios
              if (dayData['exercises'] != null)
                ...((dayData['exercises'] as List<dynamic>).map((exercise) {
                  return _buildExerciseCard(exercise);
                }).toList()),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome do exercício
          Text(
            exercise['name'] ?? 'Exercício',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Informações do exercício (séries, reps, descanso)
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (exercise['sets'] != null)
                _buildExerciseInfo(Icons.repeat, 'Séries', exercise['sets']),
              if (exercise['reps'] != null)
                _buildExerciseInfo(Icons.fitness_center, 'Reps', exercise['reps']),
              if (exercise['rest'] != null)
                _buildExerciseInfo(Icons.timer, 'Descanso', exercise['rest']),
            ],
          ),
          
          // Instruções
          if (exercise['instructions'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exercise['instructions'],
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Equipamento
          if (exercise['equipment'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.build, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Equipamento: ${exercise['equipment']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseInfo(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.orange),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
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
      // Converter formato PostgreSQL para JSON válido
      String jsonString = pgString;
      
      // Adicionar aspas duplas nas chaves (exceto quando já tem aspas)
      jsonString = jsonString.replaceAllMapped(
        RegExp(r'([a-zA-Z_][a-zA-Z0-9_]*):'),
        (match) => '"${match.group(1)}":',
      );
      
      // Adicionar aspas duplas em valores string (não números, booleanos ou arrays/objetos)
      jsonString = jsonString.replaceAllMapped(
        RegExp(r': ([^"{\[\]0-9true false][^,}\]]*[^,}\]\s])'),
        (match) {
          String value = match.group(1)!.trim();
          // Se já tem aspas ou é um número/boolean, não alterar
          if (value.startsWith('"') || 
              value.startsWith('[') || 
              value.startsWith('{') ||
              RegExp(r'^\d+(\.\d+)?$').hasMatch(value) ||
              value == 'true' || 
              value == 'false' ||
              value == 'null') {
            return match.group(0)!;
          }
          return ': "$value"';
        },
      );
      
      // Corrigir arrays
      jsonString = jsonString.replaceAllMapped(
        RegExp(r'\[([^\]]*)\]'),
        (match) {
          String content = match.group(1)!;
          if (content.trim().isEmpty) return '[]';
          
          // Separar itens do array e adicionar aspas se necessário
          List<String> items = content.split(',').map((item) {
            String trimmed = item.trim();
            if (trimmed.startsWith('"') || 
                RegExp(r'^\d+(\.\d+)?$').hasMatch(trimmed) ||
                trimmed == 'true' || 
                trimmed == 'false' ||
                trimmed == 'null') {
              return trimmed;
            }
            return '"$trimmed"';
          }).toList();
          
          return '[${items.join(', ')}]';
        },
      );
      
      print('[WORKOUT_DETAILS] 🔄 JSON corrigido: ${jsonString.substring(0, 200)}...');
      return jsonString;
    } catch (e) {
      print('[WORKOUT_DETAILS] ❌ Erro na conversão: $e');
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
      
      // Extrair dados básicos com regex
      final planNameMatch = RegExp(r'plan_name:\s*([^,}]+)').firstMatch(rawData);
      final planSummaryMatch = RegExp(r'plan_summary:\s*([^,}]+)').firstMatch(rawData);
      final progressionTipsMatch = RegExp(r'progression_tips:\s*([^,}]+)').firstMatch(rawData);
      
      // Extrair notas importantes
      List<String> importantNotes = [];
      final notesMatch = RegExp(r'important_notes:\s*\[([^\]]+)\]').firstMatch(rawData);
      if (notesMatch != null) {
        String notesStr = notesMatch.group(1)!;
        importantNotes = notesStr.split(',').map((note) {
          String clean = note.trim();
          if (clean.startsWith('"') && clean.endsWith('"')) {
            clean = clean.substring(1, clean.length - 1);
          }
          return clean;
        }).toList();
      }
      
      // Extrair cronograma de treinos
      List<Map<String, dynamic>> workoutSchedule = [];
      final scheduleMatches = RegExp(r'\{day:\s*([^,]+),\s*focus:\s*([^,]+),\s*exercises:\s*\[([^\]]+)\]').allMatches(rawData);
      
      for (var match in scheduleMatches) {
        String day = _cleanString(match.group(1)?.trim() ?? '');
        String focus = _cleanString(match.group(2)?.trim() ?? '');
        String exercisesStr = match.group(3) ?? '';
        
        // Extrair exercícios
        List<Map<String, dynamic>> exercises = [];
        final exerciseMatches = RegExp(r'\{name:\s*([^,]+),\s*reps:\s*([^,]+),\s*rest:\s*([^,]+),\s*sets:\s*([^,]+),\s*equipment:\s*([^,]+),\s*instructions:\s*([^}]+)\}').allMatches(exercisesStr);
        
        for (var exMatch in exerciseMatches) {
          exercises.add({
            'name': _cleanString(exMatch.group(1)?.trim() ?? ''),
            'reps': _cleanString(exMatch.group(2)?.trim() ?? ''),
            'rest': _cleanString(exMatch.group(3)?.trim() ?? ''),
            'sets': _cleanString(exMatch.group(4)?.trim() ?? ''),
            'equipment': _cleanString(exMatch.group(5)?.trim() ?? ''),
            'instructions': _cleanString(exMatch.group(6)?.trim() ?? ''),
          });
        }
        
        if (day.isNotEmpty && focus.isNotEmpty) {
          workoutSchedule.add({
            'day': day,
            'focus': focus,
            'exercises': exercises,
          });
        }
      }
      
      print('[WORKOUT_DETAILS] 📊 Extraídos ${workoutSchedule.length} dias de treino');
      print('[WORKOUT_DETAILS] 📝 Extraídas ${importantNotes.length} notas importantes');
      
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
        'workout_schedule': [],
        'important_notes': ['Erro ao carregar dados do treino'],
        'progression_tips': 'Recarregue o treino'
      };
    }
  }
}