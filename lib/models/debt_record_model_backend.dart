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

  // =============================================
  // CALCULATED PROPERTIES - Simple for students
  // =============================================

  bool get isOverdue {
    if (isPaidBack) return false;
    return DateTime.now().isAfter(dueDate);
  }

  // =============================================
  // JSON SERIALIZATION - Matching API exactly
  // =============================================

  // API expects these exact field names for contact-debt endpoint
  Map<String, dynamic> toJson() {
    return {
      'debt_amount': debtAmount,
      'description': debtDescription,
      'due_date': dueDate.toIso8601String(),
      'is_my_debt': isMyDebt,
    };
  }

  // Handle response from contact-debts endpoint
  factory DebtRecordModelBackend.fromJson(Map<String, dynamic> json) {
    return DebtRecordModelBackend(
      recordId: json['id']?.toString() ?? '',
      contactId: json['contact_id']?.toString() ?? '',
      contactName: json['contact_name'] ?? 'Unknown Contact',
      contactPhone: json['contact_phone'],
      debtAmount: (json['debt_amount'] ?? json['amount'] ?? 0).toDouble(),
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

  // =============================================
  // API METHODS - Simplified for students (Create only)
  // =============================================

  // CREATE debt using contact-debt endpoint with contact ID in path
  static Future<Map<String, dynamic>> createDebtRecord(DebtRecordModelBackend debtRecord) async {
    try {
      AppLogger.dataOperation('CREATE', 'Debt');

      final response = await _apiService.post(
        ApiConfig.createContactDebtEndpoint(debtRecord.contactId), // POST /api/v1/apps/contact-debt/{contactId}
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

  // GET debts by contact ID
  static Future<List<DebtRecordModelBackend>> getDebtsByContactId(String contactId) async {
    try {
      AppLogger.info('Fetching debts for contact: $contactId', tag: 'DEBT');

      final response = await _apiService.get(
          ApiConfig.getContactDebtsEndpoint(contactId) // GET /api/v1/apps/contact-debts/{contact_id}
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

  // GET home overview for dashboard
  static Future<Map<String, dynamic>> getHomeOverview() async {
    try {
      AppLogger.info('Fetching home overview', tag: 'DEBT');

      final response = await _apiService.get(ApiConfig.homeOverviewEndpoint); // GET /api/v1/apps/home/overview

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];

        final overview = {
          'success': true,
          'total_i_owe': (data['i_owe'] ?? 0).toDouble(),
          'total_they_owe': (data['they_owe'] ?? 0).toDouble(),
          'active_debts_count': data['active_debts'] ?? 0,
          'overdue_debts_count': data['overdue'] ?? 0,
        };

        AppLogger.info('Home overview retrieved successfully', tag: 'DEBT', data: overview);
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
  // CLIENT-SIDE CALCULATIONS - Simple for students
  // =============================================

  // Get all debts from all contacts (for overview calculations)
  static Future<List<DebtRecordModelBackend>> getAllDebtRecords() async {
    try {
      AppLogger.info('Getting all debt records by fetching from all contacts', tag: 'DEBT');

      // First get all contacts
      final contacts = await _apiService.get('/api/v1/apps/contact/list');
      if (contacts['success'] != true) {
        return [];
      }

      List<dynamic> contactsData = contacts['data'] ?? [];
      List<DebtRecordModelBackend> allDebts = [];

      // For each contact, get their debts
      for (var contactJson in contactsData) {
        final contactId = contactJson['id']?.toString();
        if (contactId != null) {
          final contactDebts = await getDebtsByContactId(contactId);
          allDebts.addAll(contactDebts);
        }
      }

      AppLogger.info('Retrieved total ${allDebts.length} debt records', tag: 'DEBT');
      return allDebts;
    } catch (e) {
      AppLogger.error('Get all debt records error', tag: 'DEBT', error: e);
      return [];
    }
  }

  // Get debts I owe (client-side filtering)
  static Future<List<DebtRecordModelBackend>> getMyDebts() async {
    try {
      AppLogger.info('Fetching debts I owe', tag: 'DEBT');

      final allDebts = await getAllDebtRecords();
      final myDebts = allDebts.where((debt) => debt.isMyDebt && !debt.isPaidBack).toList();

      AppLogger.info('Retrieved ${myDebts.length} debts I owe', tag: 'DEBT');
      return myDebts;
    } catch (e) {
      AppLogger.error('Get my debts error', tag: 'DEBT', error: e);
      return [];
    }
  }

  // Get debts they owe me (client-side filtering)
  static Future<List<DebtRecordModelBackend>> getTheirDebts() async {
    try {
      AppLogger.info('Fetching debts they owe me', tag: 'DEBT');

      final allDebts = await getAllDebtRecords();
      final theirDebts = allDebts.where((debt) => !debt.isMyDebt && !debt.isPaidBack).toList();

      AppLogger.info('Retrieved ${theirDebts.length} debts they owe me', tag: 'DEBT');
      return theirDebts;
    } catch (e) {
      AppLogger.error('Get their debts error', tag: 'DEBT', error: e);
      return [];
    }
  }

  // Get overdue debts (client-side filtering)
  static Future<List<DebtRecordModelBackend>> getOverdueDebts() async {
    try {
      AppLogger.info('Fetching overdue debts', tag: 'DEBT');

      final allDebts = await getAllDebtRecords();
      final overdueDebts = allDebts.where((debt) => !debt.isPaidBack && debt.isOverdue).toList();

      AppLogger.info('Retrieved ${overdueDebts.length} overdue debts', tag: 'DEBT');
      return overdueDebts;
    } catch (e) {
      AppLogger.error('Get overdue debts error', tag: 'DEBT', error: e);
      return [];
    }
  }

  // Calculate total amount I owe
  static Future<double> getTotalAmountIOwe() async {
    try {
      final myDebts = await getMyDebts();
      final total = myDebts.fold(0.0, (sum, debt) => sum + debt.debtAmount);

      AppLogger.info('Calculated total I owe: \$${total.toStringAsFixed(2)}', tag: 'DEBT');
      return total;
    } catch (e) {
      AppLogger.error('Calculate total I owe error', tag: 'DEBT', error: e);
      return 0.0;
    }
  }

  // Calculate total amount they owe me
  static Future<double> getTotalAmountTheyOweMe() async {
    try {
      final theirDebts = await getTheirDebts();
      final total = theirDebts.fold(0.0, (sum, debt) => sum + debt.debtAmount);

      AppLogger.info('Calculated total they owe me: \$${total.toStringAsFixed(2)}', tag: 'DEBT');
      return total;
    } catch (e) {
      AppLogger.error('Calculate total they owe me error', tag: 'DEBT', error: e);
      return 0.0;
    }
  }

  @override
  String toString() {
    return 'DebtRecordModelBackend{recordId: $recordId, contactId: $contactId, contactName: $contactName, debtAmount: $debtAmount, isMyDebt: $isMyDebt, isPaidBack: $isPaidBack}';
  }
}
