import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/network/api_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatBubble> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    try {
      // Carrega máximo 20 mensagens do histórico
      final history = await ApiService().getChatHistory(limit: 20);

      if (mounted) {
        setState(() {
          _messages.clear();

          // Só adicionar mensagem de boas-vindas se não há histórico
          if (history.isEmpty) {
            _messages.add(
              ChatBubble(
                message:
                    'Olá! Sou a Nutri Clara, sua nutricionista especializada em alimentos 😊\n\n🎯 Meu objetivo é esclarecer dúvidas sobre:\n• Propriedades dos alimentos\n• Valores nutricionais\n• Combinações alimentares\n• Mitos e verdades nutricionais\n• Efeitos dos alimentos no organismo\n\n⚠️ Importante: Não prescrevo dietas personalizadas - para isso, consulte um nutricionista presencialmente.\n\nComo posso te ajudar hoje?',
                isUser: false,
                time: DateTime.now(),
              ),
            );
          }

          for (final msg in history) {
            _messages.add(
              ChatBubble(
                message: msg['message'],
                isUser: msg['is_user'],
                time: DateTime.parse(msg['created_at']),
              ),
            );
          }

          // Garantir que não exceda 20 mensagens mesmo no carregamento
          if (_messages.length > 20) {
            _messages.removeRange(0, _messages.length - 20);
            print(
              '[NUTRI] 🔄 Histórico truncado para 20 mensagens no carregamento',
            );
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatBubble(
              message:
                  'Olá! Sou a Nutri Clara, sua nutricionista especializada 😊\n\nPosso ajudar apenas com dúvidas sobre alimentos e nutrição. Como posso te auxiliar hoje?',
              isUser: false,
              time: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final userMessage = _messageController.text;
    _messageController.clear();

    setState(() {
      _messages.add(
        ChatBubble(message: userMessage, isUser: true, time: DateTime.now()),
      );

      // Lógica de limitação: máximo 20 mensagens
      // Quando chegar a 21, remove a primeira (mais antiga)
      if (_messages.length > 20) {
        _messages.removeAt(0);
        print(
          '[NUTRI] 🗂️ Mensagem mais antiga removida. Total: ${_messages.length}',
        );
      }

      _isSending = true;
    });

    try {
      final response = await ApiService().sendChatMessage(userMessage);

      if (mounted) {
        setState(() {
          _messages.add(
            ChatBubble(
              message:
                  response['message'] ??
                  response['response'] ??
                  'Erro na resposta',
              isUser: false,
              time: DateTime.parse(response['created_at']),
            ),
          );

          // Aplicar limitação novamente após resposta do bot
          if (_messages.length > 20) {
            _messages.removeAt(0);
            print(
              '[NUTRI] 🗂️ Mensagem mais antiga removida após resposta. Total: ${_messages.length}',
            );
          }

          _isSending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatBubble(
              message:
                  'Desculpe, houve um erro ao processar sua mensagem. Tente novamente.',
              isUser: false,
              time: DateTime.now(),
            ),
          );

          // Aplicar limitação mesmo em caso de erro
          if (_messages.length > 20) {
            _messages.removeAt(0);
            print(
              '[NUTRI] 🗂️ Mensagem mais antiga removida após erro. Total: ${_messages.length}',
            );
          }

          _isSending = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nutri Clara'),
            Text(
              'Nutricionista Especializada',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
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
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
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

  Widget _buildMessageBubble(ChatBubble message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser
              ? (Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade600
                    : const Color(0xFF6C63FF))
              : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: message.isUser
            ? Text(message.message, style: const TextStyle(color: Colors.white))
            : MarkdownBody(
                data: message.message,
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
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade600
                        : Colors.grey.shade300,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade100
                        : Colors.black87,
                    fontFamily: 'monospace',
                  ),
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
              onSubmitted: (_) => _sendMessage(),
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
              onPressed: _sendMessage,
              icon: const Icon(Icons.arrow_forward),
              style: IconButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble {
  final String message;
  final bool isUser;
  final DateTime time;

  ChatBubble({required this.message, required this.isUser, required this.time});
}
