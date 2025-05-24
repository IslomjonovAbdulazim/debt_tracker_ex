import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DebtRecordModel {
  final String recordId;
  final String contactId;
  final String contactName;
  final double debtAmount;
  final String debtDescription;
  final DateTime createdDate;
  final DateTime dueDate;
  final bool isMyDebt; // true if I owe them, false if they owe me
  final bool isPaidBack;

  DebtRecordModel({
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

  // Convert to JSON for storage
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

  // Create from JSON
  factory DebtRecordModel.fromJson(Map<String, dynamic> json) {
    return DebtRecordModel(
      recordId: json['recordId'],
      contactId: json['contactId'],
      contactName: json['contactName'],
      debtAmount: json['debtAmount'].toDouble(),
      debtDescription: json['debtDescription'],
      createdDate: DateTime.parse(json['createdDate']),
      dueDate: DateTime.parse(json['dueDate']),
      isMyDebt: json['isMyDebt'],
      isPaidBack: json['isPaidBack'] ?? false,
    );
  }

  // Check if debt is overdue
  bool get isOverdue {
    return !isPaidBack && DateTime.now().isAfter(dueDate);
  }

  // CRUD Operations - Local Database Connection

  // Create: Save new debt record
  static Future<bool> createDebtRecord(DebtRecordModel debtRecord) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<DebtRecordModel> debtRecords = await getAllDebtRecords();
      debtRecords.add(debtRecord);

      List<String> debtJsonList = debtRecords.map((d) => jsonEncode(d.toJson())).toList();
      return await prefs.setStringList('debt_records', debtJsonList);
    } catch (e) {
      return false;
    }
  }

  // Read: Get all debt records
  static Future<List<DebtRecordModel>> getAllDebtRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? debtJsonList = prefs.getStringList('debt_records');

      if (debtJsonList == null) return [];

      return debtJsonList
          .map((jsonStr) => DebtRecordModel.fromJson(jsonDecode(jsonStr)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Read: Get debt record by ID
  static Future<DebtRecordModel?> getDebtRecordById(String recordId) async {
    try {
      List<DebtRecordModel> debtRecords = await getAllDebtRecords();
      return debtRecords.firstWhere((record) => record.recordId == recordId);
    } catch (e) {
      return null;
    }
  }

  // Read: Get debts I owe
  static Future<List<DebtRecordModel>> getMyDebts() async {
    try {
      List<DebtRecordModel> allDebts = await getAllDebtRecords();
      return allDebts.where((debt) => debt.isMyDebt && !debt.isPaidBack).toList();
    } catch (e) {
      return [];
    }
  }

  // Read: Get debts they owe me
  static Future<List<DebtRecordModel>> getTheirDebts() async {
    try {
      List<DebtRecordModel> allDebts = await getAllDebtRecords();
      return allDebts.where((debt) => !debt.isMyDebt && !debt.isPaidBack).toList();
    } catch (e) {
      return [];
    }
  }

  // Read: Get overdue debts
  static Future<List<DebtRecordModel>> getOverdueDebts() async {
    try {
      List<DebtRecordModel> allDebts = await getAllDebtRecords();
      return allDebts.where((debt) => debt.isOverdue).toList();
    } catch (e) {
      return [];
    }
  }

  // Read: Get debts by contact ID
  static Future<List<DebtRecordModel>> getDebtsByContactId(String contactId) async {
    try {
      List<DebtRecordModel> allDebts = await getAllDebtRecords();
      return allDebts.where((debt) => debt.contactId == contactId).toList();
    } catch (e) {
      return [];
    }
  }

  // Update: Update existing debt record
  static Future<bool> updateDebtRecord(DebtRecordModel updatedRecord) async {
    try {
      List<DebtRecordModel> debtRecords = await getAllDebtRecords();
      int index = debtRecords.indexWhere((record) => record.recordId == updatedRecord.recordId);

      if (index == -1) return false;

      debtRecords[index] = updatedRecord;

      final prefs = await SharedPreferences.getInstance();
      List<String> debtJsonList = debtRecords.map((d) => jsonEncode(d.toJson())).toList();
      return await prefs.setStringList('debt_records', debtJsonList);
    } catch (e) {
      return false;
    }
  }

  // Update: Mark debt as paid back
  static Future<bool> markAsPaidBack(String recordId) async {
    try {
      DebtRecordModel? debtRecord = await getDebtRecordById(recordId);
      if (debtRecord == null) return false;

      DebtRecordModel updatedRecord = DebtRecordModel(
        recordId: debtRecord.recordId,
        contactId: debtRecord.contactId,
        contactName: debtRecord.contactName,
        debtAmount: debtRecord.debtAmount,
        debtDescription: debtRecord.debtDescription,
        createdDate: debtRecord.createdDate,
        dueDate: debtRecord.dueDate,
        isMyDebt: debtRecord.isMyDebt,
        isPaidBack: true,
      );

      return await updateDebtRecord(updatedRecord);
    } catch (e) {
      return false;
    }
  }

  // Delete: Remove debt record
  static Future<bool> deleteDebtRecord(String recordId) async {
    try {
      List<DebtRecordModel> debtRecords = await getAllDebtRecords();
      debtRecords.removeWhere((record) => record.recordId == recordId);

      final prefs = await SharedPreferences.getInstance();
      List<String> debtJsonList = debtRecords.map((d) => jsonEncode(d.toJson())).toList();
      return await prefs.setStringList('debt_records', debtJsonList);
    } catch (e) {
      return false;
    }
  }

  // Calculate: Get total amount I owe
  static Future<double> getTotalAmountIOwe() async {
    try {
      List<DebtRecordModel> myDebts = await getMyDebts();
      double total = 0.0;
      for (DebtRecordModel debt in myDebts) {
        total += debt.debtAmount;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  // Calculate: Get total amount they owe me
  static Future<double> getTotalAmountTheyOweMe() async {
    try {
      List<DebtRecordModel> theirDebts = await getTheirDebts();
      double total = 0.0;
      for (DebtRecordModel debt in theirDebts) {
        total += debt.debtAmount;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  // Clear: Delete all debt records
  static Future<bool> clearAllDebtRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove('debt_records');
    } catch (e) {
      return false;
    }
  }
}