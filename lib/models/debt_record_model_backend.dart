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

  // Convert to JSON for API requests - Updated to match API docs
  Map<String, dynamic> toJson() {
    return {
      'contact_id': contactId,
      'debt_amount': debtAmount,
      'description': debtDescription,
      'due_date': dueDate.toIso8601String().split('T')[0], // Only date part
      'is_paid': isPaidBack,
      'is_my_debt': isMyDebt,
    };
  }

  // Create from JSON response - Updated based on API docs structure
  factory DebtRecordModelBackend.fromJson(Map<String, dynamic> json) {
    return DebtRecordModelBackend(
      recordId: json['id']?.toString() ?? '',
      contactId: json['contact_id']?.toString() ?? '',
      contactName: json['contact_name'] ?? 'Unknown Contact',
      debtAmount: (json['debt_amount'] ?? 0).toDouble(),
      debtDescription: json['description'] ?? '',
      createdDate: DateTime.parse(
          json['created_date'] ?? DateTime.now().toIso8601String()
      ),
      dueDate: DateTime.parse(
          json['due_date'] ?? DateTime.now().toIso8601String()
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
  // API METHODS - Updated to match actual API
  // =============================================

  // Create: Save new debt record - Updated to use /contact-debt
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

  // Read: Get all debt records - Updated to use /debts
  static Future<List<DebtRecordModelBackend>> getAllDebtRecords() async {
    try {
      AppLogger.info('Fetching all debt records', tag: 'DEBT');

      final response = await _apiService.get(ApiConfig.debtsEndpoint);

      if (response['success']) {
        final List<dynamic> debtsData = response['data'] ?? [];

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

  // Read: Get debts by contact ID - Updated to use /contact-debts/{contact_id}
  static Future<List<DebtRecordModelBackend>> getDebtsByContactId(String contactId) async {
    try {
      AppLogger.info('Fetching debts for contact: $contactId', tag: 'DEBT');

      final response = await _apiService.get('${ApiConfig.contactDebtsEndpoint}/$contactId');

      if (response['success']) {
        final List<dynamic> debtsData = response['data'] ?? [];

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

  // NEW: Get home overview data - Using /home/overview
  static Future<Map<String, dynamic>> getHomeOverview() async {
    try {
      AppLogger.info('Fetching home overview', tag: 'DEBT');

      final response = await _apiService.get(ApiConfig.homeOverviewEndpoint);

      if (response['success']) {
        final data = response['data'] ?? {};

        final overview = {
          'success': true,
          'total_i_owe': (data['i_owe'] ?? 0).toDouble(),
          'total_they_owe': (data['they_owe'] ?? 0).toDouble(),
          'active_debts_count': data['active_debts'] ?? 0,
          'overdue_debts_count': data['overdue'] ?? 0,
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
  // CLIENT-SIDE FILTERING METHODS
  // =============================================

  // Filter: Get debts I owe (client-side filtering)
  static Future<List<DebtRecordModelBackend>> getMyDebts() async {
    try {
      final allDebts = await getAllDebtRecords();
      final myDebts = allDebts.where((debt) => debt.isMyDebt && !debt.isPaidBack).toList();

      AppLogger.info('Filtered ${myDebts.length} debts I owe from ${allDebts.length} total', tag: 'DEBT');
      return myDebts;
    } catch (e) {
      AppLogger.error('Get my debts error', tag: 'DEBT', error: e);
      return [];
    }
  }

  // Filter: Get debts they owe me (client-side filtering)
  static Future<List<DebtRecordModelBackend>> getTheirDebts() async {
    try {
      final allDebts = await getAllDebtRecords();
      final theirDebts = allDebts.where((debt) => !debt.isMyDebt && !debt.isPaidBack).toList();

      AppLogger.info('Filtered ${theirDebts.length} debts they owe from ${allDebts.length} total', tag: 'DEBT');
      return theirDebts;
    } catch (e) {
      AppLogger.error('Get their debts error', tag: 'DEBT', error: e);
      return [];
    }
  }

  // Filter: Get overdue debts (client-side filtering)
  static Future<List<DebtRecordModelBackend>> getOverdueDebts() async {
    try {
      final allDebts = await getAllDebtRecords();
      final overdueDebts = allDebts.where((debt) => debt.isOverdue).toList();

      AppLogger.info('Filtered ${overdueDebts.length} overdue debts from ${allDebts.length} total', tag: 'DEBT');
      return overdueDebts;
    } catch (e) {
      AppLogger.error('Get overdue debts error', tag: 'DEBT', error: e);
      return [];
    }
  }

  // =============================================
  // CLIENT-SIDE CALCULATION METHODS
  // =============================================

  // Calculate: Get total amount I owe (client-side calculation)
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

  // Calculate: Get total amount they owe me (client-side calculation)
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

  // Get summary data - Uses /home/overview API primarily, with fallback to client-side
  static Future<Map<String, dynamic>> getDebtsSummary() async {
    try {
      // Try to get data from /home/overview first
      final overview = await getHomeOverview();

      if (overview['success'] == true) {
        AppLogger.info('Using API overview data', tag: 'DEBT');
        return overview;
      }

      // Fallback to client-side calculations
      AppLogger.info('API overview failed, falling back to client-side calculations', tag: 'DEBT');

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
  // REMOVED/DEPRECATED METHODS
  // =============================================

  // NOTE: The following methods have been removed as they don't exist in the API:
  // - getDebtRecordById() - API doesn't support individual debt lookup
  // - updateDebtRecord() - No update endpoint in API docs
  // - markAsPaidBack() - No mark-paid endpoint in API docs
  // - deleteDebtRecord() - No delete endpoint in API docs
  // - clearAllDebtRecords() - No clear endpoint in API docs

  // If these features are needed, they would need to be implemented
  // differently or the API would need to be extended

  @override
  String toString() {
    return 'DebtRecordModelBackend{recordId: $recordId, contactId: $contactId, contactName: $contactName, debtAmount: $debtAmount, isMyDebt: $isMyDebt, isPaidBack: $isPaidBack}';
  }
}