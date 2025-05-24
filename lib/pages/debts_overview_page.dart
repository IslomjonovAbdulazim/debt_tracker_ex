import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/debt_model.dart';

class DebtsPage extends StatefulWidget {
  const DebtsPage({super.key});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DebtRecordModel> myDebts = [];
  List<DebtRecordModel> theirDebts = [];
  List<DebtRecordModel> overdueDebts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDebts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDebts() async {
    setState(() => isLoading = true);

    try {
      final myDebtsList = await DebtRecordModel.getMyDebts();
      final theirDebtsList = await DebtRecordModel.getTheirDebts();
      final overdueDebtsList = await DebtRecordModel.getOverdueDebts();

      setState(() {
        myDebts = myDebtsList;
        theirDebts = theirDebtsList;
        overdueDebts = overdueDebtsList;
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
            'Mark this debt of \$${debt.debtAmount.toStringAsFixed(2)} with ${debt.contactName} as paid back?'
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
        _loadDebts();
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
        title: const Text('All Debts'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebts,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue[600],
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.blue[600],
          tabs: [
            Tab(
              text: 'I Owe (${myDebts.length})',
              icon: const Icon(Icons.arrow_upward, size: 16),
            ),
            Tab(
              text: 'They Owe (${theirDebts.length})',
              icon: const Icon(Icons.arrow_downward, size: 16),
            ),
            Tab(
              text: 'Overdue (${overdueDebts.length})',
              icon: const Icon(Icons.warning, size: 16),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildDebtsList(myDebts, true),
          _buildDebtsList(theirDebts, false),
          _buildDebtsList(overdueDebts, null),
        ],
      ),
    );
  }

  Widget _buildDebtsList(List<DebtRecordModel> debts, bool? isMyDebt) {
    if (debts.isEmpty) {
      return _buildEmptyState(isMyDebt);
    }

    // Calculate total for this tab
    double total = debts.fold(0.0, (sum, debt) => sum + debt.debtAmount);

    return Column(
      children: [
      // Total Summary Card
      Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
          Text(
            'Total Amount',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
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
            // Header Row - Contact and Amount
            Row(
              children: [
                // Contact Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: debt.isMyDebt
                      ? Colors.red[100]
                      : Colors.green[100],
                  child: Text(
                    debt.contactName.isNotEmpty
                        ? debt.contactName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: debt.isMyDebt
                          ? Colors.red[700]
                          : Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Contact Name and Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.contactName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: debt.isMyDebt
                              ? Colors.red[50]
                              : Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: debt.isMyDebt
                                ? Colors.red[200]!
                                : Colors.green[200]!,
                          ),
                        ),
                        child: Text(
                          debt.isMyDebt ? 'I Owe' : 'They Owe',
                          style: TextStyle(
                            color: debt.isMyDebt
                                ? Colors.red[700]
                                : Colors.green[700],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\${debt.debtAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: debt.isMyDebt ? Colors.red[600] : Colors.green[600],
                      ),
                    ),
                    if (isOverdue)
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
        ),
      ),
    );
  }
}(height: 8),
Text(
'\$${total.toStringAsFixed(2)}',
style: TextStyle(
fontSize: 28,
fontWeight: FontWeight.bold,
color: isMyDebt == true
? Colors.red[600]
    : isMyDebt == false
? Colors.green[600]
    : Colors.orange[600],
),
),
const SizedBox(height: 4),
Text(
'${debts.length} ${debts.length == 1 ? 'debt' : 'debts'}',
style: TextStyle(
fontSize: 12,
color: Colors.grey[500],
),
),
],
),
),

// Debts List
Expanded(
child: RefreshIndicator(
onRefresh: _loadDebts,
child: ListView.builder(
padding: const EdgeInsets.symmetric(horizontal: 16),
itemCount: debts.length,
itemBuilder: (context, index) {
final debt = debts[index];
return _buildDebtCard(debt);
},
),
),
),
],
);
}

Widget _buildEmptyState(bool? isMyDebt) {
String title;
String subtitle;
IconData icon;

if (isMyDebt == true) {
title = 'No debts you owe';
subtitle = 'You don\'t owe anyone money right now';
icon = Icons.sentiment_satisfied;
} else if (isMyDebt == false) {
title = 'No one owes you';
subtitle = 'No one owes you money right now';
icon = Icons.sentiment_neutral;
} else {
title = 'No overdue debts';
subtitle = 'All debts are on track!';
icon = Icons.check_circle_outline;
}

return Center(
child: Padding(
padding: const EdgeInsets.all(40),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
icon,
size: 80,
color: Colors.grey[400],
),
const SizedBox(height: 20),
Text(
title,
style: TextStyle(
fontSize: 20,
color: Colors.grey[600],
fontWeight: FontWeight.w600,
),
),
const SizedBox