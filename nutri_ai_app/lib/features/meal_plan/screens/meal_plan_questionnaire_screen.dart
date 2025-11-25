import 'package:flutter/material.dart';
import '../models/meal_plan_questionnaire.dart';

class MealPlanQuestionnaireScreen extends StatefulWidget {
  const MealPlanQuestionnaireScreen({super.key});

  @override
  State<MealPlanQuestionnaireScreen> createState() => _MealPlanQuestionnaireScreenState();
}

class _MealPlanQuestionnaireScreenState extends State<MealPlanQuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Estados do formulário
  List<String> _selectedFoodPreferences = [];
  List<String> _selectedDislikedFoods = [];
  String _selectedCookingTime = 'medium';
  int _selectedMealFrequency = 5;
  String _selectedBudgetLevel = 'medium';
  List<String> _selectedSpecialGoals = [];
  final TextEditingController _customDislikedController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalize seu Plano'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vamos personalizar seu plano alimentar!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Responda algumas perguntas para criarmos o plano ideal para você.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              
              _buildSimpleQuestions(),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _generatePlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Gerar Plano Alimentar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quais alimentos você mais gosta?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Selecione seus alimentos favoritos (opcional)',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _foodOptions.map((food) {
            final isSelected = _selectedFoodPreferences.contains(food);
            return FilterChip(
              label: Text(food),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedFoodPreferences.add(food);
                  } else {
                    _selectedFoodPreferences.remove(food);
                  }
                });
              },
              selectedColor: Colors.green.withOpacity(0.2),
              checkmarkColor: Colors.green,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDislikedFoodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Há alimentos que você não gosta ou não pode comer?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Nos ajude a evitar estes alimentos no seu plano',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _customDislikedController,
          decoration: const InputDecoration(
            hintText: 'Ex: brócolis, fígado, peixe...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              setState(() {
                _selectedDislikedFoods.addAll(
                  value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty)
                );
                _customDislikedController.clear();
              });
            }
          },
        ),
        if (_selectedDislikedFoods.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedDislikedFoods.map((food) {
              return Chip(
                label: Text(food),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _selectedDislikedFoods.remove(food);
                  });
                },
                backgroundColor: Colors.red.withOpacity(0.1),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildCookingTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quanto tempo você tem para cozinhar?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...{
          'quick': 'Pouco tempo (até 30 min) - Receitas rápidas',
          'medium': 'Tempo moderado (30-60 min) - Receitas normais',
          'long': 'Bastante tempo (60+ min) - Posso fazer receitas elaboradas',
        }.entries.map((entry) {
          return RadioListTile<String>(
            title: Text(entry.value),
            value: entry.key,
            groupValue: _selectedCookingTime,
            onChanged: (value) {
              setState(() {
                _selectedCookingTime = value!;
              });
            },
            activeColor: Colors.green,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMealFrequencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantas refeições por dia você prefere?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Slider(
          value: _selectedMealFrequency.toDouble(),
          min: 3,
          max: 6,
          divisions: 3,
          label: '$_selectedMealFrequency refeições',
          onChanged: (value) {
            setState(() {
              _selectedMealFrequency = value.round();
            });
          },
          activeColor: Colors.green,
        ),
        Text(
          '$_selectedMealFrequency refeições por dia',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildBudgetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Como está seu orçamento para alimentação?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...{
          'low': 'Orçamento apertado - Ingredientes básicos e econômicos',
          'medium': 'Orçamento normal - Variedade moderada',
          'high': 'Orçamento flexível - Posso investir em ingredientes premium',
        }.entries.map((entry) {
          return RadioListTile<String>(
            title: Text(entry.value),
            value: entry.key,
            groupValue: _selectedBudgetLevel,
            onChanged: (value) {
              setState(() {
                _selectedBudgetLevel = value!;
              });
            },
            activeColor: Colors.green,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSpecialGoalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Objetivos especiais de saúde?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Selecione se você tem algum objetivo específico (opcional)',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _goalOptions.map((goal) {
            final isSelected = _selectedSpecialGoals.contains(goal);
            return FilterChip(
              label: Text(goal),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSpecialGoals.add(goal);
                  } else {
                    _selectedSpecialGoals.remove(goal);
                  }
                });
              },
              selectedColor: Colors.blue.withOpacity(0.2),
              checkmarkColor: Colors.blue,
            );
          }).toList(),
        ),
      ],
    );
  }

  void _generatePlan() {
    final questionnaire = MealPlanQuestionnaire(
      foodPreferences: _selectedFoodPreferences,
      dislikedFoods: _selectedDislikedFoods,
      cookingTime: _selectedCookingTime,
      mealFrequency: _selectedMealFrequency,
      budgetLevel: _selectedBudgetLevel,
      specialGoals: _selectedSpecialGoals,
    );

    Navigator.pop(context, questionnaire);
  }

  @override
  void dispose() {
    _customDislikedController.dispose();
    super.dispose();
  }
}