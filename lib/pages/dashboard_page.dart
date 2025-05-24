import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../models/debt_record_model.dart';
import 'contacts_page.dart';
import 'debts_overview_page.dart';
import 'payment_history_page.dart';
import 'add_debt_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double totalIOwe = 0.0;
  double totalTheyOwe = 0.0;
  int activeDebts = 0;
  int overdueCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);

    try {
      final myDebtsAmount = await DebtRecordModel.getTotalAmountIOwe();
      final theirDebtsAmount = await DebtRecordModel.getTotalAmountTheyOweMe();
      final allDebts = await DebtRecordModel.getAllDebtRecords();
      final overdueDebts = await DebtRecordModel.getOverdueDebts();

      setState(() {
        totalIOwe = myDebtsAmount;
        totalTheyOwe = theirDebtsAmount;
        activeDebts = allDebts.where((debt) => !debt.isPaidBack).length;
        overdueCount = overdueDebts.length;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _showContactSelectionDialog(bool isMyDebt) async {
    final contacts = await ContactModel.getAllContacts();

    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No contacts found. Please add a contact first.'),
          backgroundColor: Colors.orange,
        ),
      );
      // Navigate to contacts page to add contact
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ContactsPage()),
      ).then((_) => _loadDashboardData());
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isMyDebt ? 'I Owe Money To...' : 'Someone Owes Me...'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isMyDebt ? Colors.red[100] : Colors.green[100],
                  child: Text(
                    contact.fullName.isNotEmpty ? contact.fullName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: isMyDebt ? Colors.red[700] : Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(contact.fullName),
                subtitle: Text(contact.phoneNumber),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddDebtPage(
                        contact: contact,
                        isMyDebt: isMyDebt,
                      ),
                    ),
                  ).then((_) => _loadDashboardData());
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactsPage()),
              ).then((_) => _loadDashboardData());
            },
            child: const Text('Add New Contact'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Debt Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Financial Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track and manage your debts easily',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Money Overview Cards with Navigation
              Row(
                children: [
                  Expanded(
                    child: _buildMoneyCardWithAction(
                      'I Owe',
                      totalIOwe,
                      Colors.red[400]!,
                      Icons.arrow_upward,
                      0, // Tab index for "I Owe" tab
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMoneyCardWithAction(
                      'They Owe',
                      totalTheyOwe,
                      Colors.green[400]!,
                      Icons.arrow_downward,
                      1, // Tab index for "They Owe" tab
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Status Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      'Active',
                      activeDebts.toString(),
                      Colors.blue[400]!,
                      Icons.receipt_long,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatusCard(
                      'Overdue',
                      overdueCount.toString(),
                      Colors.orange[400]!,
                      Icons.warning_amber,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Quick Add Debt Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Add Debt',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quickly record a new debt without navigating through contacts',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showContactSelectionDialog(true),
                            icon: const Icon(Icons.add),
                            label: const Text('I Owe Money'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[400],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showContactSelectionDialog(false),
                            icon: const Icon(Icons.add),
                            label: const Text('They Owe Me'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[400],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Navigation Actions
              const Text(
                'More Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              _buildActionCard(
                'Manage Contacts',
                'Add, edit, or view your contacts',
                Icons.people_outline,
                Colors.purple[400]!,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ContactsPage()),
                ).then((_) => _loadDashboardData()),
              ),

              const SizedBox(height: 12),

              _buildActionCard(
                'View All Debts',
                'See all active and completed debts',
                Icons.receipt_long_outlined,
                Colors.indigo[400]!,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DebtsPage()),
                ).then((_) => _loadDashboardData()),
              ),

              const SizedBox(height: 12),

              _buildActionCard(
                'Payment History',
                'Review all payment records',
                Icons.history,
                Colors.teal[400]!,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryPage()),
                ).then((_) => _loadDashboardData()),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoneyCardWithAction(String title, double amount, Color color, IconData icon, int tabIndex) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DebtsPage(initialTabIndex: tabIndex),
        ),
      ).then((_) => _loadDashboardData()),
      child: Container(
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
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Tap to view',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, Color color, IconData icon) {
    // Determine which tab to navigate to based on title
    int tabIndex = title == 'Overdue' ? 2 : -1; // -1 means no navigation

    return GestureDetector(
      onTap: tabIndex != -1 ? () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DebtsPage(initialTabIndex: tabIndex),
        ),
      ).then((_) => _loadDashboardData()) : null,
      child: Container(
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
          border: tabIndex != -1 ? Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (tabIndex != -1) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Tap to view',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }
}