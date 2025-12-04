import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/services/notification_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

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

  // Erros inline
  String? _weightError;
  String? _heightError;
  String? _ageError;
  String? _targetWeightError;

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

  Future<void> _saveProfile() async {
    // Limpa erros anteriores
    setState(() {
      _weightError = null;
      _heightError = null;
      _ageError = null;
      _targetWeightError = null;
    });

    bool hasError = false;

    // Valida campos vazios e numéricos
    if (_weightController.text.isEmpty) {
      setState(() => _weightError = 'Digite seu peso');
      hasError = true;
    } else {
      try {
        final weight = double.parse(_weightController.text);
        if (weight <= 0 || weight > 300) {
          setState(() => _weightError = 'Peso inválido (0-300 kg)');
          hasError = true;
        }
      } catch (e) {
        setState(() => _weightError = 'Digite apenas números');
        hasError = true;
      }
    }

    if (_heightController.text.isEmpty) {
      setState(() => _heightError = 'Digite sua altura');
      hasError = true;
    } else {
      try {
        final height = double.parse(_heightController.text);
        if (height <= 0 || height > 250) {
          setState(() => _heightError = 'Altura inválida (0-250 cm)');
          hasError = true;
        }
      } catch (e) {
        setState(() => _heightError = 'Digite apenas números');
        hasError = true;
      }
    }

    if (_ageController.text.isEmpty) {
      setState(() => _ageError = 'Digite sua idade');
      hasError = true;
    } else {
      try {
        final age = int.parse(_ageController.text);
        if (age <= 0 || age > 120) {
          setState(() => _ageError = 'Idade inválida (0-120 anos)');
          hasError = true;
        }
      } catch (e) {
        setState(() => _ageError = 'Digite apenas números');
        hasError = true;
      }
    }

    if (_targetWeightController.text.isEmpty) {
      setState(() => _targetWeightError = 'Digite seu peso meta');
      hasError = true;
    } else {
      try {
        final targetWeight = double.parse(_targetWeightController.text);
        if (targetWeight <= 0 || targetWeight > 300) {
          setState(() => _targetWeightError = 'Peso inválido (0-300 kg)');
          hasError = true;
        }
      } catch (e) {
        setState(() => _targetWeightError = 'Digite apenas números');
        hasError = true;
      }
    }

    if (_selectedGender == null || _selectedActivityLevel == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preencha todos os campos')));
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      await ApiService().createProfile(
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        age: int.parse(_ageController.text),
        gender: _selectedGender!,
        targetWeight: double.parse(_targetWeightController.text),
        activityLevel: _selectedActivityLevel!,
        dietaryRestrictions: _selectedRestrictions,
        dietaryPreferences: _selectedPreferences,
      );

      // Reagendar notificações de atualização de perfil
      try {
        await NotificationService().scheduleProfileUpdateReminder();
      } catch (e) {
        print('Erro ao agendar notificações de perfil: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Perfil criado com sucesso!'),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();

        print('DEBUG Onboarding - Erro: $errorMessage');

        // Remove prefixos técnicos
        if (errorMessage.contains('DioException')) {
          final parts = errorMessage.split(':');
          if (parts.length > 1) {
            errorMessage = parts.sublist(1).join(':').trim();
          }
        }
        errorMessage = errorMessage.replaceAll('[bad response]', '').trim();

        print('DEBUG Onboarding - Mensagem limpa: $errorMessage');

        // Mensagens específicas
        String displayMessage = 'Erro ao criar perfil';

        if (errorMessage.contains('já existe') ||
            errorMessage.contains('already exists')) {
          displayMessage = 'Você já possui um perfil cadastrado.';
        } else if (errorMessage.contains('inválido') ||
            errorMessage.contains('invalid')) {
          displayMessage = 'Dados inválidos. Verifique todos os campos.';
        } else if (errorMessage.contains('401') ||
            errorMessage.contains('Unauthorized')) {
          displayMessage = 'Sessão expirada. Faça login novamente.';
        } else if (errorMessage.contains('Network') ||
            errorMessage.contains('network')) {
          displayMessage = 'Erro de conexão. Verifique sua internet.';
        } else if (errorMessage.isNotEmpty &&
            !errorMessage.contains('Exception')) {
          displayMessage = errorMessage;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validateCurrentPage() {
    // Limpa erros anteriores
    setState(() {
      _weightError = null;
      _heightError = null;
      _ageError = null;
      _targetWeightError = null;
    });

    bool hasError = false;

    // Página 0: Informações Básicas
    if (_currentPage == 0) {
      if (_weightController.text.isEmpty) {
        setState(() => _weightError = 'Digite seu peso');
        hasError = true;
      } else {
        try {
          final weight = double.parse(_weightController.text);
          if (weight <= 0 || weight > 300) {
            setState(() => _weightError = 'Peso inválido (0-300 kg)');
            hasError = true;
          }
        } catch (e) {
          setState(() => _weightError = 'Digite apenas números');
          hasError = true;
        }
      }

      if (_heightController.text.isEmpty) {
        setState(() => _heightError = 'Digite sua altura');
        hasError = true;
      } else {
        try {
          final height = double.parse(_heightController.text);
          if (height <= 0 || height > 250) {
            setState(() => _heightError = 'Altura inválida (0-250 cm)');
            hasError = true;
          }
        } catch (e) {
          setState(() => _heightError = 'Digite apenas números');
          hasError = true;
        }
      }

      if (_ageController.text.isEmpty) {
        setState(() => _ageError = 'Digite sua idade');
        hasError = true;
      } else {
        try {
          final age = int.parse(_ageController.text);
          if (age <= 0 || age > 120) {
            setState(() => _ageError = 'Idade inválida (0-120 anos)');
            hasError = true;
          }
        } catch (e) {
          setState(() => _ageError = 'Digite apenas números');
          hasError = true;
        }
      }

      if (_selectedGender == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Selecione o sexo')));
        hasError = true;
      }
    }

    // Página 1: Objetivos
    if (_currentPage == 1) {
      if (_targetWeightController.text.isEmpty) {
        setState(() => _targetWeightError = 'Digite seu peso meta');
        hasError = true;
      } else {
        try {
          final targetWeight = double.parse(_targetWeightController.text);
          if (targetWeight <= 0 || targetWeight > 300) {
            setState(() => _targetWeightError = 'Peso inválido (0-300 kg)');
            hasError = true;
          }
        } catch (e) {
          setState(() => _targetWeightError = 'Digite apenas números');
          hasError = true;
        }
      }
    }

    // Página 2: Atividade
    if (_currentPage == 2) {
      if (_selectedActivityLevel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione o nível de atividade')),
        );
        hasError = true;
      }
    }

    return !hasError;
  }

  void _nextPage() {
    // Valida a página atual antes de avançar
    if (!_validateCurrentPage()) {
      return;
    }

    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Perfil')),
      body: Column(
        children: [
          // Progress Indicator
          LinearProgressIndicator(value: (_currentPage + 1) / 4),

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
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Voltar'),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextPage,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_currentPage == 3 ? 'Concluir' : 'Próximo'),
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Peso Atual (kg)',
              prefixIcon: const Icon(Icons.monitor_weight_outlined),
              helperText: 'Digite apenas números (ex: 75.5)',
              errorText: _weightError,
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Altura (cm)',
              prefixIcon: const Icon(Icons.height),
              helperText: 'Digite apenas números (ex: 175)',
              errorText: _heightError,
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Idade',
              prefixIcon: const Icon(Icons.cake_outlined),
              helperText: 'Digite apenas números (ex: 30)',
              errorText: _ageError,
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Peso Desejado (kg)',
              prefixIcon: const Icon(Icons.flag_outlined),
              helperText: 'Digite apenas números (ex: 70.0)',
              errorText: _targetWeightError,
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Este é seu objetivo de peso ideal. Vamos trabalhar juntos para alcançá-lo de forma saudável!',
          ),
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
      groupValue: _selectedActivityLevel,
      title: Text(title),
      subtitle: Text(subtitle),
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
