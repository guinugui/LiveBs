import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_service.dart';

class QuickUpdatePage extends StatefulWidget {
  const QuickUpdatePage({super.key});

  @override
  State<QuickUpdatePage> createState() => _QuickUpdatePageState();
}

class _QuickUpdatePageState extends State<QuickUpdatePage> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  bool _isLoading = false;
  String? _weightError;
  String? _heightError;
  String? _ageError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await ApiService().getProfile();
    _weightController.text = profile['weight'].toString();
    _heightController.text = profile['height'].toString();
    _ageController.text = profile['age'].toString();
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    setState(() {
      _weightError = null;
      _heightError = null;
      _ageError = null;
    });
    bool hasError = false;
    if (_weightController.text.isEmpty) {
      setState(() => _weightError = 'Digite seu peso');
      hasError = true;
    }
    if (_heightController.text.isEmpty) {
      setState(() => _heightError = 'Digite sua altura');
      hasError = true;
    }
    if (_ageController.text.isEmpty) {
      setState(() => _ageError = 'Digite sua idade');
      hasError = true;
    }
    if (hasError) return;
    setState(() => _isLoading = true);
    try {
      await ApiService().updateProfile(
        weight: double.parse(_weightController.text.replaceAll(',', '.')),
        height: double.parse(_heightController.text.replaceAll(',', '.')),
        age: int.parse(_ageController.text),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados atualizados com sucesso!'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atualizar Dados Semanais')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Peso (kg)',
                      errorText: _weightError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Altura (cm)',
                      errorText: _heightError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Idade (anos)',
                      errorText: _ageError,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    child: const Text('Salvar'),
                  ),
                ],
              ),
            ),
    );
  }
}
