import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teste Meal Plan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const MealPlanTestPage(),
    );
  }
}

class MealPlanTestPage extends StatefulWidget {
  const MealPlanTestPage({super.key});

  @override
  State<MealPlanTestPage> createState() => _MealPlanTestPageState();
}

class _MealPlanTestPageState extends State<MealPlanTestPage> {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = false;
  bool _isCreating = false;
  
  static const String baseUrl = 'http://192.168.0.85:8000';
  static const String userEmail = 'gui@gmail.com';
  static const String userPassword = '123123';

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  /// 🔍 BUSCA PLANOS SALVOS
  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    
    try {
      print('🔍 Buscando planos para: $userEmail');
      
      // 1. Login
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': userEmail,
          'password': userPassword,
        }),
      );
      
      if (loginResponse.statusCode != 200) {
        throw Exception('Login falhou: ${loginResponse.body}');
      }
      
      final loginData = json.decode(loginResponse.body);
      final token = loginData['access_token'];
      
      // 2. Buscar planos
      final plansResponse = await http.get(
        Uri.parse('$baseUrl/meal-plan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (plansResponse.statusCode != 200) {
        throw Exception('Erro ao buscar planos: ${plansResponse.body}');
      }
      
      final plansData = json.decode(plansResponse.body);
      final plans = List<Map<String, dynamic>>.from(plansData['plans'] ?? []);
      
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
      
      _showSnackBar('${plans.length} planos encontrados', Colors.green);
      
    } catch (e) {
      print('❌ Erro ao buscar planos: $e');
      setState(() => _isLoading = false);
      _showSnackBar('Erro ao carregar: $e', Colors.red);
    }
  }

  /// ➕ CRIAR NOVO PLANO
  Future<void> _createPlan() async {
    setState(() => _isCreating = true);
    
    try {
      print('🚀 Criando novo plano...');
      
      // 1. Login
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': userEmail,
          'password': userPassword,
        }),
      );
      
      if (loginResponse.statusCode != 200) {
        throw Exception('Login falhou');
      }
      
      final loginData = json.decode(loginResponse.body);
      final token = loginData['access_token'];
      
      // 2. Criar plano
      final createResponse = await http.post(
        Uri.parse('$baseUrl/meal-plan/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (createResponse.statusCode != 200 && createResponse.statusCode != 201) {
        throw Exception('Erro ao criar plano: ${createResponse.body}');
      }
      
      final result = json.decode(createResponse.body);
      
      setState(() => _isCreating = false);
      
      _showSnackBar('${result['plan_name']} criado!', Colors.green);
      
      // Recarregar lista
      await _loadPlans();
      
    } catch (e) {
      print('❌ Erro ao criar plano: $e');
      setState(() => _isCreating = false);
      _showSnackBar('Erro ao criar: $e', Colors.red);
    }
  }

  /// 🗑️ DELETAR PLANO
  Future<void> _deletePlan(String planId, String planName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text('Deletar "$planName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deletar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirmed) return;
    
    try {
      // 1. Login
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': userEmail,
          'password': userPassword,
        }),
      );
      
      if (loginResponse.statusCode != 200) {
        throw Exception('Login falhou');
      }
      
      final loginData = json.decode(loginResponse.body);
      final token = loginData['access_token'];
      
      // 2. Deletar
      final deleteResponse = await http.delete(
        Uri.parse('$baseUrl/meal-plan/$planId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (deleteResponse.statusCode != 200) {
        throw Exception('Erro ao deletar');
      }
      
      _showSnackBar('$planName deletado!', Colors.green);
      
      // Recarregar
      await _loadPlans();
      
    } catch (e) {
      _showSnackBar('Erro ao deletar: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🍽️ Planos Alimentares'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadPlans,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCreating ? null : _createPlan,
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        icon: _isCreating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add),
        label: Text(_isCreating ? 'Criando...' : 'Criar Plano'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text('Carregando planos...'),
          ],
        ),
      );
    }
    
    if (_plans.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum plano criado ainda',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Toque no botão "+" para criar seu primeiro plano'),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadPlans,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _plans.length,
        itemBuilder: (context, index) {
          final plan = _plans[index];
          final planName = plan['plan_name']?.toString() ?? 'Plano ${index + 1}';
          final planId = plan['id']?.toString() ?? '';
          final createdAt = plan['created_at']?.toString() ?? '';
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green[600],
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                planName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: createdAt.isNotEmpty
                  ? Text('Criado em ${createdAt.substring(0, 10)}')
                  : null,
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _deletePlan(planId, planName);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Deletar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () {
                _showSnackBar('Detalhes do plano: $planName', Colors.blue);
              },
            ),
          );
        },
      ),
    );
  }
}