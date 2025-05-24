import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/contact_model.dart';
import '../models/debt_model.dart';
import 'add_debt_page.dart';

class ContactDetailsPage extends StatefulWidget {
  final ContactModel contact;

  const ContactDetailsPage({super.key, required this.contact});

  @override
  State<ContactDetailsPage> createState() => _ContactDetailsPageState();
}

class _ContactDetailsPageState extends State<ContactDetailsPage> {
  List<DebtRecordModel> contactDebts = [];
  bool isLoading = true;
  double totalIOwe = 0.0;
  double totalTheyOwe = 0.0;

  @override
  void initState() {
    super.initState();
    _loadContactDebts();
  }

  Future<void> _loadContactDebts() async {
    setState(() => isLoading = true);

    try {
      final debts = await DebtRecordModel.getDebtsByContactId(widget.contact.id);

      double myTotal = 0.0;
      double theirTotal = 0.0;

      for (final debt in debts) {
        if (!debt.isPaidBack) {
          if (debt.isMyDebt) {
            myTotal += debt.debtAmount;
          } else {
            theirTotal += debt.debtAmount;
          }
        }
      }

      setState(() {
        contactDebts = debts;
        totalIOwe = myTotal;
        totalTheyOwe = theirTotal;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _markDebtAsPaid(DebtRecordModel debt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Text(
            'Mark this debt of \$${debt.debtAmount.toStringAsFixed(2)} as paid back?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark as Paid'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await DebtRecordModel.markAsPaidBack(debt.recordId);
      if (success) {
        _loadContactDebts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debt marked as paid!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(widget.contact.fullName),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadContactDebts,
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
            child: Column(
              children: [
              // Contact Header
              Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      widget.contact.fullName.isNotEmpty
                          ? widget.contact.fullName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.contact.fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.contact.phoneNumber,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Debt Summary Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'I Owe Them',
                      totalIOwe,
                      Colors.red[400]!,
                      Icons.arrow_upward,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'They Owe Me',
                      totalTheyOwe,
                      Colors.green[400]!,
                      Icons.arrow_downward,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick Add Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToAddDebt(true),
                      icon: const Icon(Icons.add),
                      label: const Text('I Owe Them'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToAddDebt(false),
                      icon: const Icon(Icons.add),
                      label: const Text('They Owe Me'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Debts List
            if (contactDebts.isEmpty)
        _buildEmptyDebtsState()
    else
    Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const Padding(
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: Text(
    'Debt History',
    style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
    ),
    ),