import 'package:flutter/material.dart';
import '../../../../core/network/api_service.dart';
import '../../../workout/presentation/pages/workout_questionnaire_page.dart';
import '../../../workout/presentation/pages/workout_plan_list_page.dart';

class VirtualTrainerPage extends StatefulWidget {
  const VirtualTrainerPage({super.key});

  @override
  State<VirtualTrainerPage> createState() => _VirtualTrainerPageState();
}

class _VirtualTrainerPageState extends State<VirtualTrainerPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLoading = true;
  String _userName = 'Usuário';
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _todayWorkout;
  bool _needsProfileUpdate = false;

  // Conversação com Personal Virtual
  final List<Map<String, dynamic>> _conversation = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadData();
    _startIntroduction();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadData() async {
    try {
      // Carregar perfil do usuário
      try {
        final profileResponse = await _apiService.getProfile();
        _profile = profileResponse;
        _userName = profileResponse['name'] ?? 'Usuário';
      } catch (e) {
        print('Erro ao carregar perfil: $e');
      }

      // Carregar histórico do Personal Virtual
      try {
        final history = await _apiService.getPersonalHistory(limit: 20);
        for (var message in history) {
          _conversation.add({
            'content': message['message'],
            'isBot': message['role'] == 'assistant',
            'timestamp': DateTime.now(),
          });
        }
      } catch (e) {
        print('Erro ao carregar histórico do Personal: $e');
      }

      // Verificar se precisa atualizar perfil (simulado)
      _needsProfileUpdate = false;

      // Buscar treino de hoje (implementar depois)
      // _todayWorkout será carregado quando o endpoint estiver pronto

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar dados: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startIntroduction() {
    // Só mostra introdução se não há histórico
    if (_conversation.isEmpty) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        _addMessage(
          'Olá! 👋 Sou o Coach Leo, seu Personal Trainer brasileiro! Como posso te ajudar hoje?',
          isBot: true,
        );
        
        Future.delayed(const Duration(milliseconds: 2000), () {
          _addMessage(
            'Estou aqui para te orientar com treinos, exercícios e rotinas. Posso te ajudar com emagrecimento, ganho de massa, cardio e muito mais! 💪',
            isBot: true,
          );
        });
      });
    }
  }

  void _addMessage(String content, {bool isBot = false}) {
    setState(() {
      _conversation.add({
        'content': content,
        'isBot': isBot,
        'timestamp': DateTime.now(),
      });
    });

    // Auto scroll para o final
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    _addMessage(message);

    setState(() {
      _isTyping = true;
    });

    try {
      // Enviar mensagem para o Personal Virtual (Coach Atlas) via API
      final response = await _apiService.sendPersonalMessage(message);
      _addMessage(response['message'], isBot: true);
      
    } catch (e) {
      print('Erro ao enviar mensagem para Personal: $e');
      _addMessage(
        'Desculpe, tive um problema técnico! 😅 Mas não desista do seu treino! 💪 Tente novamente em alguns segundos!',
        isBot: true,
      );
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Personal Virtual',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header com avatar e status
                _buildHeader(),
                
                // Área de conversa
                Expanded(child: _buildConversation()),
                
                // Ações rápidas
                _buildQuickActions(),
                
                // Campo de mensagem
                _buildMessageInput(),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade600, Colors.orange.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.smart_toy,
                          color: Colors.orange,
                          size: 30,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sua Personal Virtual',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Online e pronta para ajudar!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _conversation.length + (_isTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _conversation.length && _isTyping) {
            return _buildTypingIndicator();
          }
          
          final message = _conversation[index];
          return _buildMessageBubble(message);
        },
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isBot = message['isBot'] as bool;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBot) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.orange.shade600,
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isBot ? Colors.grey.shade100 : Colors.orange.shade600,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message['content'],
                style: TextStyle(
                  color: isBot ? Colors.black87 : Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (!isBot) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: Icon(Icons.person, color: Colors.grey.shade600, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.orange.shade600,
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animation = Tween<double>(
          begin: 0.5,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.2,
            (index * 0.2) + 0.4,
            curve: Curves.easeInOut,
          ),
        ));
        
        return Transform.scale(
          scale: animation.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildQuickActionChip(
              '🏋️‍♀️ Gerar Treino',
              () => _navigateToWorkoutGenerator(),
            ),
            const SizedBox(width: 8),
            _buildQuickActionChip(
              '📋 Meus Treinos',
              () => _navigateToWorkoutList(),
            ),
            const SizedBox(width: 8),
            if (_todayWorkout != null)
              _buildQuickActionChip(
                '💪 Treino de Hoje',
                () => _showTodayWorkout(),
              ),
            const SizedBox(width: 8),
            _buildQuickActionChip(
              '🎯 Minhas Metas',
              () => _showGoals(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionChip(String label, VoidCallback onPressed) {
    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
      backgroundColor: Colors.orange.shade50,
      labelStyle: TextStyle(
        color: Colors.orange.shade700,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      side: BorderSide(color: Colors.orange.shade200),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Digite sua mensagem...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToWorkoutGenerator() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WorkoutQuestionnairePage(),
      ),
    );
  }

  void _navigateToWorkoutList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WorkoutPlanListPage(),
      ),
    );
  }

  void _showTodayWorkout() {
    if (_todayWorkout == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Treino de ${_todayWorkout!['day_name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plano: ${_todayWorkout!['plan_name']}'),
            const SizedBox(height: 12),
            const Text(
              'Pronto para treinar hoje? 💪',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navegar para detalhes do treino
            },
            child: const Text('Ver Detalhes'),
          ),
        ],
      ),
    );
  }

  void _showGoals() {
    if (_profile == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suas Metas 🎯'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Peso atual: ${_profile!['weight']} kg'),
            Text('Meta: ${_profile!['target_weight']} kg'),
            const SizedBox(height: 8),
            if (_needsProfileUpdate)
              const Text(
                '⚠️ Considere atualizar seu perfil!',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}