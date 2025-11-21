import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Editar perfil
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
                  backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'João Silva',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'joao@email.com',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Personal Info Section
          Text(
            'Informações Pessoais',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard('Peso Atual', '75.5 kg', Icons.monitor_weight_outlined),
          _buildInfoCard('Altura', '175 cm', Icons.height),
          _buildInfoCard('Idade', '28 anos', Icons.cake_outlined),
          _buildInfoCard('Sexo', 'Masculino', Icons.wc),
          const SizedBox(height: 24),

          // Goals Section
          Text(
            'Objetivos',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard('Peso Meta', '70.0 kg', Icons.flag_outlined),
          _buildInfoCard('Atividade', 'Moderadamente Ativo', Icons.fitness_center_outlined),
          _buildInfoCard('Calorias Diárias', '1800 kcal', Icons.local_fire_department_outlined),
          const SizedBox(height: 24),

          // Preferences Section
          Text(
            'Preferências Alimentares',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 18,
                ),
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
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: const Text('Sem Lactose')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Preferências:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: const Text('Low Carb')),
                      Chip(label: const Text('Alto Proteína')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Logout Button
          OutlinedButton(
            onPressed: () {
              context.go('/login');
            },
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
