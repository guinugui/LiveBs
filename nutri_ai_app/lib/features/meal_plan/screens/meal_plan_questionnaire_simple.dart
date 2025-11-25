import 'package:flutter/material.dart';
import '../models/meal_plan_questionnaire.dart';

class MealPlanQuestionnaireScreen extends StatefulWidget {
  const MealPlanQuestionnaireScreen({super.key});

  @override
  State<MealPlanQuestionnaireScreen> createState() => _MealPlanQuestionnaireScreenState();
}

class _MealPlanQuestionnaireScreenState extends State<MealPlanQuestionnaireScreen> {
  String _selectedCookingTime = 'medium';
  int _selectedMealFrequency = 5;
  String _selectedBudgetLevel = 'medium';
  final TextEditingController _dislikedFoodsController = TextEditingController();
  final TextEditingController _foodPreferencesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalize seu Plano'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
            
            // Alimentos preferidos
            const Text(
              'Alimentos que você mais gosta:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _foodPreferencesController,
              decoration: const InputDecoration(
                hintText: 'Ex: frango, peixes, vegetais...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            // Alimentos que não gosta
            const Text(
              'Alimentos que você não gosta:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dislikedFoodsController,
              decoration: const InputDecoration(
                hintText: 'Ex: brócolis, fígado, peixe...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            // Tempo de preparo
            const Text(
              'Quanto tempo você tem para cozinhar?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...{
              'quick': 'Pouco tempo (até 30 min)',
              'medium': 'Tempo normal (30-60 min)',
              'long': 'Bastante tempo (60+ min)',
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
            const SizedBox(height: 24),
            
            // Número de refeições
            const Text(
              'Quantas refeições por dia?',
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
            Center(
              child: Text(
                '$_selectedMealFrequency refeições por dia',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 24),
            
            // Orçamento
            const Text(
              'Seu orçamento para alimentação:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...{
              'low': 'Orçamento baixo',
              'medium': 'Orçamento normal',
              'high': 'Orçamento alto',
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
    );
  }

  void _generatePlan() {
    // Processar os textos dos campos
    List<String> foodPreferences = _foodPreferencesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    
    List<String> dislikedFoods = _dislikedFoodsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final questionnaire = MealPlanQuestionnaire(
      foodPreferences: foodPreferences,
      dislikedFoods: dislikedFoods,
      cookingTime: _selectedCookingTime,
      mealFrequency: _selectedMealFrequency,
      budgetLevel: _selectedBudgetLevel,
      specialGoals: [], // Vazio por enquanto
    );

    Navigator.pop(context, questionnaire);
  }

  @override
  void dispose() {
    _dislikedFoodsController.dispose();
    _foodPreferencesController.dispose();
    super.dispose();
  }
}