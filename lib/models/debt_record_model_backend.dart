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

  // Convert to JSON for API requests - Updated to match backend API
  Map<String, dynamic> toJson() {
    return {
      'contact_id': int.tryParse(contactId) ?? contactId, // Backend expects integer
      'amount': debtAmount, // Backend expects 'amount'
      'description': debtDescription,
      'is_my_debt': isMyDebt,
      // Note: due_date and is_paid not mentioned in backend create docs
    };
  }

  // Create from JSON response - Updated based on backend API structure
  factory DebtRecordModelBackend.fromJson(Map<String, dynamic> json) {
    return DebtRecordModelBackend(
      recordId: json['id']?.toString() ?? '',
      contactId: json['contact_id']?.toString() ?? '',
      contactName: json['contact_name'] ?? 'Unknown Contact',
      debtAmount: (json['amount'] ?? 0).toDouble(), // Backend returns 'amount'
      debtDescription: json['description'] ?? '',
      createdDate: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()
      ),
      dueDate: DateTime.parse(
          json['due_date'] ?? json['created_at'] ?? DateTime.now().toIso8601String()
      ),
      isMyDebt: json['is_my_debt'] ?? false,
      isPaidBack: json['is_paid'] ?? false,
    );
  }

  // Check if debt is overdue
  bool get isOverdue {
    return !isPaidBack && DateTime.now().isAfter(dueDate);
  }

  // =============================================
  // API METHODS - Updated to match backend API
  // =============================================

  // Create: Save new debt record - Updated to use backend API
  static Future<bool> createDebtRecord(DebtRecordModelBackend debtRecord) async {
    try {
      AppLogger.apiRequest('POST', ApiConfig.createDebtEndpoint, data: debtRecord.toJson());

      final response = await _apiService.post(
        ApiConfig.createDebtEndpoint,
        debtRecord.toJson(),
      );

      final success = response['success'] ?? false;
      AppLogger.dataOperation('CREATE', 'Debt', success: success);
      return success;
    } catch (e) {
      AppLogger.error('Create debt record error', tag: 'DEBT', error: e);
      return false;
    }
  }

  // Read: Get all debt records - Updated to use backend API
  static Future<List<DebtRecordModelBackend>> getAllDebtRecords() async {
    try {
      AppLogger.info('Fetching all debt records', tag: 'DEBT');

      final response = await _apiService.get(ApiConfig.debtsEndpoint);

      if (response['success']) {
        // Backend wraps debts in data.debts array
        List<dynamic> debtsData;

        if (response['data'] != null && response['data']['debts'] is List) {
          debtsData = response['data']['debts'];
        } else if (response['data'] is List) {
          // Fallback: direct array
          debtsData = response['data'];
        } else {
          // No debts found
          debtsData = [];
        }

        final debts = debtsData
            .map((json) => DebtRecordModelBackend.fromJson(json))
            .toList();

        AppLogger.info('Retrieved ${debts.length} debt records', tag: 'DEBT');
        return debts;
      }

      AppLogger.warning('Failed to get debts: ${response['message']}', tag: 'DEBT');
      return [];
    } catch (e) {
      AppLogger.error('Get all debt records error', tag: 'DEBT', error: e);
      return [];
    }
  }

  // Read: Get debts by contact ID - Using backend API with filters
  static Future<List<DebtRecordModelBackend>> getDebtsByContactId(String contactId) async {
    try {
      AppLogger.info('Fetching debts for contact: $contactId', tag: 'DEBT');

      // Use query parameter to filter by contact_id
      final queryString = ApiConfig.buildQueryString({'contact_id': contactId});
      final endpoint = '${ApiConfig.debtsEndpoint}$queryString';

      final response = await _apiService.get(endpoint);

      if (response['success']) {
        // Backend wraps debts in data.debts array
        List<dynamic> debtsData;

        if (response['data'] != null && response['data']['debts'] is List) {
          debtsData = response['data']['debts'];
        } else if (response['data'] is List) {
          // Fallback: direct array
          debtsData = response['data'];
        } else {
          // No debts found
          debtsData = [];
        }

        final debts = debtsData
            .map((json) => DebtRecordModelBackend.fromJson(json))
            .toList();

        AppLogger.info('Retrieved ${debts.length} debts for contact $contactId', tag: 'DEBT');
        return debts;
      }

      AppLogger.warning('Failed to get debts for contact $contactId: ${response['message']}', tag: 'DEBT');
      return [];
    } catch (e) {
      AppLogger.error('Get debts by contact ID error', tag: 'DEBT', error: e);
      return [];
    }
  }

  // Get home overview data - Using backend API /debts/overview
  static Future<Map<String, dynamic>> getHomeOverview() async {
    try {
      AppLogger.info('Fetching home overview', tag: 'DEBT');

      final response = await _apiService.get(ApiConfig.homeOverviewEndpoint);

      if (response['success'] && response['data'] != null) {
        final data = response['data'];
        final summary = data['summary'] ?? {};

        final overview = {
          'success': true,
          'total_i_owe': (summary['i_owe'] ?? 0).toDouble(),
          'total_they_owe': (summary['they_owe_me'] ?? 0).toDouble(),
          'active_debts_count': summary['active_debts_count'] ?? 0,
          'overdue_debts_count': 0, // Calculate from active debts if needed
        };

        AppLogger.info('Home overview retrieved successfully', tag: 'DEBT');
        return overview;
      }

      AppLogger.warning('Failed to get home overview: ${response['message']}', tag: 'DEBT');
      return {
        'success': false,
        'total_i_owe': 0.0,
        'total_they_owe': 0.0,
        'active_debts_count': 0,
        'overdue_debts_count': 0,
      };
    } catch (e) {
      AppLogger.error('Get home overview error', tag: 'DEBT', error: e);
      return {
        'success': false,
        'total_i_owe': 0.0,
        'total_they_owe': 0.0,
        'active_debts_count': 0,
        'overdue_debts_count': 0,
      };
    }
  }

  // =============================================
  // CLIENT-SIDE FILTERING METHODS - Using backend API with filters
  // =============================================

  // Filter: Get debts I owe - Using backend API with filters
  static Future<List<DebtRecordModelBackend>> getMyDebts() async {
    try {
      AppLogger.info('Fetching debts I owe', tag: 'DEBT');

      // Use query parameters to filter
      final queryString = ApiConfig.buildQueryString({
        'is_my_debt': true,
        'is_paid': false,
      });
      final endpoint = '${ApiConfig.debtsEndpoint}$queryString';

      final response = await _apiService.get(endpoint);

      if (response['success']) {
        // Backend wraps debts in data.debts array
        List<dynamic> debtsData;

        if (response['data'] != null && response['data']['debts'] is List) {
          debtsData = response['data']['debts'];
        } else if (response['data'] is List) {
          debtsData = response['data'];
        } else {
          debtsData = [];
        }

        final debts = debtsData
            .map((json) => DebtRecordModelBackend.fromJson(json))
            .toList();

        AppLogger.info('Retrieved ${debts.length} debts I owe', tag: 'DEBT');
        return debts;
      }

      AppLogger.warning('Failed to get my debts: ${response['message']}', tag: 'DEBT');
      return [];
    } catch (e) {
      AppLogger.error('Get my debts error', tag: 'DEBT', error: e);
      return [];
    }
  }

  // Filter: Get debts they owe me - Using backend API with filters
  static Future<List<DebtRecordModelBackend>> getTheirDebts() async {
    try {
      AppLogger.info('Fetching debts they owe me', tag: 'DEBT');

      // Use query parameters to filter
      final queryString = ApiConfig.buildQueryString({
        'is_my_debt': false,
        'is_paid': false,
      });
      final endpoint = '${ApiConfig.debtsEndpoint}$queryString';

      final response = await _apiService.get(endpoint);

      if (response['success']) {
        // Backend wraps debts in data.debts array
        List<dynamic> debtsData;

        if (response['data'] != null && response['data']['debts'] is List) {
          debtsData = response['data']['debts'];
        } else if (response['data'] is List) {
          debtsData = response['data'];
        } else {
          debtsData = [];
        }

        final debts = debtsData
            .map((json) => DebtRecordModelBackend.fromJson(json))
            .toList();

        AppLogger.info('Retrieved ${debts.length} debts they owe me', tag: 'DEBT');
        return debts;
      }

      AppLogger.warning('Failed to get their debts: ${response['message']}', tag: 'DEBT');
      return [];
    } catch (e) {
      AppLogger.error('Get their debts error', tag: 'DEBT', error: e);
      return [];
    }
  }

  // Filter: Get overdue debts - Client-side filtering since backend doesn't have overdue filter
  static Future<List<DebtRecordModelBackend>> getOverdueDebts() async {
    try {
      AppLogger.info('Fetching overdue debts', tag: 'DEBT');

      // Get all unpaid debts first
      final queryString = ApiConfig.buildQueryString({'is_paid': false});
      final endpoint = '${ApiConfig.debtsEndpoint}$queryString';

      final response = await _apiService.get(endpoint);

      if (response['success']) {
        List<dynamic> debtsData;

        if (response['data'] != null && response['data']['debts'] is List) {
          debtsData = response['data']['debts'];
        } else if (response['data'] is List) {
          debtsData = response['data'];
        } else {
          debtsData = [];
        }

        final allDebts = debtsData
            .map((json) => DebtRecordModelBackend.fromJson(json))
            .toList();

        // Filter overdue debts client-side
        final overdueDebts = allDebts.where((debt) => debt.isOverdue).toList();

        AppLogger.info('Retrieved ${overdueDebts.length} overdue debts from ${allDebts.length} total', tag: 'DEBT');
        return overdueDebts;
      }

      AppLogger.warning('Failed to get overdue debts: ${response['message']}', tag: 'DEBT');
      return [];
    } catch (e) {
      AppLogger.error('Get overdue debts error', tag: 'DEBT', error: e);
      return [];
    }
  }

  // =============================================
  // CLIENT-SIDE CALCULATION METHODS - Fallback if API fails
  // =============================================

  // Calculate: Get total amount I owe
  static Future<double> getTotalAmountIOwe() async {
    try {
      final myDebts = await getMyDebts();
      final total = myDebts.fold(0.0, (sum, debt) => sum + debt.debtAmount.abs());

      AppLogger.info('Calculated total I owe: \$${total.toStringAsFixed(2)}', tag: 'DEBT');
      return total;
    } catch (e) {
      AppLogger.error('Calculate total I owe error', tag: 'DEBT', error: e);
      return 0.0;
    }
  }

  // Calculate: Get total amount they owe me
  static Future<double> getTotalAmountTheyOweMe() async {
    try {
      final theirDebts = await getTheirDebts();
      final total = theirDebts.fold(0.0, (sum, debt) => sum + debt.debtAmount.abs());

      AppLogger.info('Calculated total they owe me: \$${total.toStringAsFixed(2)}', tag: 'DEBT');
      return total;
    } catch (e) {
      AppLogger.error('Calculate total they owe me error', tag: 'DEBT', error: e);
      return 0.0;
    }
  }

  // Get summary data - Uses backend API primarily, with fallback to client-side
  static Future<Map<String, dynamic>> getDebtsSummary() async {
    try {
      // Try to get data from backend overview first
      final overview = await getHomeOverview();

      if (overview['success'] == true) {
        AppLogger.info('Using backend overview data', tag: 'DEBT');
        return overview;
      }

      // Fallback to client-side calculations
      AppLogger.info('Backend overview failed, falling back to client-side calculations', tag: 'DEBT');

      final results = await Future.wait([
        getTotalAmountIOwe(),
        getTotalAmountTheyOweMe(),
        getAllDebtRecords(),
        getOverdueDebts(),
      ]);

      final totalIOwe = results[0] as double;
      final totalTheyOwe = results[1] as double;
      final allDebts = results[2] as List<DebtRecordModelBackend>;
      final overdueDebts = results[3] as List<DebtRecordModelBackend>;

      final summary = {
        'success': true,
        'total_i_owe': totalIOwe,
        'total_they_owe': totalTheyOwe,
        'active_debts_count': allDebts.where((debt) => !debt.isPaidBack).length,
        'overdue_debts_count': overdueDebts.length,
      };

      AppLogger.info('Client-side summary calculated successfully', tag: 'DEBT');
      return summary;
    } catch (e) {
      AppLogger.error('Get debts summary error', tag: 'DEBT', error: e);
      return {
        'success': false,
        'total_i_owe': 0.0,
        'total_they_owe': 0.0,
        'active_debts_count': 0,
        'overdue_debts_count': 0,
      };
    }
  }

  // =============================================
  // NEW METHODS - Based on backend API
  // =============================================

  // Update debt record - Added based on backend docs
  static Future<Map<String, dynamic>> updateDebtRecord(String id, DebtRecordModelBackend debt) async {
    try {
      AppLogger.dataOperation('UPDATE', 'Debt', id: id);

      final response = await _apiService.put(
        ApiConfig.updateDebtEndpoint(id),
        debt.toJson(),
      );

      if (response['success']) {
        AppLogger.dataOperation('UPDATE', 'Debt', id: id, success: true);
      } else {
        AppLogger.dataOperation('UPDATE', 'Debt', id: id, success: false);
      }

      return response;
    } catch (e) {
      AppLogger.error('Update debt record error', tag: 'DEBT', error: e);
      return {
        'success': false,
        'message': 'Failed to update debt: $e',
      };
    }
  }

  // Mark debt as paid - Added based on backend docs
  static Future<Map<String, dynamic>> markDebtAsPaid(String id) async {
    try {
      AppLogger.dataOperation('UPDATE', 'DebtPayment', id: id);

      final response = await _apiService.put(
        ApiConfig.markDebtPaidEndpoint(id),
        {}, // Backend expects PATCH but we'll use PUT with empty body
      );

      if (response['success']) {
        AppLogger.dataOperation('UPDATE', 'DebtPayment', id: id, success: true);
      } else {
        AppLogger.dataOperation('UPDATE', 'DebtPayment', id: id, success: false);
      }

      return response;
    } catch (e) {
      AppLogger.error('Mark debt as paid error', tag: 'DEBT', error: e);
      return {
        'success': false,
        'message': 'Failed to mark debt as paid: $e',
      };
    }
  }

  // Delete debt record - Added based on backend docs
  static Future<Map<String, dynamic>> deleteDebtRecord(String id) async {
    try {
      AppLogger.dataOperation('DELETE', 'Debt', id: id);

      final response = await _apiService.delete(ApiConfig.deleteDebtEndpoint(id));

      if (response['success']) {
        AppLogger.dataOperation('DELETE', 'Debt', id: id, success: true);
      } else {
        AppLogger.dataOperation('DELETE', 'Debt', id: id, success: false);
      }

      return response;
    } catch (e) {
      AppLogger.error('Delete debt record error', tag: 'DEBT', error: e);
      return {
        'success': false,
        'message': 'Failed to delete debt: $e',
      };
    }
  }

  // Get specific debt by ID - Added based on backend docs
  static Future<DebtRecordModelBackend?> getDebtRecordById(String id) async {
    try {
      AppLogger.info('Fetching debt by ID: $id', tag: 'DEBT');

      final response = await _apiService.get(ApiConfig.getDebtEndpoint(id));

      if (response['success'] && response['data'] != null) {
        final debt = DebtRecordModelBackend.fromJson(response['data']);
        AppLogger.info('Retrieved debt $id', tag: 'DEBT');
        return debt;
      }

      AppLogger.warning('Debt $id not found', tag: 'DEBT');
      return null;
    } catch (e) {
      AppLogger.error('Get debt by ID error', tag: 'DEBT', error: e);
      return null;
    }
  }

  @override
  String toString() {
    return 'DebtRecordModelBackend{recordId: $recordId, contactId: $contactId, contactName: $contactName, debtAmount: $debtAmount, isMyDebt: $isMyDebt, isPaidBack: $isPaidBack}';
  }
}