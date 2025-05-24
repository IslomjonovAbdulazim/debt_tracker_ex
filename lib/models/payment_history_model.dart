import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentHistoryModel {
  final String paymentId;
  final String originalDebtId;
  final String contactName;
  final double paidAmount;
  final String paymentDescription;
  final DateTime paymentDate;
  final bool wasMyDebt; // Was it me who owed or they who owed

  PaymentHistoryModel({
    required this.paymentId,
    required this.originalDebtId,
    required this.contactName,
    required this.paidAmount,
    required this.paymentDescription,
    required this.paymentDate,
    required this.wasMyDebt,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'originalDebtId': originalDebtId,
      'contactName': contactName,
      'paidAmount': paidAmount,
      'paymentDescription': paymentDescription,
      'paymentDate': paymentDate.toIso8601String(),
      'wasMyDebt': wasMyDebt,
    };
  }

  // Create from JSON
  factory PaymentHistoryModel.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryModel(
      paymentId: json['paymentId'],
      originalDebtId: json['originalDebtId'],
      contactName: json['contactName'],
      paidAmount: json['paidAmount'].toDouble(),
      paymentDescription: json['paymentDescription'],
      paymentDate: DateTime.parse(json['paymentDate']),
      wasMyDebt: json['wasMyDebt'],
    );
  }

  // CRUD Operations - Local Database Connection

  // Create: Save new payment history
  static Future<bool> createPaymentHistory(PaymentHistoryModel paymentHistory) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<PaymentHistoryModel> paymentHistories = await getAllPaymentHistories();
      paymentHistories.add(paymentHistory);

      List<String> paymentJsonList = paymentHistories.map((p) => jsonEncode(p.toJson())).toList();
      return await prefs.setStringList('payment_histories', paymentJsonList);
    } catch (e) {
      return false;
    }
  }

  // Read: Get all payment histories
  static Future<List<PaymentHistoryModel>> getAllPaymentHistories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? paymentJsonList = prefs.getStringList('payment_histories');

      if (paymentJsonList == null) return [];

      return paymentJsonList
          .map((jsonStr) => PaymentHistoryModel.fromJson(jsonDecode(jsonStr)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Read: Get payment history by ID
  static Future<PaymentHistoryModel?> getPaymentHistoryById(String paymentId) async {
    try {
      List<PaymentHistoryModel> paymentHistories = await getAllPaymentHistories();
      return paymentHistories.firstWhere((payment) => payment.paymentId == paymentId);
    } catch (e) {
      return null;
    }
  }

  // Read: Get payments where I paid back
  static Future<List<PaymentHistoryModel>> getMyPayments() async {
    try {
      List<PaymentHistoryModel> allPayments = await getAllPaymentHistories();
      return allPayments.where((payment) => payment.wasMyDebt).toList();
    } catch (e) {
      return [];
    }
  }

  // Read: Get payments where they paid me back
  static Future<List<PaymentHistoryModel>> getTheirPayments() async {
    try {
      List<PaymentHistoryModel> allPayments = await getAllPaymentHistories();
      return allPayments.where((payment) => !payment.wasMyDebt).toList();
    } catch (e) {
      return [];
    }
  }

  // Read: Get payment history by contact name
  static Future<List<PaymentHistoryModel>> getPaymentsByContact(String contactName) async {
    try {
      List<PaymentHistoryModel> allPayments = await getAllPaymentHistories();
      return allPayments.where((payment) => payment.contactName == contactName).toList();
    } catch (e) {
      return [];
    }
  }

  // Read: Get recent payment histories (last 30 days)
  static Future<List<PaymentHistoryModel>> getRecentPayments() async {
    try {
      List<PaymentHistoryModel> allPayments = await getAllPaymentHistories();
      DateTime thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      return allPayments
          .where((payment) => payment.paymentDate.isAfter(thirtyDaysAgo))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Update: Update existing payment history
  static Future<bool> updatePaymentHistory(PaymentHistoryModel updatedPayment) async {
    try {
      List<PaymentHistoryModel> paymentHistories = await getAllPaymentHistories();
      int index = paymentHistories.indexWhere((payment) => payment.paymentId == updatedPayment.paymentId);

      if (index == -1) return false;

      paymentHistories[index] = updatedPayment;

      final prefs = await SharedPreferences.getInstance();
      List<String> paymentJsonList = paymentHistories.map((p) => jsonEncode(p.toJson())).toList();
      return await prefs.setStringList('payment_histories', paymentJsonList);
    } catch (e) {
      return false;
    }
  }

  // Delete: Remove payment history
  static Future<bool> deletePaymentHistory(String paymentId) async {
    try {
      List<PaymentHistoryModel> paymentHistories = await getAllPaymentHistories();
      paymentHistories.removeWhere((payment) => payment.paymentId == paymentId);

      final prefs = await SharedPreferences.getInstance();
      List<String> paymentJsonList = paymentHistories.map((p) => jsonEncode(p.toJson())).toList();
      return await prefs.setStringList('payment_histories', paymentJsonList);
    } catch (e) {
      return false;
    }
  }

  // Calculate: Get total amount I have paid back
  static Future<double> getTotalAmountIPaid() async {
    try {
      List<PaymentHistoryModel> myPayments = await getMyPayments();
      double total = 0.0;
      for (PaymentHistoryModel payment in myPayments) {
        total += payment.paidAmount;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  // Calculate: Get total amount they have paid me back
  static Future<double> getTotalAmountTheyPaid() async {
    try {
      List<PaymentHistoryModel> theirPayments = await getTheirPayments();
      double total = 0.0;
      for (PaymentHistoryModel payment in theirPayments) {
        total += payment.paidAmount;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  // Clear: Delete all payment histories
  static Future<bool> clearAllPaymentHistories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove('payment_histories');
    } catch (e) {
      return false;
    }
  }
}