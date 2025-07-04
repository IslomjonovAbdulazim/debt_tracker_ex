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
  final DateTime dueDate;
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
    DateTime? dueDate,
    required this.isMyDebt,
    this.isPaidBack = false,
  }) : dueDate = dueDate ?? createdDate.add(const Duration(days: 30));

  // Calculated properties
  bool get isOverdue {
    if (isPaidBack) return false;
    return DateTime.now().isAfter(dueDate);
  }

  // JSON serialization - matching API documentation
  Map<String, dynamic> toJson() {
    return {
      'debt_amount': debtAmount,
      'description': debtDescription,
      'due_date': dueDate.toIso8601String(),
      'is_my_debt': isMyDebt,
    };
  }

  // JSON serialization for updates - includes all updatable fields
  Map<String, dynamic> toUpdateJson() {
    return {
      'debt_amount': debtAmount.toString(),
      'description': debtDescription,
      'due_date': dueDate.toIso8601String(),
      'is_my_debt': isMyDebt,
      'is_paid': isPaidBack,
      'is_overdue': isOverdue,
      'contact': contactId.isNotEmpty ? int.tryParse(contactId) ?? 0 : 0,
    };
  }

  factory DebtRecordModelBackend.fromJson(Map<String, dynamic> json) {
    return DebtRecordModelBackend(
      recordId: json['id']?.toString() ?? '',
      contactId: json['contact_id']?.toString() ?? '',
      contactName: json['contact_name'] ?? 'Unknown Contact',
      contactPhone: json['contact_phone'],
      debtAmount: double.tryParse(json['debt_amount']?.toString() ?? '0') ?? 0.0,
      debtDescription: json['description'] ?? '',
      createdDate: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()
      ),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()).add(const Duration(days: 30)),
      isMyDebt: json['is_my_debt'] ?? false,
      isPaidBack: json['is_paid'] ?? false,
    );
  }

  // Create a copy with updated fields
  DebtRecordModelBackend copyWith({
    String? recordId,
    String? contactId,
    String? contactName,
    String? contactPhone,
    double? debtAmount,
    String? debtDescription,
    DateTime? createdDate,
    DateTime? dueDate,
    bool? isMyDebt,
    bool? isPaidBack,
  }) {
    return DebtRecordModelBackend(
      recordId: recordId ?? this.recordId,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      debtAmount: debtAmount ?? this.debtAmount,
      debtDescription: debtDescription ?? this.debtDescription,
      createdDate: createdDate ?? this.createdDate,
      dueDate: dueDate ?? this.dueDate,
      isMyDebt: isMyDebt ?? this.isMyDebt,
      isPaidBack: isPaidBack ?? this.isPaidBack,
    );
  }

  // API Methods
  static Future<Map<String, dynamic>> createDebtRecord(DebtRecordModelBackend debtRecord) async {
    try {
      AppLogger.dataOperation('CREATE', 'Debt');

      final response = await _apiService.post(
        ApiConfig.createContactDebtEndpoint(debtRecord.contactId),
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

  // NEW: Update debt record method
  static Future<Map<String, dynamic>> updateDebtRecord(DebtRecordModelBackend debtRecord) async {
    try {
      AppLogger.dataOperation('UPDATE', 'Debt', id: debtRecord.recordId);

      final response = await _apiService.put(
        ApiConfig.updateDebtEndpoint(debtRecord.recordId),
        debtRecord.toUpdateJson(),
      );

      if (response['success'] == true) {
        AppLogger.dataOperation('UPDATE', 'Debt', id: debtRecord.recordId, success: true);
      } else {
        AppLogger.dataOperation('UPDATE', 'Debt', id: debtRecord.recordId, success: false);
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

  // NEW: Delete debt record method
  static Future<Map<String, dynamic>> deleteDebtRecord(String debtId) async {
    try {
      AppLogger.dataOperation('DELETE', 'Debt', id: debtId);

      final response = await _apiService.delete(
        ApiConfig.deleteDebtEndpoint(debtId),
      );

      if (response['success'] == true) {
        AppLogger.dataOperation('DELETE', 'Debt', id: debtId, success: true);
      } else {
        AppLogger.dataOperation('DELETE', 'Debt', id: debtId, success: false);
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

  static Future<List<DebtRecordModelBackend>> getDebtsByContactId(String contactId) async {
    try {
      AppLogger.info('Fetching debts for contact: $contactId', tag: 'DEBT');

      final response = await _apiService.get(
          ApiConfig.getContactDebtsEndpoint(contactId)
      );

      if (response['success'] == true) {
        final data = response['data'];
        List<dynamic> debtsData = [];

        if (data != null && data is List) {
          debtsData = data;
        } else if (data != null && data['debts'] is List) {
          debtsData = data['debts'];
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

  // FIXED: Get home overview matching exact API response structure
  static Future<Map<String, dynamic>> getHomeOverview() async {
    try {
      AppLogger.info('Fetching home overview', tag: 'DEBT');
      print('🏠 [DEBT] Making API call to: ${ApiConfig.homeOverviewEndpoint}');

      final response = await _apiService.get(ApiConfig.homeOverviewEndpoint);

      print('🏠 [DEBT] Raw response: $response');

      // Handle exact API structure: {"status": 200, "data": {...}}
      if (response['statusCode'] == 200 && response['data'] != null) {
        final data = response['data'];
        print('🏠 [DEBT] Data field: $data');

        // Parse exact API response structure
        final overview = {
          'success': true,
          'total_i_owe': double.tryParse(data['my_debt']?.toString() ?? '0') ?? 0.0,
          'total_they_owe': double.tryParse(data['their_debt']?.toString() ?? '0') ?? 0.0,
          'active_debts_count': int.tryParse(data['expired_debt']?.toString() ?? '0') ?? 0,
          'overdue_debts_count': data['overdue'] ?? 0,
        };

        print('🏠 [DEBT] Processed overview: $overview');
        AppLogger.info('Home overview retrieved successfully', tag: 'DEBT', data: overview);
        return overview;
      }

      print('❌ [DEBT] API call failed: ${response['message']}');
      AppLogger.warning('Failed to get home overview: ${response['message']}', tag: 'DEBT');
      return {
        'success': false,
        'total_i_owe': 0.0,
        'total_they_owe': 0.0,
        'active_debts_count': 0,
        'overdue_debts_count': 0,
      };
    } catch (e, stackTrace) {
      print('❌ [DEBT] Exception in getHomeOverview: $e');
      print('❌ [DEBT] Stack trace: $stackTrace');
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

  // Get all debts from new API endpoint
  static Future<List<DebtRecordModelBackend>> getAllDebtsFromAPI() async {
    try {
      AppLogger.info('Fetching all debts from API', tag: 'DEBT');
      print('📋 [DEBT] Making API call to: /api/v1/apps/debt/list');

      final response = await _apiService.get('/api/v1/apps/debt/list');
      print('📋 [DEBT] Raw response: $response');

      List<dynamic> debtsData = [];

      // Handle direct array response
      if (response['statusCode'] == 200 && response['data'] is List) {
        debtsData = response['data'] as List<dynamic>;
      }

      final debts = debtsData
          .map((json) => DebtRecordModelBackend.fromJson(json))
          .toList();

      print('✅ [DEBT] Retrieved ${debts.length} total debts');
      return debts;
    } catch (e) {
      print('❌ [DEBT] Error fetching all debts: $e');
      return [];
    }
  }

  // Update existing methods to use new API
  static Future<List<DebtRecordModelBackend>> getAllDebtRecords() async {
    return getAllDebtsFromAPI();
  }

  static Future<List<DebtRecordModelBackend>> getMyDebts() async {
    try {
      final allDebts = await getAllDebtRecords();
      final myDebts = allDebts.where((debt) => debt.isMyDebt && !debt.isPaidBack).toList();
      return myDebts;
    } catch (e) {
      return [];
    }
  }

  static Future<List<DebtRecordModelBackend>> getTheirDebts() async {
    try {
      final allDebts = await getAllDebtRecords();
      final theirDebts = allDebts.where((debt) => !debt.isMyDebt && !debt.isPaidBack).toList();
      return theirDebts;
    } catch (e) {
      return [];
    }
  }

  static Future<List<DebtRecordModelBackend>> getOverdueDebts() async {
    try {
      final allDebts = await getAllDebtRecords();
      final overdueDebts = allDebts.where((debt) => !debt.isPaidBack && debt.isOverdue).toList();
      return overdueDebts;
    } catch (e) {
      return [];
    }
  }

  static Future<double> getTotalAmountIOwe() async {
    try {
      final myDebts = await getMyDebts();
      return myDebts.fold<double>(0.0, (double sum, DebtRecordModelBackend debt) => sum + debt.debtAmount);
    } catch (e) {
      return 0.0;
    }
  }

  static Future<double> getTotalAmountTheyOweMe() async {
    try {
      final theirDebts = await getTheirDebts();
      return theirDebts.fold<double>(0.0, (double sum, DebtRecordModelBackend debt) => sum + debt.debtAmount);
    } catch (e) {
      return 0.0;
    }
  }

  // FIXED: Mark debt as paid using the correct new endpoint
  static Future<Map<String, dynamic>> markDebtAsPaid(String debtId) async {
    try {
      AppLogger.userAction('Mark debt as paid', context: {'debtId': debtId});
      print('💰 [DEBT] Marking debt as paid: $debtId');

      final response = await _apiService.post(
        ApiConfig.markDebtAsPaidEndpoint(debtId),
        {}, // Empty body as per API documentation
      );

      print('💰 [DEBT] Mark as paid response: $response');

      if (response['success'] == true) {
        AppLogger.dataOperation('UPDATE', 'DebtPayment', id: debtId, success: true);
        print('✅ [DEBT] Successfully marked debt $debtId as paid');
      } else {
        AppLogger.dataOperation('UPDATE', 'DebtPayment', id: debtId, success: false);
        print('❌ [DEBT] Failed to mark debt $debtId as paid: ${response['message']}');
      }

      return response;
    } catch (e) {
      AppLogger.error('Mark debt as paid error', tag: 'DEBT', error: e);
      print('❌ [DEBT] Exception marking debt as paid: $e');
      return {
        'success': false,
        'message': 'Failed to mark debt as paid: $e',
      };
    }
  }

  @override
  String toString() {
    return 'DebtRecordModelBackend{recordId: $recordId, contactId: $contactId, contactName: $contactName, debtAmount: $debtAmount, isMyDebt: $isMyDebt, isPaidBack: $isPaidBack}';
  }
}