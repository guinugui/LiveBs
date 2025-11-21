import 'package:flutter/material.dart';

class MealPlanPage extends StatelessWidget {
  const MealPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plano Alimentar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: Regenerar plano
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 7,
        itemBuilder: (context, index) {
          return _buildDayCard(context, index + 1);
        },
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, int day) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          'Dia $day',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Toque para ver as refeições'),
        children: [
          _buildMealItem(
            context,
            'Café da Manhã',
            'Omelete com legumes',
            '350 kcal',
            Icons.breakfast_dining_outlined,
          ),
          _buildMealItem(
            context,
            'Lanche da Manhã',
            'Iogurte natural com frutas',
            '150 kcal',
            Icons.fastfood_outlined,
          ),
          _buildMealItem(
            context,
            'Almoço',
            'Frango grelhado com arroz integral',
            '500 kcal',
            Icons.lunch_dining_outlined,
          ),
          _buildMealItem(
            context,
            'Lanche da Tarde',
            'Mix de castanhas',
            '200 kcal',
            Icons.cookie_outlined,
          ),
          _buildMealItem(
            context,
            'Jantar',
            'Salmão ao forno com vegetais',
            '450 kcal',
            Icons.dinner_dining_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildMealItem(
    BuildContext context,
    String mealType,
    String mealName,
    String calories,
    IconData icon,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
        child: Icon(icon, color: const Color(0xFF6C63FF)),
      ),
      title: Text(mealType),
      subtitle: Text(mealName),
      trailing: Text(
        calories,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF4CAF50),
        ),
      ),
      onTap: () {
        // TODO: Mostrar detalhes da refeição
        _showMealDetails(context, mealType, mealName);
      },
    );
  }

  void _showMealDetails(BuildContext context, String type, String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Macronutrientes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildMacroRow('Proteínas', '25g', Colors.red),
                  _buildMacroRow('Carboidratos', '40g', Colors.orange),
                  _buildMacroRow('Gorduras', '15g', Colors.blue),
                  const SizedBox(height: 24),
                  const Text(
                    'Modo de Preparo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Em uma tigela, bata os ovos\n'
                    '2. Adicione os legumes picados\n'
                    '3. Tempere a gosto\n'
                    '4. Leve à frigideira antiaderente\n'
                    '5. Deixe dourar dos dois lados',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroRow(String name, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(name),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
