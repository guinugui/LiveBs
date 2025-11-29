import 'package:flutter/material.dart';
import '../services/meal_plan_service.dart';

class MealPlanFormScreen extends StatefulWidget {
  const MealPlanFormScreen({super.key});

  @override
  State<MealPlanFormScreen> createState() => _MealPlanFormScreenState();
}

class _MealPlanFormScreenState extends State<MealPlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = MealPlanService();

  // Controllers
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  final _targetWeightController = TextEditingController();

  // Variáveis
  String _gender = 'male';
  String _activityLevel = 'moderate';
  String _goal = 'lose_weight';
  int _calculatedCalories = 2000;
  List<String> _selectedRestrictions = [];
  List<String> _selectedPreferences = [];
  bool _isLoading = false;

  final List<Map<String, String>> _restrictions = [
    {'value': 'lactose', 'label': 'Lactose'},
    {'value': 'gluten', 'label': 'Glúten'},
    {'value': 'nuts', 'label': 'Oleaginosas'},
    {'value': 'soy', 'label': 'Soja'},
    {'value': 'eggs', 'label': 'Ovos'},
  ];

  final List<Map<String, String>> _preferences = [
    {'value': 'low_carb', 'label': 'Low Carb'},
    {'value': 'vegetarian', 'label': 'Vegetariano'},
    {'value': 'vegan', 'label': 'Vegano'},
    {'value': 'paleo', 'label': 'Paleo'},
    {'value': 'keto', 'label': 'Cetogênica'},
  ];

  void _calculateCalories() {
    if (_weightController.text.isEmpty ||
        _heightController.text.isEmpty ||
        _ageController.text.isEmpty) {
      return;
    }

    final calories = _service.calculateDailyCalories(
      weight: double.parse(_weightController.text),
      height: double.parse(_heightController.text),
      age: int.parse(_ageController.text),
      gender: _gender,
      activityLevel: _activityLevel,
      goal: _goal,
    );

    setState(() {
      _calculatedCalories = calories;
    });
  }

  Future<void> _generateMealPlan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Gerar plano usando o serviço atualizado
      await _service.generateMealPlan();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Plano alimentar gerado com sucesso!'),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );

        // Voltar para a tela anterior ou navegar para a lista de planos
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao gerar plano: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Plano Alimentar')),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Gerando seu plano alimentar...'),
                  SizedBox(height: 8),
                  Text('Isso pode levar alguns segundos'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dados Pessoais',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            decoration: const InputDecoration(
                              labelText: 'Peso Atual (kg)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v!.isEmpty ? 'Campo obrigatório' : null,
                            onChanged: (_) => _calculateCalories(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _targetWeightController,
                            decoration: const InputDecoration(
                              labelText: 'Peso Meta (kg)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v!.isEmpty ? 'Campo obrigatório' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            decoration: const InputDecoration(
                              labelText: 'Altura (cm)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v!.isEmpty ? 'Campo obrigatório' : null,
                            onChanged: (_) => _calculateCalories(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            decoration: const InputDecoration(
                              labelText: 'Idade',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v!.isEmpty ? 'Campo obrigatório' : null,
                            onChanged: (_) => _calculateCalories(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Sexo',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'male',
                          child: Text('Masculino'),
                        ),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('Feminino'),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _gender = v!);
                        _calculateCalories();
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Atividade Física',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _activityLevel,
                      decoration: const InputDecoration(
                        labelText: 'Nível de Atividade',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'sedentary',
                          child: Text('Sedentário'),
                        ),
                        DropdownMenuItem(
                          value: 'light',
                          child: Text('Leve (1-2x/semana)'),
                        ),
                        DropdownMenuItem(
                          value: 'moderate',
                          child: Text('Moderado (3-5x/semana)'),
                        ),
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('Ativo (6-7x/semana)'),
                        ),
                        DropdownMenuItem(
                          value: 'very_active',
                          child: Text('Muito Ativo (2x/dia)'),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _activityLevel = v!);
                        _calculateCalories();
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Objetivo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _goal,
                      decoration: const InputDecoration(
                        labelText: 'Meta',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'lose_weight',
                          child: Text('Perder Peso'),
                        ),
                        DropdownMenuItem(
                          value: 'maintain',
                          child: Text('Manter Peso'),
                        ),
                        DropdownMenuItem(
                          value: 'gain_weight',
                          child: Text('Ganhar Peso'),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _goal = v!);
                        _calculateCalories();
                      },
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Calorias Diárias:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$_calculatedCalories kcal',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Restrições Alimentares',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: _restrictions.map((r) {
                        final isSelected = _selectedRestrictions.contains(
                          r['value'],
                        );
                        return FilterChip(
                          label: Text(r['label']!),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedRestrictions.add(r['value']!);
                              } else {
                                _selectedRestrictions.remove(r['value']);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Preferências Alimentares',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: _preferences.map((p) {
                        final isSelected = _selectedPreferences.contains(
                          p['value'],
                        );
                        return FilterChip(
                          label: Text(p['label']!),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedPreferences.add(p['value']!);
                              } else {
                                _selectedPreferences.remove(p['value']);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _generateMealPlan,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Gerar Plano Alimentar',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }
}
