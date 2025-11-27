import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  late final Dio _dio;
  final String _apiKey;

  OpenAIService() : _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '' {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.openai.com/v1',
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  Future<String> sendChatMessage(
    String message,
    List<Map<String, String>> history,
  ) async {
    try {
      final messages = [
        {
          'role': 'system',
          'content':
              '''Você é Dr. Nutri, um nutricionista virtual especializado em emagrecimento saudável.
Suas responsabilidades:
- Fornecer orientações nutricionais personalizadas
- Sugerir planos alimentares balanceados
- Responder dúvidas sobre alimentos e nutrição
- Motivar e apoiar emocionalmente
- Adaptar recomendações conforme perfil do usuário
- Sempre priorizar a saúde e bem-estar

Tom: amigável, profissional, motivador
Sempre responda em português do Brasil.''',
        },
        ...history,
        {'role': 'user', 'content': message},
      ];

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'gpt-4o',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 500,
        },
      );

      return response.data['choices'][0]['message']['content'];
    } catch (e) {
      throw Exception('Erro ao comunicar com IA: $e');
    }
  }

  Future<Map<String, dynamic>> generateMealPlan({
    required double calories,
    required String activityLevel,
    required List<String> restrictions,
    required List<String> preferences,
  }) async {
    try {
      final prompt =
          '''
Crie um plano alimentar para 7 dias com as seguintes especificações:
- Calorias diárias: $calories kcal
- Nível de atividade: $activityLevel
- Restrições: ${restrictions.join(', ')}
- Preferências: ${preferences.join(', ')}

Formato JSON:
{
  "days": [
    {
      "day": 1,
      "meals": [
        {
          "type": "breakfast",
          "name": "Nome da refeição",
          "calories": 400,
          "protein": 20,
          "carbs": 50,
          "fat": 10,
          "recipe": "Modo de preparo detalhado"
        }
      ]
    }
  ]
}
''';

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Você é um nutricionista especializado. Retorne apenas JSON válido.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.8,
          'response_format': {'type': 'json_object'},
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      return {'success': true, 'data': content};
    } catch (e) {
      throw Exception('Erro ao gerar plano alimentar: $e');
    }
  }
}
