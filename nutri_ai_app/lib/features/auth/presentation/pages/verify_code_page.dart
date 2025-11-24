import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_service.dart';
import 'package:dio/dio.dart';

class VerifyCodePage extends StatefulWidget {
  final String email;
  
  const VerifyCodePage({
    super.key,
    required this.email,
  });

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _codeError;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    setState(() {
      _codeError = null;
      _isLoading = true;
    });

    if (_codeController.text.isEmpty) {
      setState(() {
        _codeError = 'Digite o código';
        _isLoading = false;
      });
      return;
    }

    try {
      await ApiService().verifyResetCode(
        email: widget.email,
        code: _codeController.text.trim(),
      );
      
      if (mounted) {
        // Navega para tela de redefinir senha
        context.pushReplacement('/reset-password?email=${Uri.encodeComponent(widget.email)}&code=${Uri.encodeComponent(_codeController.text.trim())}');
      }
    } catch (e) {
      String errorMessage = 'Código inválido ou expirado';
      
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data.containsKey('detail')) {
          errorMessage = e.response!.data['detail'];
        }
      }

      setState(() {
        _codeError = errorMessage;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    try {
      await ApiService().forgotPassword(email: widget.email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Novo código enviado para seu email!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao reenviar código'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar código'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.mail_outline,
              size: 80,
              color: Color(0xFF4CAF50),
            ),
            const SizedBox(height: 32),
            
            Text(
              'Código enviado!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            Text(
              'Digite o código de 6 dígitos que enviamos para:',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            
            Text(
              widget.email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 32),
            
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                labelText: 'Código de verificação',
                hintText: '000000',
                errorText: _codeError,
                border: const OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyCode,
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
                      'Verificar código',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Não recebeu o código? '),
                TextButton(
                  onPressed: _resendCode,
                  child: const Text(
                    'Reenviar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
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