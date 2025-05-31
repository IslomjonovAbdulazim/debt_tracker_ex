import 'package:debt_tracker_ex/config/app_logger.dart';

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
      'contact': contactId,  // Changed to snake_case
      'contact_name': contactName,  // Changed to snake_case
      'debt_amount': debtAmount,  // Changed to snake_case
      'description': debtDescription,  // Changed to snake_case
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
      contactId: json['contact']?.toString() ?? '',
      contactName: json['contact_name'] ?? '',
      debtAmount: (json['debt_amount'] ?? 0).toDouble(),
      debtDescription: json['description'] ?? '',
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
          'contact': debtRecord.contactId,
          'debt_amount': debtRecord.debtAmount,
          'description': debtRecord.debtDescription,
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
          'contact': updatedRecord.contactId,
          'debt_amount': updatedRecord.debtAmount,
          'description': updatedRecord.debtDescription,
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

  // Calculate: Get total amount I owe - Updated to handle new API response
  static Future<double> getTotalAmountIOwe() async {
    try {
      final response = await _apiService.get(ApiConfig.debtsSummaryEndpoint);

      if (response['success'] && response['data'] != null) {
        final List<dynamic> summaryData = response['data'] ?? [];
        double total = 0.0;

        for (final item in summaryData) {
          if (item is Map<String, dynamic>) {
            final bool isMyDebt = item['is_my_debt'] == true;
            final bool isPaidBack = item['is_paid_back'] == true;

            if (isMyDebt && !isPaidBack) {
              final double amount = double.tryParse(item['debt_amount']?.toString() ?? '0') ?? 0.0;
              total += amount.abs(); // Use absolute value
            }
          }
        }

        return total;
      }

      return 0.0;
    } catch (e) {
      print('Get total amount I owe error: $e');
      return 0.0;
    }
  }

  // Calculate: Get total amount they owe me - Updated to handle new API response
  static Future<double> getTotalAmountTheyOweMe() async {
    try {
      final response = await _apiService.get(ApiConfig.debtsSummaryEndpoint);

      if (response['success'] && response['data'] != null) {
        final List<dynamic> summaryData = response['data'] ?? [];
        double total = 0.0;

        for (final item in summaryData) {
          if (item is Map<String, dynamic>) {
            final bool isMyDebt = item['is_my_debt'] == true;
            final bool isPaidBack = item['is_paid_back'] == true;

            if (!isMyDebt && !isPaidBack) {
              final double amount = double.tryParse(item['debt_amount']?.toString() ?? '0') ?? 0.0;
              total += amount.abs(); // Use absolute value
            }
          }
        }

        return total;
      }

      return 0.0;
    } catch (e) {
      print('Get total amount they owe me error: $e');
      return 0.0;
    }
  }

  // Get summary data directly from API - New method to handle the summary response
  static Future<Map<String, dynamic>> getDebtsSummary() async {
    try {
      final response = await _apiService.get(ApiConfig.debtsSummaryEndpoint);

      if (response['success'] && response['data'] != null) {
        final List<dynamic> summaryData = response['data'] ?? [];
        AppLogger.info(summaryData.toString());


        double totalIOwe = 0.0;
        double totalTheyOwe = 0.0;
        int activeDebts = 0;
        int overdueCount = 0;

        // for (final item in summaryData) {
        //   if (item is Map<String, dynamic>) {
        //     final double amount = double.tryParse(item['debt_amount']?.toString() ?? '0') ?? 0.0;
        //     final bool isMyDebt = item['is_my_debt'] == true;
        //     final bool isPaidBack = item['is_paid_back'] == true;
        //     final bool isOverdue = item['is_overdue'] == true;
        //
        //     if (!isPaidBack) {
        //       activeDebts++;
        //
        //       if (isMyDebt) {
        //         totalIOwe += amount.abs();
        //       } else {
        //         totalTheyOwe += amount.abs();
        //       }
        //
        //       if (isOverdue) {
        //         overdueCount++;
        //       }
        //     }
        //   }
        // }

        return {
          'success': true,
          'total_i_owe': response["total_i_owe"],
          'total_they_owe': response["total_they_owe"],
          'active_debts_count': response["active_debts_count"],
          'overdue_debts_count': response["overdue_debts_count"],
        };
      }

      return {
        'success': false,
        'totalIOwe': 0.0,
        'totalTheyOwe': 0.0,
        'activeDebts': 0,
        'overdueCount': 0,
      };
    } catch (e) {
      print('Get debts summary error: $e');
      return {
        'success': false,
        'totalIOwe': 0.0,
        'totalTheyOwe': 0.0,
        'activeDebts': 0,
        'overdueCount': 0,
      };
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