import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  String? _token;

  Future<void> initialize() async {
    _dio = Dio(BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60), // Increased for AI requests
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Interceptor para adicionar token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Carrega o token sempre antes da requisição se não estiver carregado
        if (_token == null) {
          await _loadToken();
        }
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Extrai mensagem de erro do backend
        if (error.response?.data != null) {
          final data = error.response!.data;
          if (data is Map && data.containsKey('detail')) {
            // Lança exceção com a mensagem do backend
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                type: error.type,
                error: data['detail'],
                message: data['detail'],
              ),
            );
          }
        }
        return handler.next(error);
      },
    ));

    await _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // ==================== AUTH ====================
  
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _dio.post(
      kAuthRegisterEndpoint,
      data: {
        'email': email,
        'password': password,
        'name': name,
      },
    );
    return response.data;
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      kAuthLoginEndpoint,
      data: {
        'email': email,
        'password': password,
      },
    );
    final token = response.data['access_token'];
    await setToken(token);
    return token;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get(kAuthMeEndpoint);
    return response.data;
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    final response = await _dio.post(
      '/auth/forgot-password',
      queryParameters: {'email': email},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> verifyResetCode({
    required String email,
    required String code,
  }) async {
    final response = await _dio.post(
      '/auth/verify-reset-code',
      queryParameters: {
        'email': email,
        'code': code,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await _dio.post(
      '/auth/reset-password',
      queryParameters: {
        'email': email,
        'code': code,
        'new_password': newPassword,
      },
    );
    return response.data;
  }

  // ==================== PROFILE ====================

  Future<Map<String, dynamic>> createProfile({
    required double weight,
    required double height,
    required int age,
    required String gender,
    required double targetWeight,
    required String activityLevel,
    List<String> dietaryRestrictions = const [],
    List<String> dietaryPreferences = const [],
  }) async {
    final response = await _dio.post(
      kProfileEndpoint,
      data: {
        'weight': weight,
        'height': height,
        'age': age,
        'gender': gender,
        'target_weight': targetWeight,
        'activity_level': activityLevel,
        'dietary_restrictions': dietaryRestrictions,
        'dietary_preferences': dietaryPreferences,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get(kProfileEndpoint);
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile({
    double? weight,
    double? height,
    int? age,
    double? targetWeight,
    String? activityLevel,
  }) async {
    final data = <String, dynamic>{};
    if (weight != null) data['weight'] = weight;
    if (height != null) data['height'] = height;
    if (age != null) data['age'] = age;
    if (targetWeight != null) data['target_weight'] = targetWeight;
    if (activityLevel != null) data['activity_level'] = activityLevel;

    final response = await _dio.put(kProfileEndpoint, data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> checkUpdateNeeded() async {
    final response = await _dio.get('$kProfileEndpoint/check-update-needed');
    return response.data;
  }

  // ==================== CHAT ====================

  Future<Map<String, dynamic>> sendChatMessage(String message) async {
    final response = await _dio.post(
      kChatEndpoint,
      data: {'message': message},
    );
    return response.data;
  }

  Future<List<dynamic>> getChatHistory({int limit = 50}) async {
    final response = await _dio.get(
      kChatHistoryEndpoint,
      queryParameters: {'limit': limit},
    );
    return response.data;
  }

  // ==================== PERSONAL TRAINER ====================

  Future<Map<String, dynamic>> sendPersonalMessage(String message) async {
    print('[API] 📡 Enviando POST para $kPersonalEndpoint com: {"message": "$message"}');
    final response = await _dio.post(
      kPersonalEndpoint,
      data: {'message': message},
      options: Options(
        receiveTimeout: const Duration(seconds: 90), // Extra timeout for AI generation
        sendTimeout: const Duration(seconds: 30),
      ),
    );
    print('[API] ✅ Resposta do servidor: ${response.statusCode} - ${response.data}');
    return response.data;
  }

  // ==================== WORKOUT GENERATION ====================
  
  /// Gera treino com IA sem salvar no histórico do chat personal
  Future<Map<String, dynamic>> generateWorkoutWithAI(String prompt) async {
    print('[API] 🏋️ Gerando treino com IA (sem salvar no chat)...');
    final response = await _dio.post(
      '/workout-plan/generate', // Endpoint separado para geração de treinos
      data: {'prompt': prompt},
      options: Options(
        receiveTimeout: const Duration(seconds: 90), // Extra timeout for AI generation
        sendTimeout: const Duration(seconds: 30),
      ),
    );
    print('[API] ✅ Treino gerado: ${response.statusCode}');
    return response.data;
  }

  Future<List<dynamic>> getPersonalHistory({int limit = 50}) async {
    final response = await _dio.get(
      kPersonalHistoryEndpoint,
      queryParameters: {'limit': limit},
    );
    return response.data;
  }

  // ==================== MEAL PLAN ====================

  /// Gera e salva um novo plano alimentar
  Future<Map<String, dynamic>> generateMealPlan() async {
    final response = await _dio.post(kMealPlanEndpoint);
    return response.data;
  }

  /// Lista todos os planos salvos do usuário
  Future<Map<String, dynamic>> getSavedMealPlans() async {
    final response = await _dio.get(kMealPlanEndpoint);
    return response.data;
  }

  /// Obtém detalhes completos de um plano específico
  Future<Map<String, dynamic>> getMealPlanDetails(String planId) async {
    final response = await _dio.get('$kMealPlanEndpoint/$planId');
    return response.data;
  }

  /// Deleta um plano salvo
  Future<void> deleteMealPlan(String planId) async {
    await _dio.delete('$kMealPlanEndpoint/$planId');
  }

  // ==================== LOGS ====================

  Future<Map<String, dynamic>> logWeight(double weight, {String? notes}) async {
    final response = await _dio.post(
      kWeightLogsEndpoint,
      data: {
        'weight': weight,
        if (notes != null) 'notes': notes,
      },
    );
    return response.data;
  }

  Future<List<dynamic>> getWeightHistory({int limit = 30}) async {
    final response = await _dio.get(
      kWeightLogsEndpoint,
      queryParameters: {'limit': limit},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> logWater(double amount) async {
    final response = await _dio.post(
      kWaterLogsEndpoint,
      data: {'amount': amount},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getWaterToday() async {
    final response = await _dio.get(kWaterTodayEndpoint);
    return response.data;
  }

  Future<Map<String, dynamic>> logMeal({
    required String mealName,
    int? calories,
    String? photoUrl,
    String? notes,
  }) async {
    final response = await _dio.post(
      kMealLogsEndpoint,
      data: {
        'meal_name': mealName,
        if (calories != null) 'calories': calories,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (notes != null) 'notes': notes,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getCaloriesToday() async {
    final response = await _dio.get(kMealTodayEndpoint);
    return response.data;
  }

  // ==================== WORKOUT PLANS ====================

  Future<Map<String, dynamic>> saveWorkoutPlan(Map<String, dynamic> workoutData) async {
    final response = await _dio.post(
      '/workout-plan/',
      data: workoutData,
    );
    return response.data;
  }

  Future<List<dynamic>> getWorkoutPlans() async {
    final response = await _dio.get('/workout-plan/');
    return response.data;
  }

  Future<Map<String, dynamic>> getWorkoutPlanDetails(String planId) async {
    final response = await _dio.get('/workout-plan/$planId');
    return response.data;
  }

  Future<void> deleteWorkoutPlan(String planId) async {
    await _dio.delete('/workout-plan/$planId');
  }
}
