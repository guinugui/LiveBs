import '../../../core/network/api_service.dart';

class SubscriptionService {
  final ApiService _apiService = ApiService();

  /// Criar assinatura PIX
  Future<SubscriptionResponse> createSubscription({
    String planType = 'monthly',
    double amount = 39.90,
  }) async {
    try {
      final response = await _apiService.post(
        '/subscription/create',
        data: {
          'plan_type': planType,
          'amount': amount,
        },
        requireAuth: true,
      );

      return SubscriptionResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao criar assinatura: $e');
    }
  }

  /// Verificar status da assinatura
  Future<SubscriptionStatusResponse> getSubscriptionStatus() async {
    try {
      final response = await _apiService.get(
        '/subscription/status',
        requireAuth: true,
      );

      return SubscriptionStatusResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao verificar status: $e');
    }
  }

  /// Abrir URL do pagamento PIX
  Future<void> openPaymentUrl(String paymentUrl) async {
    try {
      // Usar url_launcher para abrir URL do PIX
      final uri = Uri.parse(paymentUrl);
      // await launchUrl(uri, mode: LaunchMode.externalApplication);
      print('Abrir URL: $paymentUrl');
    } catch (e) {
      throw Exception('Erro ao abrir pagamento: $e');
    }
  }
}

class SubscriptionResponse {
  final String paymentUrl;
  final String paymentId;
  final String status;
  final String? qrCode;

  SubscriptionResponse({
    required this.paymentUrl,
    required this.paymentId,
    required this.status,
    this.qrCode,
  });

  factory SubscriptionResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionResponse(
      paymentUrl: json['payment_url'] ?? '',
      paymentId: json['payment_id'] ?? '',
      status: json['status'] ?? '',
      qrCode: json['qr_code'],
    );
  }
}

class SubscriptionStatusResponse {
  final String userId;
  final String subscriptionStatus;
  final String? subscriptionPaymentId;
  final DateTime? subscriptionDate;
  final bool isActive;

  SubscriptionStatusResponse({
    required this.userId,
    required this.subscriptionStatus,
    this.subscriptionPaymentId,
    this.subscriptionDate,
    required this.isActive,
  });

  factory SubscriptionStatusResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatusResponse(
      userId: json['user_id'] ?? '',
      subscriptionStatus: json['subscription_status'] ?? 'pending',
      subscriptionPaymentId: json['subscription_payment_id'],
      subscriptionDate: json['subscription_date'] != null 
          ? DateTime.parse(json['subscription_date'])
          : null,
      isActive: json['is_active'] ?? false,
    );
  }
}