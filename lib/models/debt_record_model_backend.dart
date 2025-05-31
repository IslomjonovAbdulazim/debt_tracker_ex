import '../services/api_service.dart';
import '../config/api_config.dart';

class DebtRecordModelBackend {
  static final ApiService _apiService = ApiService();

  final String recordId;
  final String contactId;
  final String contactName;
  final double debtAmount;
  final String debtDescription;
  final DateTime createdDate;
  final DateTime dueDate;
  final bool isMyDebt; // true if I owe them, false if they owe me
  final bool isPaidBack;

  DebtRecordModelBackend({
    required this.recordId,
    required this.contactId,
    required this.contactName,
    required this.debtAmount,
    required this.debtDescription,
    required this.createdDate,
    required this.dueDate,
    required this.isMyDebt,
    this.isPaidBack = false,
  });

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': recordId,
      'contact_id': contactId,  // Changed to snake_case
      'contact_name': contactName,  // Changed to snake_case
      'debt_amount': debtAmount,  // Changed to snake_case
      'debt_description': debtDescription,  // Changed to snake_case
      'created_date': createdDate.toIso8601String(),  // Changed to snake_case
      'due_date': dueDate.toIso8601String(),  // Changed to snake_case
      'is_my_debt': isMyDebt,  // Changed to snake_case
      'is_paid_back': isPaidBack,  // Changed to snake_case
    };
  }

  // Create from JSON response
  factory DebtRecordModelBackend.fromJson(Map<String, dynamic> json) {
    return DebtRecordModelBackend(
      recordId: json['id']?.toString() ?? '',  // API uses 'id'
      contactId: json['contact_id']?.toString() ?? '',
      contactName: json['contact_name'] ?? '',
      debtAmount: (json['debt_amount'] ?? 0).toDouble(),
      debtDescription: json['debt_description'] ?? '',
      createdDate: DateTime.parse(
          json['created_date'] ?? DateTime.now().toIso8601String()
      ),
      dueDate: DateTime.parse(
          json['due_date'] ?? DateTime.now().toIso8601String()
      ),
      isMyDebt: json['is_my_debt'] ?? false,
      isPaidBack: json['is_paid_back'] ?? false,
    );
  }

  // Check if debt is overdue
  bool get isOverdue {
    return !isPaidBack && DateTime.now().isAfter(dueDate);
  }

  // Create: Save new debt record
  static Future<bool> createDebtRecord(DebtRecordModelBackend debtRecord) async {
    try {
      final response = await _apiService.post(
        ApiConfig.createDebtEndpoint,
        {
          'contact_id': debtRecord.contactId,
          'debt_amount': debtRecord.debtAmount,
          'debt_description': debtRecord.debtDescription,
          'due_date': debtRecord.dueDate.toIso8601String().split('T')[0], // Only date part
          'is_my_debt': debtRecord.isMyDebt,
        },
      );

      return response['success'] ?? false;
    } catch (e) {
      print('Create debt record error: $e');
      return false;
    }
  }

  // Read: Get all debt records
  static Future<List<DebtRecordModelBackend>> getAllDebtRecords() async {
    try {
      final response = await _apiService.get(ApiConfig.debtsEndpoint);

      if (response['success']) {
        final List<dynamic> debtsData = response['data']?['debts'] ?? [];
        return debtsData
            .map((json) => DebtRecordModelBackend.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print('Get all debt records error: $e');
      return [];
    }
  }

  // Read: Get debt record by ID
  static Future<DebtRecordModelBackend?> getDebtRecordById(String recordId) async {
    try {
      final response = await _apiService.get('${ApiConfig.debtsEndpoint}/$recordId');

      if (response['success']) {
        return DebtRecordModelBackend.fromJson(response['data']['debt']);
      }

      return null;
    } catch (e) {
      print('Get debt record by ID error: $e');
      return null;
    }
  }

  // Read: Get debts I owe
  static Future<List<DebtRecordModelBackend>> getMyDebts() async {
    try {
      final response = await _apiService.get(ApiConfig.myDebtsEndpoint);

      if (response['success']) {
        final List<dynamic> debtsData = response['data']?['debts'] ?? [];
        return debtsData
            .map((json) => DebtRecordModelBackend.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print('Get my debts error: $e');
      return [];
    }
  }

  // Read: Get debts they owe me
  static Future<List<DebtRecordModelBackend>> getTheirDebts() async {
    try {
      final response = await _apiService.get(ApiConfig.theirDebtsEndpoint);

      if (response['success']) {
        final List<dynamic> debtsData = response['data']?['debts'] ?? [];
        return debtsData
            .map((json) => DebtRecordModelBackend.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print('Get their debts error: $e');
      return [];
    }
  }

  // Read: Get overdue debts
  static Future<List<DebtRecordModelBackend>> getOverdueDebts() async {
    try {
      final response = await _apiService.get(ApiConfig.overdueDebtsEndpoint);

      if (response['success']) {
        final List<dynamic> debtsData = response['data']?['debts'] ?? [];
        return debtsData
            .map((json) => DebtRecordModelBackend.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print('Get overdue debts error: $e');
      return [];
    }
  }

  // Read: Get debts by contact ID
  static Future<List<DebtRecordModelBackend>> getDebtsByContactId(String contactId) async {
    try {
      final response = await _apiService.get('${ApiConfig.debtsByContactEndpoint}/$contactId');

      if (response['success']) {
        final List<dynamic> debtsData = response['data']?['debts'] ?? [];
        return debtsData
            .map((json) => DebtRecordModelBackend.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print('Get debts by contact ID error: $e');
      return [];
    }
  }

  // Update: Update existing debt record
  static Future<bool> updateDebtRecord(DebtRecordModelBackend updatedRecord) async {
    try {
      final response = await _apiService.put(
        '${ApiConfig.updateDebtEndpoint}/${updatedRecord.recordId}',
        {
          'contact_id': updatedRecord.contactId,
          'debt_amount': updatedRecord.debtAmount,
          'debt_description': updatedRecord.debtDescription,
          'due_date': updatedRecord.dueDate.toIso8601String().split('T')[0],
          'is_my_debt': updatedRecord.isMyDebt,
          'is_paid_back': updatedRecord.isPaidBack,
        },
      );

      return response['success'] ?? false;
    } catch (e) {
      print('Update debt record error: $e');
      return false;
    }
  }

  // Update: Mark debt as paid back
  static Future<bool> markAsPaidBack(String recordId) async {
    try {
      final response = await _apiService.put(
        '${ApiConfig.markDebtPaidEndpoint}/$recordId/mark-paid',
        {
          'payment_description': 'Marked as paid via app',
        },
      );

      return response['success'] ?? false;
    } catch (e) {
      print('Mark debt as paid error: $e');
      return false;
    }
  }

  // Delete: Remove debt record
  static Future<bool> deleteDebtRecord(String recordId) async {
    try {
      final response = await _apiService.delete('${ApiConfig.deleteDebtEndpoint}/$recordId');
      return response['success'] ?? false;
    } catch (e) {
      print('Delete debt record error: $e');
      return false;
    }
  }

  // Calculate: Get total amount I owe
  static Future<double> getTotalAmountIOwe() async {
    try {
      final response = await _apiService.get(ApiConfig.debtsSummaryEndpoint);

      if (response['success']) {
        return (response['data']?['summary']?['total_i_owe'] ?? 0).toDouble();
      }

      return 0.0;
    } catch (e) {
      print('Get total amount I owe error: $e');
      return 0.0;
    }
  }

  // Calculate: Get total amount they owe me
  static Future<double> getTotalAmountTheyOweMe() async {
    try {
      final response = await _apiService.get(ApiConfig.debtsSummaryEndpoint);

      if (response['success']) {
        return (response['data']?['summary']?['total_they_owe'] ?? 0).toDouble();
      }

      return 0.0;
    } catch (e) {
      print('Get total amount they owe me error: $e');
      return 0.0;
    }
  }

  // Clear: Delete all debt records
  static Future<bool> clearAllDebtRecords() async {
    try {
      final response = await _apiService.delete(ApiConfig.debtsEndpoint);
      return response['success'] ?? false;
    } catch (e) {
      print('Clear all debt records error: $e');
      return false;
    }
  }
}