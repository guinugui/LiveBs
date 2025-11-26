import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _email = prefs.getString('email') ?? '';

      final profile = await ApiService().getProfile();

      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar perfil: $e')));
      }
    }
  }

  String _getActivityLevelText(String level) {
    switch (level) {
      case 'sedentary':
        return 'Sedentário';
      case 'lightly_active':
        return 'Levemente Ativo';
      case 'moderately_active':
        return 'Moderadamente Ativo';
      case 'very_active':
        return 'Muito Ativo';
      case 'extremely_active':
        return 'Extremamente Ativo';
      default:
        return level;
    }
  }

  String _getGenderText(String gender) {
    switch (gender) {
      case 'male':
        return 'Masculino';
      case 'female':
        return 'Feminino';
      case 'other':
        return 'Outro';
      default:
        return gender;
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const Center(child: Text('Erro ao carregar perfil')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navega para a tela de atualização rápida (peso, altura, idade)
              context.push('/quick-update');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(
                    0xFF6C63FF,
                  ).withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _email.split('@')[0],
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(_email, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Personal Info Section
          Text(
            'Informações Pessoais',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Peso Atual',
            '${_profile!['weight'].toStringAsFixed(1)} kg',
            Icons.monitor_weight_outlined,
          ),
          _buildInfoCard('Altura', '${_profile!['height']} cm', Icons.height),
          _buildInfoCard(
            'Idade',
            '${_profile!['age']} anos',
            Icons.cake_outlined,
          ),
          _buildInfoCard('Sexo', _getGenderText(_profile!['gender']), Icons.wc),
          _buildInfoCard(
            'IMC',
            _profile!['bmi'].toStringAsFixed(1),
            Icons.analytics_outlined,
          ),
          const SizedBox(height: 24),

          // Goals Section
          Text(
            'Objetivos',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Peso Meta',
            '${_profile!['target_weight'].toStringAsFixed(1)} kg',
            Icons.flag_outlined,
          ),
          _buildInfoCard(
            'Atividade',
            _getActivityLevelText(_profile!['activity_level']),
            Icons.fitness_center_outlined,
          ),
          _buildInfoCard(
            'Calorias Diárias',
            '${_profile!['daily_calories']} kcal',
            Icons.local_fire_department_outlined,
          ),
          const SizedBox(height: 24),

          // Preferences Section
          Text(
            'Preferências Alimentares',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Restrições:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_profile!['dietary_restrictions'] != null &&
                      (_profile!['dietary_restrictions'] as List).isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: (_profile!['dietary_restrictions'] as List)
                          .map((r) => Chip(label: Text(r)))
                          .toList(),
                    )
                  else
                    const Text(
                      'Nenhuma restrição',
                      style: TextStyle(color: Colors.grey),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Preferências:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_profile!['dietary_preferences'] != null &&
                      (_profile!['dietary_preferences'] as List).isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: (_profile!['dietary_preferences'] as List)
                          .map((p) => Chip(label: Text(p)))
                          .toList(),
                    )
                  else
                    const Text(
                      'Nenhuma preferência',
                      style: TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Logout Button
          OutlinedButton(
            onPressed: _logout,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: const Text('Sair'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF6C63FF)),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
