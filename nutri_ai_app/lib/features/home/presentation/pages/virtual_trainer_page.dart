import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/network/api_service.dart';



class VirtualTrainerPage extends StatefulWidget {
  const VirtualTrainerPage({super.key});

  @override
  State<VirtualTrainerPage> createState() => _VirtualTrainerPageState();
}

class _VirtualTrainerPageState extends State<VirtualTrainerPage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late AnimationController _animationController;




  // Conversação com Personal Virtual
  final List<Map<String, dynamic>> _conversation = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    print('[PERSONAL] 🚀 Personal Virtual initState chamado!');
    _setupAnimations();
    _loadData();
    _startIntroduction();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );


  }

  Future<void> _loadData() async {
    try {
      // Carregar perfil do usuário
      try {
        await _apiService.getProfile();
      } catch (e) {
        print('Erro ao carregar perfil: $e');
      }

      // Carregar histórico do Personal Virtual
      try {
        print('[PERSONAL] 🔍 Tentando carregar histórico do Personal Virtual...');
        final history = await _apiService.getPersonalHistory(limit: 20);
        print('[PERSONAL] ✅ Histórico carregado: ${history.length} mensagens');
        for (var message in history) {
          print('[PERSONAL] 💬 Mensagem: ${message['message'].substring(0, 50)}...');
          _conversation.add({
            'content': message['message'],
            'isBot': message['role'] == 'assistant',
            'timestamp': DateTime.now(),
          });
        }
        
        // Garantir que não exceda 20 mensagens mesmo no carregamento
        if (_conversation.length > 20) {
          _conversation.removeRange(0, _conversation.length - 20);
          print('[PERSONAL] 🔄 Histórico truncado para 20 mensagens no carregamento');
        }
        
      } catch (e) {
        print('[PERSONAL] ❌ Erro ao carregar histórico do Personal: $e');
      }

      // Verificar se precisa atualizar perfil (simulado)

      // Buscar treino de hoje (implementar depois)
      // _todayWorkout será carregado quando o endpoint estiver pronto

      setState(() {
        // Dados carregados
      });
    } catch (e) {
      print('Erro ao carregar dados: $e');
      setState(() {
        // Erro ao carregar dados
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
      
      // Lógica de limitação: máximo 20 mensagens
      // Quando chegar a 21, remove a primeira (mais antiga)
      if (_conversation.length > 20) {
        _conversation.removeAt(0);
        print('[PERSONAL] 🗺️ Mensagem mais antiga removida. Total: ${_conversation.length}');
      }
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
    print('[FRONTEND] 🎯 _sendMessage chamada!');
    if (_messageController.text.trim().isEmpty || _isTyping) {
      print('[FRONTEND] ⚠️ Mensagem vazia ou já enviando, cancelando...');
      return;
    }

    final userMessage = _messageController.text;
    print('[FRONTEND] 📝 Mensagem: "$userMessage"');
    _messageController.clear();

    setState(() {
      _conversation.add({
        'content': userMessage,
        'isBot': false,
        'timestamp': DateTime.now(),
      });
      
      // Aplicar limitação após adicionar mensagem do usuário
      if (_conversation.length > 20) {
        _conversation.removeAt(0);
        print('[PERSONAL] 🗂️ Mensagem mais antiga removida após mensagem do usuário. Total: ${_conversation.length}');
      }
      
      _isTyping = true;
    });

    try {
      print('[FRONTEND] 🚀 Enviando mensagem para Personal: $userMessage');
      final response = await _apiService.sendPersonalMessage(userMessage);
      print('[FRONTEND] ✅ Resposta recebida: $response');
      
      if (mounted) {
        setState(() {
          _conversation.add({
            'content': response['message'],
            'isBot': true,
            'timestamp': DateTime.parse(response['created_at']),
          });
          
          // Aplicar limitação após resposta do bot
          if (_conversation.length > 20) {
            _conversation.removeAt(0);
            print('[PERSONAL] 🗂️ Mensagem mais antiga removida após resposta. Total: ${_conversation.length}');
          }
          
          _isTyping = false;
        });
      }
      
    } catch (e) {
      print('[FRONTEND] ❌ Erro ao enviar mensagem para Personal: $e');
      if (mounted) {
        setState(() {
          _conversation.add({
            'content': 'Desculpe, tive um problema técnico! 😅 Mas não desista do seu treino! 💪 Tente novamente em alguns segundos!',
            'isBot': true,
            'timestamp': DateTime.now(),
          });
          
          // Aplicar limitação mesmo em caso de erro
          if (_conversation.length > 20) {
            _conversation.removeAt(0);
            print('[PERSONAL] 🗂️ Mensagem mais antiga removida após erro. Total: ${_conversation.length}');
          }
          
          _isTyping = false;
        });
      }
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
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.black 
                  : Colors.grey.shade50,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _conversation.length,
                itemBuilder: (context, index) {
                  final message = _conversation[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }



  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isBot = message['isBot'] as bool;
    
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isBot 
              ? (Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey.shade700 
                  : Colors.grey.shade200)
              : (Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey.shade600 
                  : Theme.of(context).primaryColor),
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: isBot && message['content'].contains('*')
          ? MarkdownBody(
              data: message['content'],
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey.shade100 
                      : Colors.black87,
                  fontSize: 14,
                ),
                h1: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey.shade100 
                      : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                h2: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey.shade100 
                      : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                h3: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey.shade100 
                      : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                listBullet: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey.shade100 
                      : Colors.black87,
                  fontSize: 14,
                ),
                strong: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey.shade100 
                      : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
                em: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey.shade100 
                      : Colors.black87,
                  fontStyle: FontStyle.italic,
                ),
                code: TextStyle(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey.shade600 
                      : Colors.grey.shade300,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey.shade100 
                      : Colors.black87,
                  fontFamily: 'monospace',
                ),
              ),
            )
          : Text(
              message['content'],
              style: TextStyle(
                color: isBot 
                    ? (Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey.shade100 
                        : Colors.black87)
                    : Colors.white,
              ),
            ),
      ),
    );
  }



  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey.shade900 
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Digite sua mensagem...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey.shade800 
                    : Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                print('[FRONTEND] 🎹 onSubmitted chamado!');
                _sendMessage();
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey.shade600 
                  : Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                print('BOTAO CLICADO!!!');
                print('[FRONTEND] 👆 Botão de enviar clicado!');
                _sendMessage();
              },
              icon: const Icon(Icons.arrow_forward),
              style: IconButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
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