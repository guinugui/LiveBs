import 'package:flutter/material.dart';
import '../../../../core/network/ai_service.dart';
import '../../../../core/utils/profile_utils.dart';
import 'meal_plan_display_page.dart';

class NutritionPreferencesPage extends StatefulWidget {
  const NutritionPreferencesPage({super.key});

  @override
  State<NutritionPreferencesPage> createState() => _NutritionPreferencesPageState();
}

class _NutritionPreferencesPageState extends State<NutritionPreferencesPage> {
  final List<String> _selectedAllergies = [];
  final List<String> _selectedDislikes = [];
  final List<String> _selectedDietaryPreferences = [];
  String _selectedDietaryStyle = 'Tradicional';
  bool _isLoading = false;

  final List<String> _allergiesOptions = [
    'Glúten',
    'Lactose',
    'Amendoim',
    'Frutos do mar',
    'Ovos',
    'Soja',
    'Nozes e castanhas',
    'Peixes',
  ];

  final List<String> _dislikesOptions = [
    'Brócolis',
    'Couve-flor',
    'Espinafre',
    'Peixe',
    'Frango',
    'Carne vermelha',
    'Feijão',
    'Queijos',
    'Ovos',
    'Tomate',
  ];

  final List<String> _dietaryPreferencesOptions = [
    'Low carb',
    'Rica em proteínas',
    'Rica em fibras',
    'Sem açúcar refinado',
    'Comida caseira',
    'Pratos rápidos',
    'Alimentos funcionais',
    'Superalimentos',
  ];

  final List<String> _dietaryStyleOptions = [
    'Tradicional',
    'Vegetariano',
    'Vegano',
    'Pescetariano',
    'Low Carb',
    'Cetogênico',
    'Mediterrâneo',
    'Paleo',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Nutricionista IA',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Gerando seu cardápio personalizado...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🥗 Vamos criar seu cardápio personalizado!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Conte-nos sobre suas preferências alimentares para receber um plano nutricional ideal.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Estilo alimentar
                  _buildSectionCard(
                    title: '🍽️ Qual seu estilo alimentar?',
                    child: Column(
                      children: _dietaryStyleOptions.map((style) {
                        return RadioListTile<String>(
                          title: Text(style),
                          value: style,
                          groupValue: _selectedDietaryStyle,
                          activeColor: const Color(0xFF2E7D32),
                          onChanged: (String? value) {
                            setState(() {
                              _selectedDietaryStyle = value ?? 'Tradicional';
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Alergias alimentares
                  _buildSectionCard(
                    title: '⚠️ Você tem alguma alergia alimentar?',
                    child: Column(
                      children: _allergiesOptions.map((allergy) {
                        return CheckboxListTile(
                          title: Text(allergy),
                          value: _selectedAllergies.contains(allergy),
                          activeColor: const Color(0xFF2E7D32),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedAllergies.add(allergy);
                              } else {
                                _selectedAllergies.remove(allergy);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Alimentos que não gosta
                  _buildSectionCard(
                    title: '🚫 Quais alimentos você não gosta?',
                    child: Column(
                      children: _dislikesOptions.map((dislike) {
                        return CheckboxListTile(
                          title: Text(dislike),
                          value: _selectedDislikes.contains(dislike),
                          activeColor: const Color(0xFF2E7D32),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedDislikes.add(dislike);
                              } else {
                                _selectedDislikes.remove(dislike);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Preferências dietéticas
                  _buildSectionCard(
                    title: '🎯 Suas preferências dietéticas:',
                    child: Column(
                      children: _dietaryPreferencesOptions.map((preference) {
                        return CheckboxListTile(
                          title: Text(preference),
                          value: _selectedDietaryPreferences.contains(preference),
                          activeColor: const Color(0xFF2E7D32),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedDietaryPreferences.add(preference);
                              } else {
                                _selectedDietaryPreferences.remove(preference);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Botão Gerar Plano
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _generateMealPlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Gerar Cardápio Personalizado',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    '💡 Dica: Seja honesto sobre suas restrições para receber um cardápio que você realmente vai seguir!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Future<void> _generateMealPlan() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Buscar perfil do usuário
      final userProfile = await ProfileUtils.getUserProfile();
      
      if (userProfile == null) {
        throw Exception('Perfil do usuário não encontrado');
      }

      // Gerar plano alimentar
      final aiService = AIService();
      final mealPlan = await aiService.generateMealPlan(
        userProfile: userProfile,
        allergies: _selectedAllergies,
        dislikes: _selectedDislikes,
        dietaryPreferences: _selectedDietaryPreferences,
        dietaryStyle: _selectedDietaryStyle,
      );

      setState(() {
        _isLoading = false;
      });

      // Navegar para página de exibição do plano
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MealPlanDisplayPage(mealPlan: mealPlan),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar cardápio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}