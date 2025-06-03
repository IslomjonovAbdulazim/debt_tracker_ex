// lib/models/debt_record_model_backend.dart
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../config/app_logger.dart';

class DebtRecordModelBackend {
  static final ApiService _apiService = ApiService();

  final String recordId;
  final String contactId;
  final String contactName;
  final String? contactPhone;
  final double debtAmount;
  final String debtDescription;
  final DateTime createdDate;
  final bool isMyDebt;
  final bool isPaidBack;

  DebtRecordModelBackend({
    required this.recordId,
    required this.contactId,
    required this.contactName,
    this.contactPhone,
    required this.debtAmount,
    required this.debtDescription,
    required this.createdDate,
    required this.isMyDebt,
    this.isPaidBack = false,
  });

  // =============================================
  // CALCULATED PROPERTIES
  // =============================================

  DateTime get dueDate {
    return createdDate.add(const Duration(days: 30));
  }

  bool get isOverdue {
    if (isPaidBack) return false;
    return DateTime.now().isAfter(dueDate);
  }

  // =============================================
  // JSON SERIALIZATION - FIXED for backend API
  // =============================================

  // FIXED: Backend expects DebtCreate model fields
  Map<String, dynamic> toJson() {
    return {
      'contact_id': int.tryParse(contactId) ?? contactId,
      'amount': debtAmount,
      'description': debtDescription,
      'is_my_debt': isMyDebt,
    };
  }

  // FIXED: Backend returns debt with contact info
  factory DebtRecordModelBackend.fromJson(Map<String, dynamic> json) {
    return DebtRecordModelBackend(
      recordId: json['id']?.toString() ?? '',
      contactId: json['contact_id']?.toString() ?? '',
      contactName: json['contact_name'] ?? 'Unknown Contact',
      contactPhone: json['contact_phone'],
      debtAmount: (json['amount'] ?? 0).toDouble(),
      debtDescription: json['description'] ?? '',
      createdDate: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()
      ),
      isMyDebt: json['is_my_debt'] ?? false,
      isPaidBack: json['is_paid'] ?? false,
    );
  }

  // =============================================
  // API METHODS - FIXED for backend
  // =============================================

  // FIXED: Create debt using backend DebtCreate model
  static Future<Map<String, dynamic>> createDebtRecord(DebtRecordModelBackend debtRecord) async {
    try {
      AppLogger.dataOperation('CREATE', 'Debt');

      final response = await _apiService.post(
        ApiConfig.debtsEndpoint,
        debtRecord.toJson(),
      );

      if (response['success'] == true) {
        AppLogger.dataOperation('CREATE', 'Debt', success: true);
      } else {
        AppLogger.dataOperation('CREATE', 'Debt', success: false);
      }

      return response;
    } catch (e) {
      AppLogger.error('Create debt record error', tag: 'DEBT', error: e);
      return {
        'success': false,
        'message': 'Failed to create debt: $e',
      };
    }
  }

  // FIXED: Get all debts with backend filters
  static Future<List<DebtRecordModelBackend>> getAllDebtRecords() async {
    try {
      AppLogger.info('Fetching all debt records', tag: 'DEBT');

      final response = await _apiService.get(ApiConfig.debtsEndpoint);

      if (response['success'] == true) {
        final data = response['data'];
        List<dynamic> debtsData = [];

        if (data != null && data['debts'] is List) {
          debtsData = data['debts'];
        } else if (data is List) {
          debtsData = data;
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

  // FIXED: Get debts by contact ID using backend filters
  static Future<List<DebtRecordModelBackend>> getDebtsByContactId(String contactId) async {
    try {
      AppLogger.info('Fetching debts for contact: $contactId', tag: 'DEBT');

      final queryString = ApiConfig.buildQueryString({'contact_id': contactId});
      final endpoint = '${ApiConfig.debtsEndpoint}$queryString';

      final response = await _apiService.get(endpoint);

      if (response['success'] == true) {
        final data = response['data'];
        List<dynamic> debtsData = [];

        if (data != null && data['debts'] is List) {
          debtsData = data['debts'];
        } else if (data is List) {
          debtsData = data;
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

  // FIXED: Get home overview using backend /debts/overview endpoint
  static Future<Map<String, dynamic>> getHomeOverview() async {
    try {
      AppLogger.info('Fetching home overview', tag: 'DEBT');

      final response = await _apiService.get(ApiConfig.homeOverviewEndpoint);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final summary = data['summary'] ?? {};

        final overview = {
          'success': true,
          'total_i_owe': (summary['i_owe'] ?? 0).toDouble(),
          'total_they_owe': (summary['they_owe_me'] ?? 0).toDouble(),
          'active_debts_count': summary['active_debts_count'] ?? 0,
          'overdue_debts_count': summary['paid_debts_count'] ?? 0,
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

  // FIXED: Get my debts using backend filters
  static Future<List<DebtRecordModelBackend>> getMyDebts() async {
    try {
      AppLogger.info('Fetching debts I owe', tag: 'DEBT');

      final queryString = ApiConfig.buildQueryString({
        'is_my_debt': 'true',
        'is_paid': 'false',
      });
      final endpoint = '${ApiConfig.debtsEndpoint}$queryString';

      final response = await _apiService.get(endpoint);

      if (response['success'] == true) {
        final data = response['data'];
        List<dynamic> debtsData = [];

        if (data != null && data['debts'] is List) {
          debtsData = data['debts'];
        } else if (data is List) {
          debtsData = data;
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

  // FIXED: Get their debts using backend filters
  static Future<List<DebtRecordModelBackend>> getTheirDebts() async {
    try {
      AppLogger.info('Fetching debts they owe me', tag: 'DEBT');

      final queryString = ApiConfig.buildQueryString({
        'is_my_debt': 'false',
        'is_paid': 'false',
      });
      final endpoint = '${ApiConfig.debtsEndpoint}$queryString';

      final response = await _apiService.get(endpoint);

      if (response['success'] == true) {
        final data = response['data'];
        List<dynamic> debtsData = [];

        if (data != null && data['debts'] is List) {
          debtsData = data['debts'];
        } else if (data is List) {
          debtsData = data;
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

  // FIXED: Get overdue debts with client-side filtering
  static Future<List<DebtRecordModelBackend>> getOverdueDebts() async {
    try {
      AppLogger.info('Fetching overdue debts', tag: 'DEBT');

      // Get all unpaid debts first
      final queryString = ApiConfig.buildQueryString({'is_paid': 'false'});
      final endpoint = '${ApiConfig.debtsEndpoint}$queryString';

      final response = await _apiService.get(endpoint);

      if (response['success'] == true) {
        final data = response['data'];
        List<dynamic> debtsData = [];

        if (data != null && data['debts'] is List) {
          debtsData = data['debts'];
        } else if (data is List) {
          debtsData = data;
        }

        final allDebts = debtsData
            .map((json) => DebtRecordModelBackend.fromJson(json))
            .toList();

        // Filter overdue debts client-side
        final now = DateTime.now();
        final overdueDebts = allDebts.where((debt) {
          final daysSinceCreated = now.difference(debt.createdDate).inDays;
          return daysSinceCreated > 30; // Consider overdue after 30 days
        }).toList();

        AppLogger.info(
            'Retrieved ${overdueDebts.length} overdue debts from ${allDebts.length} total',
            tag: 'DEBT'
        );
        return overdueDebts;
      }

      AppLogger.warning('Failed to get overdue debts: ${response['message']}', tag: 'DEBT');
      return [];
    } catch (e) {
      AppLogger.error('Get overdue debts error', tag: 'DEBT', error: e);
      return [];
    }
  }

  // FIXED: Calculate total amount I owe
  static Future<double> getTotalAmountIOwe() async {
    try {
      final myDebts = await getMyDebts();
      final total = myDebts.fold(0.0, (sum, debt) => sum + debt.debtAmount);

      AppLogger.info('Calculated total I owe: \${total.toStringAsFixed(2)}', tag: 'DEBT');
      return total;
    } catch (e) {
      AppLogger.error('Calculate total I owe error', tag: 'DEBT', error: e);
      return 0.0;
    }
  }

  // FIXED: Calculate total amount they owe me
  static Future<double> getTotalAmountTheyOweMe() async {
    try {
      final theirDebts = await getTheirDebts();
      final total = theirDebts.fold(0.0, (sum, debt) => sum + debt.debtAmount);

      AppLogger.info('Calculated total they owe me: \${total.toStringAsFixed(2)}', tag: 'DEBT');
      return total;
    } catch (e) {
      AppLogger.error('Calculate total they owe me error', tag: 'DEBT', error: e);
      return 0.0;
    }
  }

  // FIXED: Mark debt as paid using backend PATCH endpoint
  static Future<Map<String, dynamic>> markDebtAsPaid(String id) async {
    try {
      AppLogger.dataOperation('UPDATE', 'DebtPayment', id: id);

      final response = await _apiService.patch(
        ApiConfig.markDebtPaidEndpoint(id),
        {}, // Backend expects empty body for PATCH
      );

      if (response['success'] == true) {
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

  // FIXED: Update debt record
  static Future<Map<String, dynamic>> updateDebtRecord(String id, DebtRecordModelBackend debt) async {
    try {
      AppLogger.dataOperation('UPDATE', 'Debt', id: id);

      final updateData = {
        'amount': debt.debtAmount,
        'description': debt.debtDescription,
        'is_paid': debt.isPaidBack,
        'is_my_debt': debt.isMyDebt,
      };

      final response = await _apiService.put(
        ApiConfig.updateDebtEndpoint(id),
        updateData,
      );

      if (response['success'] == true) {
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

  // FIXED: Delete debt record
  static Future<Map<String, dynamic>> deleteDebtRecord(String id) async {
    try {
      AppLogger.dataOperation('DELETE', 'Debt', id: id);

      final response = await _apiService.delete(ApiConfig.deleteDebtEndpoint(id));

      if (response['success'] == true) {
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

  // FIXED: Get specific debt by ID
  static Future<DebtRecordModelBackend?> getDebtRecordById(String id) async {
    try {
      AppLogger.info('Fetching debt by ID: $id', tag: 'DEBT');

      final response = await _apiService.get(ApiConfig.getDebtEndpoint(id));

      if (response['success'] == true && response['data'] != null) {
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