import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _waterReminders = true;
  bool _profileUpdates = true;
  bool _mealPlans = true;
  bool _workouts = true;
  bool _weeklyReports = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterReminders = prefs.getBool('notifications_water') ?? true;
      _profileUpdates = prefs.getBool('notifications_profile') ?? true;
      _mealPlans = prefs.getBool('notifications_meal') ?? true;
      _workouts = prefs.getBool('notifications_workout') ?? true;
      _weeklyReports = prefs.getBool('notifications_reports') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool('notifications_water', _waterReminders),
      prefs.setBool('notifications_profile', _profileUpdates),
      prefs.setBool('notifications_meal', _mealPlans),
      prefs.setBool('notifications_workout', _workouts),
      prefs.setBool('notifications_reports', _weeklyReports),
    ]);
  }

  Future<void> _updateNotifications() async {
    setState(() => _isLoading = true);

    try {
      await _saveSettings();
      
      // Cancel all notifications first
      await NotificationService().cancelAllNotifications();
      
      // Schedule only enabled notifications
      if (_waterReminders) {
        await NotificationService().scheduleWaterReminders();
      }
      if (_profileUpdates) {
        await NotificationService().scheduleProfileUpdateReminder();
      }
      if (_mealPlans) {
        await NotificationService().scheduleMealPlanReminder();
      }
      if (_workouts) {
        await NotificationService().scheduleWorkoutReminders();
      }
      if (_weeklyReports) {
        await NotificationService().scheduleWeeklyReport();
      }

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurações salvas com sucesso!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar configurações: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? const Color(0xFF2196F3)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor ?? const Color(0xFF2196F3),
            size: 24,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF4CAF50),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Notificações',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _updateNotifications,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Mantenha-se no foco!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Configure suas notificações para nunca perder o ritmo da sua jornada saudável',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notification Settings
            _buildNotificationTile(
              title: 'Lembretes de Água',
              subtitle: 'Notificações de 2 em 2 horas das 8h às 22h',
              icon: Icons.water_drop,
              value: _waterReminders,
              onChanged: (value) => setState(() => _waterReminders = value),
              iconColor: const Color(0xFF2196F3),
            ),

            _buildNotificationTile(
              title: 'Atualização de Dados',
              subtitle: 'Lembrete a cada 7 dias para atualizar peso e medidas',
              icon: Icons.analytics,
              value: _profileUpdates,
              onChanged: (value) => setState(() => _profileUpdates = value),
              iconColor: const Color(0xFF4CAF50),
            ),

            _buildNotificationTile(
              title: 'Planos Alimentares',
              subtitle: 'Sugestão de novos planos todo domingo às 8h',
              icon: Icons.restaurant_menu,
              value: _mealPlans,
              onChanged: (value) => setState(() => _mealPlans = value),
              iconColor: const Color(0xFFFF9800),
            ),

            _buildNotificationTile(
              title: 'Lembretes de Treino',
              subtitle: 'Motivação para treinar (seg, qua, sex às 19h)',
              icon: Icons.fitness_center,
              value: _workouts,
              onChanged: (value) => setState(() => _workouts = value),
              iconColor: const Color(0xFFE91E63),
            ),

            _buildNotificationTile(
              title: 'Relatórios Semanais',
              subtitle: 'Resumo do seu progresso todo sábado às 18h',
              icon: Icons.assessment,
              value: _weeklyReports,
              onChanged: (value) => setState(() => _weeklyReports = value),
              iconColor: const Color(0xFF9C27B0),
            ),

            const SizedBox(height: 24),

            // Test Notification Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notifications,
                    color: Color(0xFF2196F3),
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Testar Notificação',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: const Text(
                  'Enviar uma notificação de teste agora',
                  style: TextStyle(fontSize: 14),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await NotificationService().showImmediateNotification(
                    title: '🎉 Notificação Teste!',
                    body: 'Se você viu isso, as notificações estão funcionando perfeitamente!',
                    payload: 'test',
                  );
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notificação de teste enviada!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 16),

            // Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF6B7280),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'As notificações ajudam você a manter seus hábitos saudáveis. Você pode desativá-las a qualquer momento.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}