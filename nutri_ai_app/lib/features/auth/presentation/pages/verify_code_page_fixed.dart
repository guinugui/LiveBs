import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final code = _controllers.map((c) => c.text).join();
    
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Digite o código de 6 dígitos';
        _isLoading = false;
      });
      return;
    }

    try {
      await ApiService().verifyResetCode(
        email: widget.email,
        code: code,
      );
      
      if (mounted) {
        context.push('/reset-password', extra: {
          'email': widget.email,
          'code': code,
        });
      }
    } catch (e) {
      String errorMessage = 'Código inválido ou expirado';
      
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data.containsKey('detail')) {
          errorMessage = e.response!.data['detail'];
        }
      }

      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
    }
  }

  Future<void> _resendCode() async {
    try {
      await ApiService().forgotPassword(email: widget.email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Novo código enviado para seu email'),
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
              Icons.mark_email_read_outlined,
              size: 80,
              color: Color(0xFF4CAF50),
            ),
            const SizedBox(height: 32),
            
            Text(
              'Código enviado',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            Text(
              'Digite o código de 6 dígitos enviado para\n${widget.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            
            // Campo de entrada do código (6 dígitos)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 50,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        if (index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        }
                      } else {
                        if (index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      }
                    },
                  ),
                );
              }),
            ),
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            
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
            
            TextButton(
              onPressed: _resendCode,
              child: const Text('Reenviar código'),
            ),
          ],
        ),
      ),
    );
  }
}