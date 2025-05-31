import '../services/api_service.dart';
import '../config/api_config.dart';

class PaymentHistoryModelBackend {
  static final ApiService _apiService = ApiService();

  final String paymentId;
  final String originalDebtId;
  final String contactName;
  final double paidAmount;
  final String paymentDescription;
  final DateTime paymentDate;
  final bool wasMyDebt; // Was it me who owed or they who owed

  PaymentHistoryModelBackend({
    required this.paymentId,
    required this.originalDebtId,
    required this.contactName,
    required this.paidAmount,
    required this.paymentDescription,
    required this.paymentDate,
    required this.wasMyDebt,
  });

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': paymentId,
      'original_debt_id': originalDebtId,  // Changed to snake_case
      'contact_name': contactName,  // Changed to snake_case
      'paid_amount': paidAmount,  // Changed to snake_case
      'payment_description': paymentDescription,  // Changed to snake_case
      'payment_date': paymentDate.toIso8601String(),  // Changed to snake_case
      'was_my_debt': wasMyDebt,  // Changed to snake_case
    };
  }

  // Create from JSON response
  factory PaymentHistoryModelBackend.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryModelBackend(
      paymentId: json['id']?.toString() ?? '',  // API uses 'id'
      originalDebtId: json['original_debt_id']?.toString() ?? '',
      contactName: json['contact_name'] ?? '',
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      paymentDescription: json['payment_description'] ?? '',
      paymentDate: DateTime.parse(
          json['payment_date'] ?? DateTime.now().toIso8601String()
      ),
      wasMyDebt: json['was_my_debt'] ?? false,
    );
  }

  // Create: Save new payment history
  static Future<bool> createPaymentHistory(PaymentHistoryModelBackend paymentHistory) async {
    try {
      final response = await _apiService.post(
        ApiConfig.createPaymentEndpoint,
        {
          'original_debt_id': paymentHistory.originalDebtId,
          'contact_name': paymentHistory.contactName,
          'paid_amount': paymentHistory.paidAmount,
          'payment_description': paymentHistory.paymentDescription,
          'was_my_debt': paymentHistory.wasMyDebt,
        },
      );

      return response['success'] ?? false;
    } catch (e) {
      print('Create payment history error: $e');
      return false;
    }
  }

  // Read: Get all payment histories
  static Future<List<PaymentHistoryModelBackend>> getAllPaymentHistories() async {
    try {
      final response = await _apiService.get(ApiConfig.paymentsEndpoint);

      if (response['success']) {
        final List<dynamic> paymentsData = response['data']?['payments'] ?? [];
        return paymentsData
            .map((json) => PaymentHistoryModelBackend.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print('Get all payment histories error: $e');
      return [];
    }
  }

  // Read: Get payment history by ID
  static Future<PaymentHistoryModelBackend?> getPaymentHistoryById(String paymentId) async {
    try {
      final response = await _apiService.get('${ApiConfig.paymentsEndpoint}/$paymentId');

      if (response['success']) {
        return PaymentHistoryModelBackend.fromJson(response['data']['payment']);
      }

      return null;
    } catch (e) {
      print('Get payment history by ID error: $e');
      return null;
    }
  }

  // Read: Get payments where I paid back
  static Future<List<PaymentHistoryModelBackend>> getMyPayments() async {
    try {
      final response = await _apiService.get(ApiConfig.myPaymentsEndpoint);

      if (response['success']) {
        final List<dynamic> paymentsData = response['data']?['payments'] ?? [];
        return paymentsData
            .map((json) => PaymentHistoryModelBackend.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print('Get my payments error: $e');
      return [];
    }
  }

  // Read: Get payments where they paid me back
  static Future<List<PaymentHistoryModelBackend>> getTheirPayments() async {
    try {
      final response = await _apiService.get(ApiConfig.theirPaymentsEndpoint);

      if (response['success']) {
        final List<dynamic> paymentsData = response['data']?['payments'] ?? [];
        return paymentsData
            .map((json) => PaymentHistoryModelBackend.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print('Get their payments error: $e');
      return [];
    }
  }

  // Read: Get payment history by contact name using query parameter
  static Future<List<PaymentHistoryModelBackend>> getPaymentsByContact(String contactName) async {
    try {
      final response = await _apiService.get(
          '${ApiConfig.paymentsByContactEndpoint}?contact_name=${Uri.encodeComponent(contactName)}'
      );

      if (response['success']) {
        final List<dynamic> paymentsData = response['data']?['payments'] ?? [];
        return paymentsData
            .map((json) => PaymentHistoryModelBackend.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print('Get payments by contact error: $e');
      return [];
    }
  }

  // Read: Get recent payment histories (last 30 days)
  static Future<List<PaymentHistoryModelBackend>> getRecentPayments() async {
    try {
      // Calculate date 30 days ago
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      final dateFromStr = thirtyDaysAgo.toIso8601String().split('T')[0]; // Only date part

      final response = await _apiService.get('${ApiConfig.recentPaymentsEndpoint}?date_from=$dateFromStr');

      if (response['success']) {
        final List<dynamic> paymentsData = response['data']?['payments'] ?? [];
        return paymentsData
            .map((json) => PaymentHistoryModelBackend.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print('Get recent payments error: $e');
      return [];
    }
  }

  // Update: Update existing payment history
  static Future<bool> updatePaymentHistory(PaymentHistoryModelBackend updatedPayment) async {
    try {
      final response = await _apiService.put(
        '${ApiConfig.paymentsEndpoint}/${updatedPayment.paymentId}',
        {
          'original_debt_id': updatedPayment.originalDebtId,
          'contact_name': updatedPayment.contactName,
          'paid_amount': updatedPayment.paidAmount,
          'payment_description': updatedPayment.paymentDescription,
          'was_my_debt': updatedPayment.wasMyDebt,
        },
      );

      return response['success'] ?? false;
    } catch (e) {
      print('Update payment history error: $e');
      return false;
    }
  }

  // Delete: Remove payment history
  static Future<bool> deletePaymentHistory(String paymentId) async {
    try {
      final response = await _apiService.delete('${ApiConfig.paymentsEndpoint}/$paymentId');
      return response['success'] ?? false;
    } catch (e) {
      print('Delete payment history error: $e');
      return false;
    }
  }

  // Calculate: Get total amount I have paid back
  static Future<double> getTotalAmountIPaid() async {
    try {
      final response = await _apiService.get('${ApiConfig.paymentsEndpoint}?type=my_payments');

      if (response['success']) {
        return (response['data']?['summary']?['total_paid_by_me'] ?? 0).toDouble();
      }

      // Fallback: calculate from individual payments
      final myPayments = await getMyPayments();
      double total = 0.0;
      for (PaymentHistoryModelBackend payment in myPayments) {
        total += payment.paidAmount;
      }
      return total;
    } catch (e) {
      print('Get total amount I paid error: $e');
      return 0.0;
    }
  }

  // Calculate: Get total amount they have paid me back
  static Future<double> getTotalAmountTheyPaid() async {
    try {
      final response = await _apiService.get('${ApiConfig.paymentsEndpoint}?type=their_payments');

      if (response['success']) {
        return (response['data']?['summary']?['total_paid_to_me'] ?? 0).toDouble();
      }

      // Fallback: calculate from individual payments
      final theirPayments = await getTheirPayments();
      double total = 0.0;
      for (PaymentHistoryModelBackend payment in theirPayments) {
        total += payment.paidAmount;
      }
      return total;
    } catch (e) {
      print('Get total amount they paid error: $e');
      return 0.0;
    }
  }

  // Clear: Delete all payment histories
  static Future<bool> clearAllPaymentHistories() async {
    try {
      final response = await _apiService.delete(ApiConfig.paymentsEndpoint);
      return response['success'] ?? false;
    } catch (e) {
      print('Clear all payment histories error: $e');
      return false;
    }
  }
}