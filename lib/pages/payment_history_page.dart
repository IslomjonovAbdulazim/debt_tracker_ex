import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment_history_model.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PaymentHistoryModel> allPayments = [];
  List<PaymentHistoryModel> myPayments = [];
  List<PaymentHistoryModel> theirPayments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPaymentHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() => isLoading = true);

    try {
      final allPaymentsList = await PaymentHistoryModel.getAllPaymentHistories();
      final myPaymentsList = await PaymentHistoryModel.getMyPayments();
      final theirPaymentsList = await PaymentHistoryModel.getTheirPayments();

      // Sort all lists by payment date (newest first)
      allPaymentsList.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      myPaymentsList.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      theirPaymentsList.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

      setState(() {
        allPayments = allPaymentsList;
        myPayments = myPaymentsList;
        theirPayments = theirPaymentsList;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPaymentHistory,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue[600],
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.blue[600],
          tabs: [
            Tab(
              text: 'All (${allPayments.length})',
              icon: const Icon(Icons.history, size: 16),
            ),
            Tab(
              text: 'I Paid (${myPayments.length})',
              icon: const Icon(Icons.arrow_upward, size: 16),
            ),
            Tab(
              text: 'They Paid (${theirPayments.length})',
              icon: const Icon(Icons.arrow_downward, size: 16),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildPaymentsList(allPayments, null),
          _buildPaymentsList(myPayments, true),
          _buildPaymentsList(theirPayments, false),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(List<PaymentHistoryModel> payments, bool? wasMyDebt) {
    if (payments.isEmpty) {
      return _buildEmptyState(wasMyDebt);
    }

    // Calculate total for this tab
    double total = payments.fold(0.0, (sum, payment) => sum + payment.paidAmount);

    return Column(
      children: [
        // Total Summary Card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: wasMyDebt == true
                  ? [Colors.red[400]!, Colors.red[500]!]
                  : wasMyDebt == false
                  ? [Colors.green[400]!, Colors.green[500]!]
                  : [Colors.blue[400]!, Colors.blue[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Total Paid',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${payments.length} ${payments.length == 1 ? 'payment' : 'payments'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),

        // Payments List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadPaymentHistory,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return _buildPaymentCard(payment);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool? wasMyDebt) {
    String title;
    String subtitle;
    IconData icon;

    if (wasMyDebt == true) {
      title = 'No payments made';
      subtitle = 'You haven\'t paid back any debts yet';
      icon = Icons.payment_outlined;
    } else if (wasMyDebt == false) {
      title = 'No payments received';
      subtitle = 'No one has paid you back yet';
      icon = Icons.account_balance_wallet_outlined;
    } else {
      title = 'No payment history';
      subtitle = 'No payments have been recorded yet';
      icon = Icons.history;
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

  Widget _buildPaymentCard(PaymentHistoryModel payment) {
    final isRecent = DateTime.now().difference(payment.paymentDate).inDays < 7;

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
                // Payment Direction Indicator
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: payment.wasMyDebt
                        ? Colors.red[50]
                        : Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    payment.wasMyDebt
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: payment.wasMyDebt
                        ? Colors.red[600]
                        : Colors.green[600],
                    size: 20,
                  ),
                ),

                const SizedBox(width: 12),

                // Contact and Payment Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.contactName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        payment.wasMyDebt ? 'I paid them' : 'They paid me',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount and Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\${payment.paidAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: payment.wasMyDebt
                            ? Colors.red[600]
                            : Colors.green[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isRecent) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.blue[400],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          DateFormat('MMM dd').format(payment.paymentDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: isRecent ? Colors.blue[600] : Colors.grey[600],
                            fontWeight: isRecent ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                payment.paymentDescription,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Payment Details
            Row(
              children: [
                // Payment Date
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Date',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            DateFormat('MMM dd, yyyy').format(payment.paymentDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Payment Time
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            DateFormat('h:mm a').format(payment.paymentDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Text(
                    'COMPLETED',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}