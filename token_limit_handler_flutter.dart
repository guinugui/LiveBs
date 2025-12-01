// 🎨 TOKEN LIMIT HANDLER - Flutter
// Como tratar limites de token no frontend

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TokenLimitHandler {
  /// Trata resposta da API e mostra modals/avisos conforme necessário
  static Future<Map<String, dynamic>?> handleApiResponse({
    required BuildContext context,
    required http.Response response,
    required String operation, // Ex: "gerar plano alimentar", "chat personal"
  }) async {
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Verificar se há warning de tokens
      if (data['message'] != null && data['message'].toString().contains('tokens')) {
        _showTokenWarning(context, data['message']);
      }
      
      return data;
      
    } else if (response.statusCode == 429) {
      // Limite de tokens atingido
      final errorData = json.decode(response.body);
      final detail = errorData['detail'];
      
      if (detail['type'] == 'token_limit') {
        await _showTokenLimitDialog(context, detail, operation);
        return null; // Indica que operação foi bloqueada
      }
    }
    
    // Outros erros HTTP
    throw Exception('Erro na API: ${response.statusCode}');
  }
  
  /// Mostra aviso discreto de tokens baixos
  static void _showTokenWarning(BuildContext context, String warningMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(warningMessage),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Ver Status',
          textColor: Colors.white,
          onPressed: () => _showTokenStatusDialog(context),
        ),
      ),
    );
  }
  
  /// Mostra dialog quando limite é atingido
  static Future<void> _showTokenLimitDialog(
    BuildContext context, 
    Map<String, dynamic> detail, 
    String operation
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Não pode fechar clicando fora
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.block, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Limite Diário Atingido'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Você já utilizou seus ${detail['daily_limit']} tokens disponíveis hoje para operações de IA.',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text(
                  '✨ O que você pode fazer:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('• Aguarde até amanhã para novos tokens'),
                const Text('• Continue usando outras funcionalidades do app'),
                const Text('• Veja seus planos e treinos já salvos'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.access_time, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Tokens renovam automaticamente às 00:00',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => _showTokenStatusDialog(context),
              child: const Text('Ver Detalhes'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }
  
  /// Mostra dialog com status detalhado dos tokens
  static Future<void> _showTokenStatusDialog(BuildContext context) async {
    // Fechar dialog anterior se estiver aberto
    Navigator.of(context).pop();
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Status dos Tokens'),
          content: FutureBuilder<Map<String, dynamic>>(
            future: _fetchTokenStatus(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Carregando status...'),
                  ],
                );
              }
              
              if (snapshot.hasError) {
                return const Text('Erro ao carregar status dos tokens');
              }
              
              final status = snapshot.data!;
              final percentageUsed = status['percentage_used'];
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTokenProgressBar(percentageUsed),
                  const SizedBox(height: 16),
                  Text('Tokens usados hoje: ${status['tokens_used_today']}'),
                  Text('Tokens restantes: ${status['tokens_remaining']}'),
                  Text('Limite diário: ${status['daily_limit']}'),
                  Text('Requests feitas: ${status['requests_count']}'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status['alert_level']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status['status_message'],
                      style: TextStyle(
                        color: _getStatusColor(status['alert_level']),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
  
  /// Barra de progresso dos tokens
  static Widget _buildTokenProgressBar(double percentage) {
    Color progressColor;
    if (percentage >= 95) progressColor = Colors.red;
    else if (percentage >= 80) progressColor = Colors.orange;
    else if (percentage >= 60) progressColor = Colors.yellow[700]!;
    else progressColor = Colors.green;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Uso diário: ${percentage.toStringAsFixed(1)}%'),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
        ),
      ],
    );
  }
  
  /// Busca status atual dos tokens
  static Future<Map<String, dynamic>> _fetchTokenStatus() async {
    // Substituir pela sua API call real
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8001/tokens/status'),
      headers: {
        'Authorization': 'Bearer YOUR_TOKEN_HERE',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erro ao buscar status dos tokens');
    }
  }
  
  /// Retorna cor baseada no nível de alerta
  static Color _getStatusColor(String alertLevel) {
    switch (alertLevel) {
      case 'critical': return Colors.red;
      case 'warning': return Colors.orange;
      case 'info': return Colors.yellow[700]!;
      default: return Colors.green;
    }
  }
}

// 🎯 EXEMPLO DE USO EM UM WIDGET:

class ChatPersonalPage extends StatefulWidget {
  @override
  _ChatPersonalPageState createState() => _ChatPersonalPageState();
}

class _ChatPersonalPageState extends State<ChatPersonalPage> {
  
  Future<void> _sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8001/personal/chat'),
        headers: {
          'Authorization': 'Bearer YOUR_TOKEN',
          'Content-Type': 'application/json',
        },
        body: json.encode({'message': message}),
      );
      
      // ✨ USAR O TOKEN HANDLER AQUI
      final result = await TokenLimitHandler.handleApiResponse(
        context: context,
        response: response,
        operation: "conversar com o personal trainer",
      );
      
      if (result != null) {
        // Sucesso - exibir resposta
        setState(() {
          // Adicionar mensagem à lista de chat
        });
      }
      // Se result for null, significa que foi bloqueado por limite
      
    } catch (e) {
      // Tratar outros erros
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Trainer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => TokenLimitHandler._showTokenStatusDialog(context),
            tooltip: 'Ver status dos tokens',
          ),
        ],
      ),
      // ... resto do widget
    );
  }
}