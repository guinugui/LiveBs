import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  double _currentWeight = 0.0;
  double _targetWeight = 0.0;
  double _height = 0.0;
  double _waterConsumed = 0.0;
  double _waterGoal = 2.0;
  bool _needsUpdate = false;
  String _updateMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  double _calculateWaterGoal(double weight, double height) {
    // Fórmula: 35ml por kg de peso corporal
    // Mínimo 2L, máximo 5L
    double liters = (weight * 35) / 1000;

    // Ajusta baseado na altura
    if (height > 180) {
      liters += 0.5;
    }

    // Limita entre 2L e 5L
    if (liters < 2.0) liters = 2.0;
    if (liters > 5.0) liters = 5.0;

    return double.parse(liters.toStringAsFixed(1));
  }

  Future<void> _loadData() async {
    try {
      // Buscar perfil do usuário
      final profile = await ApiService().getProfile();

      // Buscar água consumida hoje
      final waterData = await ApiService().getWaterToday();

      // Verificar se precisa atualizar dados
      final updateCheck = await ApiService().checkUpdateNeeded();

      final weight = profile['weight'] ?? 0.0;
      final height = profile['height'] ?? 0.0;
      final calculatedWaterGoal = _calculateWaterGoal(weight, height);

      setState(() {
        _currentWeight = weight;
        _targetWeight = profile['target_weight'] ?? 0.0;
        _height = height;
        _waterConsumed = waterData['total_liters'] ?? 0.0;
        _waterGoal = calculatedWaterGoal;
        _needsUpdate = updateCheck['needs_update'] ?? false;
        _updateMessage = updateCheck['message'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    }
  }

  Future<void> _addWater() async {
    try {
      // Adiciona 500ml (0.5L)
      await ApiService().logWater(0.5);

      setState(() {
        _waterConsumed += 0.5;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('+ 500ml de água registrado!'),
            backgroundColor: Colors.green.shade400,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao registrar água: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('LiveBs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner de atualização semanal
            if (_needsUpdate)
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.update,
                            color: Colors.orange.shade700,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Atualização Semanal',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _updateMessage,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/profile'),
                          icon: const Icon(Icons.edit),
                          label: const Text('Atualizar Dados'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_needsUpdate) const SizedBox(height: 16),

            // Quick Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Peso Atual',
                    '${_currentWeight.toStringAsFixed(1)} kg',
                    Icons.monitor_weight_outlined,
                    const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Meta',
                    '${_targetWeight.toStringAsFixed(1)} kg',
                    Icons.flag_outlined,
                    const Color(0xFF81C784),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // === SEÇÃO CHATS ===
            Text(
              '💬 Assistentes Virtuais',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),

            // Chat Nutri e Chat Personal
            Row(
              children: [
                // Chat Nutri
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/chat'),
                    child: Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade400,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Icon(
                                Icons.restaurant,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Chat Nutri',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dúvidas sobre\nalimentos',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Chat Personal
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/progress'),
                    child: Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade400,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Icon(
                                Icons.fitness_center,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Chat Personal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Treinos e\nexercícios',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // === SEÇÃO HIDRATAÇÃO ===
            Text(
              '💧 Hidratação Diária',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),

            // Seção de Hidratação
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.water_drop,
                              color: Colors.green.shade600,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Hidratação',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${_waterConsumed.toStringAsFixed(1)}L / ${_waterGoal.toStringAsFixed(1)}L',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Barra de progresso
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _waterConsumed / _waterGoal,
                        minHeight: 12,
                        backgroundColor: Colors.green.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.green.shade400,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Blocos de 500ml
                    _buildWaterBlocks(),

                    const SizedBox(height: 16),

                    // Botão adicionar água
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _waterConsumed < _waterGoal
                            ? _addWater
                            : null,
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar 500ml'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // === SEÇÃO TREINOS ===
            Text(
              '💪 Treinos Personalizados',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.fitness_center,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Treinos com IA 🤖',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gere treinos personalizados com inteligência artificial',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/workout-generator'),
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('Gerar Treino'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade400,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/workout-plans'),
                            icon: Icon(Icons.list, color: Colors.green.shade400, size: 20),
                            label: Text(
                              'Meus Treinos',
                              style: TextStyle(color: Colors.green.shade400),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.green.shade400),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // === SEÇÃO PLANO ALIMENTAR ===
            Text(
              '🍽️ Plano Alimentar',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.restaurant_menu,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alimentação Saudável 🥗',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gere seu plano nutricional personalizado',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/meal-plan'),
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('Novo Plano'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade400,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/meal-plan'),
                            icon: Icon(Icons.history, color: Colors.green.shade400, size: 20),
                            label: Text(
                              'Meus Planos',
                              style: TextStyle(color: Colors.green.shade400),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.green.shade400),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green.shade400,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            activeIcon: Icon(Icons.restaurant_menu),
            label: 'Plano Alimentar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Nutri',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center),
            label: 'Personal',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              // Já está na home
              break;
            case 1:
              context.push('/meal-plan');
              break;
            case 2:
              context.push('/chat');
              break;
            case 3:
              context.push('/progress');
              break;
          }
        },
      ),
    );
  }

  Widget _buildWaterBlocks() {
    // Calcula quantos blocos de 500ml cabem na meta
    int totalBlocks = (_waterGoal / 0.5).ceil();
    int consumedBlocks = (_waterConsumed / 0.5).floor();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(totalBlocks, (index) {
        bool isFilled = index < consumedBlocks;

        return Container(
          width: 60,
          height: 70,
          decoration: BoxDecoration(
            color: isFilled ? Colors.green.shade400 : Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade300, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.water_drop,
                color: isFilled ? Colors.white : Colors.green.shade300,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                '500ml',
                style: TextStyle(
                  fontSize: 10,
                  color: isFilled ? Colors.white : Colors.green.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
