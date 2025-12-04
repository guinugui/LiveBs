import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../subscription/subscription_service.dart';
import '../../../subscription/subscription_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Limpa erros anteriores
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await ApiService().login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await ApiService().setToken(token);

      // Salva email para uso posterior
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', _emailController.text.trim());

      // Agendar notificações para usuário logado
      try {
        await NotificationService().scheduleAllNotifications();
      } catch (e) {
        print('Erro ao agendar notificações: $e');
      }

      // Verificar status da assinatura
      try {
        final subscriptionService = SubscriptionService();
        final status = await subscriptionService.getSubscriptionStatus();
        
        if (!status.isActive) {
          // Usuário não tem assinatura ativa - redirecionar para tela de assinatura
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SubscriptionPage(
                  onSubscriptionComplete: () {
                    // Após pagamento, continuar o fluxo normal
                    _continueLoginFlow();
                  },
                ),
              ),
            );
          }
          return; // Sair da função para não continuar o fluxo
        }
        
        // Assinatura ativa - continuar fluxo normal
        _continueLoginFlow();
      } catch (e) {
        print('Erro ao verificar assinatura: $e');
        // Em caso de erro na verificação, assumir que precisa de assinatura
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SubscriptionPage(
                onSubscriptionComplete: () {
                  _continueLoginFlow();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erro ao fazer login';

        final errorStr = e.toString();
        if (errorStr.contains('401') || errorStr.contains('Unauthorized')) {
          errorMessage = 'Email ou senha incorretos';
        } else if (errorStr.contains('404') || errorStr.contains('not found')) {
          errorMessage = 'Usuário não encontrado';
        } else if (errorStr.contains('Network')) {
          errorMessage = 'Erro de conexão. Verifique sua internet.';
        } else if (errorStr.contains('400')) {
          errorMessage = 'Dados inválidos. Verifique os campos.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _continueLoginFlow() async {
    // Verifica se o usuário tem perfil
    try {
      await ApiService().getProfile();
      // Se chegou aqui, tem perfil - vai para home
      if (mounted) {
        context.go('/home');
      }
    } catch (profileError) {
      // Se deu erro ao buscar perfil, redireciona para onboarding
      print('DEBUG - Perfil não encontrado, indo para onboarding');
      if (mounted) {
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Icon
                  const Icon(
                    Icons.favorite,
                    size: 80,
                    color: Color(0xFF6C63FF),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'LiveBs',
                    style: Theme.of(context).textTheme.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Viva melhor e mais saudável',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      errorText: _emailError,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu email';
                      }
                      if (!value.contains('@')) {
                        return 'Email inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      errorText: _passwordError,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira sua senha';
                      }
                      if (value.length < 6) {
                        return 'Senha deve ter no mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Entrar'),
                  ),
                  const SizedBox(height: 16),

                  // Forgot Password Link
                  TextButton(
                    onPressed: () => context.go('/forgot-password'),
                    child: const Text(
                      'Esqueci minha senha',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Não tem uma conta?'),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: const Text('Cadastre-se'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
