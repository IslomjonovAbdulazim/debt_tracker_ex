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
      'recordId': recordId,
      'contactId': contactId,
      'contactName': contactName,
      'debtAmount': debtAmount,
      'debtDescription': debtDescription,
      'createdDate': createdDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'isMyDebt': isMyDebt,
      'isPaidBack': isPaidBack,
    };
  }

  // Create from JSON response
  factory DebtRecordModelBackend.fromJson(Map<String, dynamic> json) {
    return DebtRecordModelBackend(
      recordId: json['recordId'] ?? json['record_id'] ?? json['id'] ?? '',
      contactId: json['contactId'] ?? json['contact_id'] ?? '',
      contactName: json['contactName'] ?? json['contact_name'] ?? '',
      debtAmount: (json['debtAmount'] ?? json['debt_amount'] ?? 0).toDouble(),
      debtDescription: json['debtDescription'] ?? json['debt_description'] ?? '',
      createdDate: DateTime.parse(
          json['createdDate'] ?? json['created_date'] ?? json['created_at'] ?? DateTime.now().toIso8601String()
      ),
      dueDate: DateTime.parse(
          json['dueDate'] ?? json['due_date'] ?? DateTime.now().toIso8601String()
      ),
      isMyDebt: json['isMyDebt'] ?? json['is_my_debt'] ?? false,
      isPaidBack: json['isPaidBack'] ?? json['is_paid_back'] ?? false,
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
          'contactId': debtRecord.contactId,
          'contactName': debtRecord.contactName,
          'debtAmount': debtRecord.debtAmount,
          'debtDescription': debtRecord.debtDescription,
          'dueDate': debtRecord.dueDate.toIso8601String(),
          'isMyDebt': debtRecord.isMyDebt,
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
        final List<dynamic> debtsData = response['debts'] ?? response['data'] ?? [];
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
        return DebtRecordModelBackend.fromJson(response['debt'] ?? response['data']);
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
        final List<dynamic> debtsData = response['debts'] ?? response['data'] ?? [];
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
        final List<dynamic> debtsData = response['debts'] ?? response['data'] ?? [];
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
        final List<dynamic> debtsData = response['debts'] ?? response['data'] ?? [];
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
        final List<dynamic> debtsData = response['debts'] ?? response['data'] ?? [];
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
          'contactId': updatedRecord.contactId,
          'contactName': updatedRecord.contactName,
          'debtAmount': updatedRecord.debtAmount,
          'debtDescription': updatedRecord.debtDescription,
          'dueDate': updatedRecord.dueDate.toIso8601String(),
          'isMyDebt': updatedRecord.isMyDebt,
          'isPaidBack': updatedRecord.isPaidBack,
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
        {},
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
      final response = await _apiService.get('${ApiConfig.debtsSummaryEndpoint}?type=my_debts');

      if (response['success']) {
        return (response['totalAmount'] ?? response['total'] ?? 0).toDouble();
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
      final response = await _apiService.get('${ApiConfig.debtsSummaryEndpoint}?type=their_debts');

      if (response['success']) {
        return (response['totalAmount'] ?? response['total'] ?? 0).toDouble();
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