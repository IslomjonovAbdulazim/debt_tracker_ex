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
      'paymentId': paymentId,
      'originalDebtId': originalDebtId,
      'contactName': contactName,
      'paidAmount': paidAmount,
      'paymentDescription': paymentDescription,
      'paymentDate': paymentDate.toIso8601String(),
      'wasMyDebt': wasMyDebt,
    };
  }

  // Create from JSON response
  factory PaymentHistoryModelBackend.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryModelBackend(
      paymentId: json['paymentId'] ?? json['payment_id'] ?? json['id'] ?? '',
      originalDebtId: json['originalDebtId'] ?? json['original_debt_id'] ?? '',
      contactName: json['contactName'] ?? json['contact_name'] ?? '',
      paidAmount: (json['paidAmount'] ?? json['paid_amount'] ?? 0).toDouble(),
      paymentDescription: json['paymentDescription'] ?? json['payment_description'] ?? '',
      paymentDate: DateTime.parse(
          json['paymentDate'] ?? json['payment_date'] ?? json['created_at'] ?? DateTime.now().toIso8601String()
      ),
      wasMyDebt: json['wasMyDebt'] ?? json['was_my_debt'] ?? false,
    );
  }

  // Create: Save new payment history
  static Future<bool> createPaymentHistory(PaymentHistoryModelBackend paymentHistory) async {
    try {
      final response = await _apiService.post(
        ApiConfig.createPaymentEndpoint,
        {
          'originalDebtId': paymentHistory.originalDebtId,
          'contactName': paymentHistory.contactName,
          'paidAmount': paymentHistory.paidAmount,
          'paymentDescription': paymentHistory.paymentDescription,
          'wasMyDebt': paymentHistory.wasMyDebt,
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
        final List<dynamic> paymentsData = response['payments'] ?? response['data'] ?? [];
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
        return PaymentHistoryModelBackend.fromJson(response['payment'] ?? response['data']);
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
        final List<dynamic> paymentsData = response['payments'] ?? response['data'] ?? [];
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
        final List<dynamic> paymentsData = response['payments'] ?? response['data'] ?? [];
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

  // Read: Get payment history by contact name
  static Future<List<PaymentHistoryModelBackend>> getPaymentsByContact(String contactName) async {
    try {
      final response = await _apiService.get(
          '${ApiConfig.paymentsByContactEndpoint}/${Uri.encodeComponent(contactName)}'
      );

      if (response['success']) {
        final List<dynamic> paymentsData = response['payments'] ?? response['data'] ?? [];
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
      final response = await _apiService.get(ApiConfig.recentPaymentsEndpoint);

      if (response['success']) {
        final List<dynamic> paymentsData = response['payments'] ?? response['data'] ?? [];
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
          'originalDebtId': updatedPayment.originalDebtId,
          'contactName': updatedPayment.contactName,
          'paidAmount': updatedPayment.paidAmount,
          'paymentDescription': updatedPayment.paymentDescription,
          'wasMyDebt': updatedPayment.wasMyDebt,
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