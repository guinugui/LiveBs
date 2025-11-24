import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_service.dart';
import 'package:dio/dio.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _emailError = null;
      _isLoading = true;
    });

    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = 'Digite seu email';
        _isLoading = false;
      });
      return;
    }

    try {
      await ApiService().forgotPassword(email: _emailController.text.trim());
      
      if (mounted) {
        // Navega para tela de verificação de código
        context.push('/verify-code?email=${Uri.encodeComponent(_emailController.text.trim())}');
      }
    } catch (e) {
      String errorMessage = 'Erro ao enviar código';
      
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data.containsKey('detail')) {
          errorMessage = e.response!.data['detail'];
        }
      }

      setState(() {
        _emailError = errorMessage;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Esqueci minha senha'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 80,
              color: Color(0xFF4CAF50),
            ),
            const SizedBox(height: 32),
            
            Text(
              'Recuperar senha',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Digite seu email para receber um código de recuperação de senha.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Digite seu email',
                prefixIcon: const Icon(Icons.email_outlined),
                errorText: _emailError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _sendCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Enviar código',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            
            const SizedBox(height: 16),
            
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Voltar para login'),
            ),
          ],
        ),
      ),
    );
  }
}