import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/contact_model.dart';
import '../models/debt_record_model.dart';
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

  void _navigateToAddDebt(bool isMyDebt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDebtPage(
          contact: widget.contact,
          isMyDebt: isMyDebt,
        ),
      ),
    ).then((_) => _loadContactDebts());
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
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: contactDebts.length,
                        itemBuilder: (context, index) {
                          final debt = contactDebts[index];
                          return _buildDebtCard(debt);
                        },
                      ),
                    ],
                  ),

                const SizedBox(height: 20),
              ],
            )
        )
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDebtsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'No debts recorded',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Use the buttons above to add a debt record with ${widget.contact.fullName}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtCard(DebtRecordModel debt) {
    final isOverdue = debt.isOverdue;
    final daysDifference = debt.dueDate.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: debt.isMyDebt ? Colors.red[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: debt.isMyDebt ? Colors.red[200]! : Colors.green[200]!,
                    ),
                  ),
                  child: Text(
                    debt.isMyDebt ? 'I Owe' : 'They Owe',
                    style: TextStyle(
                      color: debt.isMyDebt ? Colors.red[700] : Colors.green[700],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const Spacer(),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${debt.debtAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: debt.isMyDebt ? Colors.red[600] : Colors.green[600],
                      ),
                    ),
                    if (debt.isPaidBack)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'PAID',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'OVERDUE',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                debt.debtDescription,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Date Information
            Row(
              children: [
                // Created Date
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Created',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              DateFormat('MMM dd').format(debt.createdDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Due Date
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isOverdue ? Icons.warning : Icons.schedule,
                        size: 14,
                        color: isOverdue ? Colors.orange[600] : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Due Date',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              DateFormat('MMM dd').format(debt.dueDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: isOverdue ? Colors.orange[700] : Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Days Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isOverdue ? 'Overdue by' : 'Due in',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${daysDifference.abs()} ${daysDifference.abs() == 1 ? 'day' : 'days'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue ? Colors.orange[700] : Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (!debt.isPaidBack) ...[
              const SizedBox(height: 12),
              // Action Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _markDebtAsPaid(debt),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Mark as Paid'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[600],
                    side: BorderSide(color: Colors.blue[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}