import '../services/api_service.dart';
import '../config/api_config.dart';
import '../config/app_logger.dart';

class PaymentHistoryModelBackend {
  static final ApiService _apiService = ApiService();

  final String paymentId;
  final int contact;
  final double debtAmount;
  final String description;
  final bool isMyDebt;
  final DateTime dueDate;

  PaymentHistoryModelBackend({
    required this.paymentId,
    required this.contact,
    required this.debtAmount,
    required this.description,
    required this.isMyDebt,
    required this.dueDate,
  });

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': paymentId,
      'contact': contact,
      'debt_amount': debtAmount.toString(),
      'description': description,
      'is_my_debt': isMyDebt,
      'due_date': dueDate.toIso8601String(),
    };
  }

  // Create from JSON response - Updated to match API structure
  factory PaymentHistoryModelBackend.fromJson(Map<String, dynamic> json) {
    AppLogger.debug('Creating PaymentHistoryModelBackend from JSON: $json', tag: 'PAYMENT');

    return PaymentHistoryModelBackend(
      paymentId: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      contact: json['contact'] ?? 0,
      debtAmount: _parseAmount(json['debt_amount']),
      description: json['description'] ?? '',
      isMyDebt: json['is_my_debt'] ?? false,
      dueDate: DateTime.parse(json['due_date'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Helper method to parse amount safely
  static double _parseAmount(dynamic amount) {
    if (amount == null || amount == '') return 0.0;
    if (amount is num) return amount.toDouble();
    if (amount is String) {
      final parsed = double.tryParse(amount);
      return parsed?.abs() ?? 0.0; // Use absolute value for display
    }
    return 0.0;
  }

  // Get display amount (always positive for UI)
  double get displayAmount => debtAmount.abs();

  // Get contact name (placeholder since API returns contact ID)
  String get contactName => 'Contact $contact';

  // Get payment date (using due_date from API)
  DateTime get paymentDate => dueDate;

  // Get payment description
  String get paymentDescription => description.isNotEmpty ? description : 'Payment recorded';

  // Determine if this was my payment or theirs
  bool get wasMyDebt => isMyDebt;

  // Create: Save new payment history
  static Future<bool> createPaymentHistory(PaymentHistoryModelBackend paymentHistory) async {
    AppLogger.dataOperation('CREATE', 'Payment', id: paymentHistory.paymentId);

    try {
      final response = await _apiService.post(
        ApiConfig.createPaymentEndpoint,
        {
          'contact': paymentHistory.contact,
          'debt_amount': paymentHistory.debtAmount.toString(),
          'description': paymentHistory.description,
          'is_my_debt': paymentHistory.isMyDebt,
          'due_date': paymentHistory.dueDate.toIso8601String(),
        },
      );

      final success = response['success'] ?? false;
      AppLogger.dataOperation('CREATE', 'Payment', success: success);
      return success;
    } catch (e) {
      AppLogger.error('Create payment history error', tag: 'PAYMENT', error: e);
      AppLogger.dataOperation('CREATE', 'Payment', success: false);
      return false;
    }
  }

  // Read: Get all payment histories
  static Future<List<PaymentHistoryModelBackend>> getAllPaymentHistories() async {
    AppLogger.info('Fetching all payment histories', tag: 'PAYMENT');

    try {
      final response = await _apiService.get(ApiConfig.paymentsEndpoint);

      if (response['success']) {
        // API returns array directly
        final List<dynamic> paymentsData = response['data'] ?? [];

        AppLogger.info('Retrieved ${paymentsData.length} payments', tag: 'PAYMENT');

        return paymentsData
            .map((json) => PaymentHistoryModelBackend.fromJson(json))
            .toList();
      }

      AppLogger.warning('Failed to get payments: ${response['message']}', tag: 'PAYMENT');
      return [];
    } catch (e) {
      AppLogger.error('Get all payment histories error', tag: 'PAYMENT', error: e);
      return [];
    }
  }

  // Read: Get payment history by ID
  static Future<PaymentHistoryModelBackend?> getPaymentHistoryById(String paymentId) async {
    AppLogger.info('Fetching payment by ID: $paymentId', tag: 'PAYMENT');

    try {
      final response = await _apiService.get('${ApiConfig.paymentsEndpoint}/$paymentId');

      if (response['success']) {
        // Assuming single payment returned in array or object
        final paymentData = response['data'];
        if (paymentData is List && paymentData.isNotEmpty) {
          return PaymentHistoryModelBackend.fromJson(paymentData.first);
        } else if (paymentData is Map<String, dynamic>) {
          return PaymentHistoryModelBackend.fromJson(paymentData);
        }
      }

      AppLogger.warning('Payment not found: $paymentId', tag: 'PAYMENT');
      return null;
    } catch (e) {
      AppLogger.error('Get payment history by ID error', tag: 'PAYMENT', error: e);
      return null;
    }
  }

  // Read: Get payments where I paid back (my payments)
  static Future<List<PaymentHistoryModelBackend>> getMyPayments() async {
    AppLogger.info('Fetching my payments', tag: 'PAYMENT');

    try {
      final response = await _apiService.get(ApiConfig.myPaymentsEndpoint);

      if (response['success']) {
        final List<dynamic> paymentsData = response['data'] ?? [];

        AppLogger.info('Retrieved ${paymentsData.length} my payments', tag: 'PAYMENT');

        return paymentsData
            .map((json) => PaymentHistoryModelBackend.fromJson(json))
            .toList();
      }

      AppLogger.warning('Failed to get my payments: ${response['message']}', tag: 'PAYMENT');
      return [];
    } catch (e) {
      AppLogger.error('Get my payments error', tag: 'PAYMENT', error: e);
      return [];
    }
  }

  // Read: Get payments where they paid me back (their payments)
  static Future<List<PaymentHistoryModelBackend>> getTheirPayments() async {
    AppLogger.info('Fetching their payments', tag: 'PAYMENT');

    try {
      final response = await _apiService.get(ApiConfig.theirPaymentsEndpoint);

      if (response['success']) {
        final List<dynamic> paymentsData = response['data'] ?? [];

        AppLogger.info('Retrieved ${paymentsData.length} their payments', tag: 'PAYMENT');

        return paymentsData
            .map((json) => PaymentHistoryModelBackend.fromJson(json))
            .toList();
      }

      AppLogger.warning('Failed to get their payments: ${response['message']}', tag: 'PAYMENT');
      return [];
    } catch (e) {
      AppLogger.error('Get their payments error', tag: 'PAYMENT', error: e);
      return [];
    }
  }

  // Read: Get payment history by contact ID
  static Future<List<PaymentHistoryModelBackend>> getPaymentsByContact(int contactId) async {
    AppLogger.info('Fetching payments for contact: $contactId', tag: 'PAYMENT');

    try {
      // Get all payments and filter by contact
      final allPayments = await getAllPaymentHistories();
      final contactPayments = allPayments.where((payment) => payment.contact == contactId).toList();

      AppLogger.info('Found ${contactPayments.length} payments for contact $contactId', tag: 'PAYMENT');
      return contactPayments;
    } catch (e) {
      AppLogger.error('Get payments by contact error', tag: 'PAYMENT', error: e);
      return [];
    }
  }

  // Read: Get recent payment histories (last 30 days)
  static Future<List<PaymentHistoryModelBackend>> getRecentPayments() async {
    AppLogger.info('Fetching recent payments (last 30 days)', tag: 'PAYMENT');

    try {
      final allPayments = await getAllPaymentHistories();
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final recentPayments = allPayments.where((payment) {
        return payment.paymentDate.isAfter(thirtyDaysAgo);
      }).toList();

      AppLogger.info('Found ${recentPayments.length} recent payments', tag: 'PAYMENT');
      return recentPayments;
    } catch (e) {
      AppLogger.error('Get recent payments error', tag: 'PAYMENT', error: e);
      return [];
    }
  }

  // Update: Update existing payment history
  static Future<bool> updatePaymentHistory(PaymentHistoryModelBackend updatedPayment) async {
    AppLogger.dataOperation('UPDATE', 'Payment', id: updatedPayment.paymentId);

    try {
      final response = await _apiService.put(
        '${ApiConfig.paymentsEndpoint}/${updatedPayment.paymentId}',
        {
          'contact': updatedPayment.contact,
          'debt_amount': updatedPayment.debtAmount.toString(),
          'description': updatedPayment.description,
          'is_my_debt': updatedPayment.isMyDebt,
          'due_date': updatedPayment.dueDate.toIso8601String(),
        },
      );

      final success = response['success'] ?? false;
      AppLogger.dataOperation('UPDATE', 'Payment', id: updatedPayment.paymentId, success: success);
      return success;
    } catch (e) {
      AppLogger.error('Update payment history error', tag: 'PAYMENT', error: e);
      AppLogger.dataOperation('UPDATE', 'Payment', success: false);
      return false;
    }
  }

  // Delete: Remove payment history
  static Future<bool> deletePaymentHistory(String paymentId) async {
    AppLogger.dataOperation('DELETE', 'Payment', id: paymentId);

    try {
      final response = await _apiService.delete('${ApiConfig.paymentsEndpoint}/$paymentId');
      final success = response['success'] ?? false;
      AppLogger.dataOperation('DELETE', 'Payment', id: paymentId, success: success);
      return success;
    } catch (e) {
      AppLogger.error('Delete payment history error', tag: 'PAYMENT', error: e);
      AppLogger.dataOperation('DELETE', 'Payment', success: false);
      return false;
    }
  }

  // Calculate: Get total amount I have paid back
  static Future<double> getTotalAmountIPaid() async {
    AppLogger.info('Calculating total amount I paid', tag: 'PAYMENT');

    try {
      final myPayments = await getMyPayments();
      double total = 0.0;

      for (PaymentHistoryModelBackend payment in myPayments) {
        total += payment.displayAmount;
      }

      AppLogger.info('Total amount I paid: \$${total.toStringAsFixed(2)}', tag: 'PAYMENT');
      return total;
    } catch (e) {
      AppLogger.error('Get total amount I paid error', tag: 'PAYMENT', error: e);
      return 0.0;
    }
  }

  // Calculate: Get total amount they have paid me back
  static Future<double> getTotalAmountTheyPaid() async {
    AppLogger.info('Calculating total amount they paid me', tag: 'PAYMENT');

    try {
      final theirPayments = await getTheirPayments();
      double total = 0.0;

      for (PaymentHistoryModelBackend payment in theirPayments) {
        total += payment.displayAmount;
      }

      AppLogger.info('Total amount they paid me: \$${total.toStringAsFixed(2)}', tag: 'PAYMENT');
      return total;
    } catch (e) {
      AppLogger.error('Get total amount they paid error', tag: 'PAYMENT', error: e);
      return 0.0;
    }
  }

  // Clear: Delete all payment histories
  static Future<bool> clearAllPaymentHistories() async {
    AppLogger.warning('Clearing all payment histories', tag: 'PAYMENT');

    try {
      final response = await _apiService.delete(ApiConfig.paymentsEndpoint);
      final success = response['success'] ?? false;
      AppLogger.dataOperation('CLEAR_ALL', 'Payments', success: success);
      return success;
    } catch (e) {
      AppLogger.error('Clear all payment histories error', tag: 'PAYMENT', error: e);
      AppLogger.dataOperation('CLEAR_ALL', 'Payments', success: false);
      return false;
    }
  }

  @override
  String toString() {
    return 'PaymentHistoryModelBackend{paymentId: $paymentId, contact: $contact, debtAmount: $debtAmount, description: $description, isMyDebt: $isMyDebt, dueDate: $dueDate}';
  }
}