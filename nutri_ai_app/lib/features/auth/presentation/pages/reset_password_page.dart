import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_service.dart';
import 'package:dio/dio.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String code;
  
  const ResetPasswordPage({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    setState(() {
      _passwordError = null;
      _confirmPasswordError = null;
      _isLoading = true;
    });

    bool hasError = false;

    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = 'Digite a nova senha');
      hasError = true;
    } else if (_passwordController.text.length < 6) {
      setState(() => _passwordError = 'Senha deve ter pelo menos 6 caracteres');
      hasError = true;
    }

    if (_confirmPasswordController.text.isEmpty) {
      setState(() => _confirmPasswordError = 'Confirme a senha');
      hasError = true;
    } else if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _confirmPasswordError = 'Senhas não coincidem');
      hasError = true;
    }

    if (hasError) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      await ApiService().resetPassword(
        email: widget.email,
        code: widget.code,
        newPassword: _passwordController.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Senha alterada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Volta para tela de login
        context.go('/login');
      }
    } catch (e) {
      String errorMessage = 'Erro ao alterar senha';
      
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data.containsKey('detail')) {
          errorMessage = e.response!.data['detail'];
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova senha'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.lock_reset,
              size: 80,
              color: Color(0xFF4CAF50),
            ),
            const SizedBox(height: 32),
            
            Text(
              'Criar nova senha',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Digite sua nova senha abaixo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Nova senha',
                hintText: 'Digite sua nova senha',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                errorText: _passwordError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirmar senha',
                hintText: 'Digite novamente sua nova senha',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                errorText: _confirmPasswordError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
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
                      'Alterar senha',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}