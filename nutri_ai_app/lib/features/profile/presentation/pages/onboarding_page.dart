import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form controllers
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  final _targetWeightController = TextEditingController();
  
  String? _selectedGender;
  String? _selectedActivityLevel;
  final List<String> _selectedRestrictions = [];
  final List<String> _selectedPreferences = [];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // TODO: Salvar dados do perfil
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Perfil'),
      ),
      body: Column(
        children: [
          // Progress Indicator
          LinearProgressIndicator(
            value: (_currentPage + 1) / 4,
          ),
          
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildBasicInfoPage(),
                _buildGoalsPage(),
                _buildActivityPage(),
                _buildPreferencesPage(),
              ],
            ),
          ),

          // Bottom Navigation
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Voltar'),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(_currentPage == 3 ? 'Concluir' : 'Próximo'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Informações Básicas',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Peso Atual (kg)',
              prefixIcon: Icon(Icons.monitor_weight_outlined),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Altura (cm)',
              prefixIcon: Icon(Icons.height),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Idade',
              prefixIcon: Icon(Icons.cake_outlined),
            ),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _selectedGender,
            decoration: const InputDecoration(
              labelText: 'Sexo',
              prefixIcon: Icon(Icons.wc),
            ),
            items: const [
              DropdownMenuItem(value: 'male', child: Text('Masculino')),
              DropdownMenuItem(value: 'female', child: Text('Feminino')),
              DropdownMenuItem(value: 'other', child: Text('Outro')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Seus Objetivos',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _targetWeightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Peso Desejado (kg)',
              prefixIcon: Icon(Icons.flag_outlined),
            ),
          ),
          const SizedBox(height: 24),

          const Text('Este é seu objetivo de peso ideal. Vamos trabalhar juntos para alcançá-lo de forma saudável!'),
        ],
      ),
    );
  }

  Widget _buildActivityPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nível de Atividade',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),

          _buildActivityOption(
            'sedentary',
            'Sedentário',
            'Pouco ou nenhum exercício',
          ),
          _buildActivityOption(
            'light',
            'Levemente Ativo',
            'Exercício leve 1-3 dias/semana',
          ),
          _buildActivityOption(
            'moderate',
            'Moderadamente Ativo',
            'Exercício moderado 3-5 dias/semana',
          ),
          _buildActivityOption(
            'active',
            'Muito Ativo',
            'Exercício intenso 6-7 dias/semana',
          ),
          _buildActivityOption(
            'very_active',
            'Extremamente Ativo',
            'Exercício muito intenso diariamente',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityOption(String value, String title, String subtitle) {
    return RadioListTile<String>(
      value: value,
      selected: _selectedActivityLevel == value,
      title: Text(title),
      subtitle: Text(subtitle),
      toggleable: true,
      onChanged: (String? newValue) {
        setState(() {
          _selectedActivityLevel = newValue;
        });
      },
    );
  }

  Widget _buildPreferencesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Preferências Alimentares',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),

          const Text(
            'Restrições Alimentares:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildChip('Vegetariano', _selectedRestrictions),
              _buildChip('Vegano', _selectedRestrictions),
              _buildChip('Sem Lactose', _selectedRestrictions),
              _buildChip('Sem Glúten', _selectedRestrictions),
              _buildChip('Diabetes', _selectedRestrictions),
            ],
          ),
          const SizedBox(height: 24),

          const Text(
            'Preferências:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildChip('Refeições Rápidas', _selectedPreferences),
              _buildChip('Comida Caseira', _selectedPreferences),
              _buildChip('Low Carb', _selectedPreferences),
              _buildChip('Alto Proteína', _selectedPreferences),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, List<String> selectedList) {
    final isSelected = selectedList.contains(label);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            selectedList.add(label);
          } else {
            selectedList.remove(label);
          }
        });
      },
    );
  }
}
