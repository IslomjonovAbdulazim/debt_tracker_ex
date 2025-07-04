import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/debt_record_model_backend.dart';
import '../models/contact_model.dart';
import '../config/app_theme.dart';
import '../config/app_logger.dart';
import 'edit_debt_page.dart';

class DebtsPage extends StatefulWidget {
  final int initialTabIndex;

  const DebtsPage({super.key, this.initialTabIndex = 0});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DebtRecordModelBackend> myDebts = [];
  List<DebtRecordModelBackend> theirDebts = [];
  List<DebtRecordModelBackend> overdueDebts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    AppLogger.lifecycle('DebtsPage initialized', data: {
      'initialTabIndex': widget.initialTabIndex,
    });
    _loadDebts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    AppLogger.lifecycle('DebtsPage disposed');
    super.dispose();
  }

  Future<void> _loadDebts() async {
    setState(() => isLoading = true);

    final stopwatch = Stopwatch()..start();
    AppLogger.info('Starting to load all debts data', tag: 'DEBTS_PAGE');
    print('📋 [DEBTS_PAGE] Starting debt loading process');

    try {
      // Use new direct API endpoint
      print('📋 [DEBTS_PAGE] Calling getAllDebtsFromAPI...');
      final allDebts = await DebtRecordModelBackend.getAllDebtsFromAPI();

      print('📋 [DEBTS_PAGE] Received ${allDebts.length} total debts from API');
      AppLogger.info('Retrieved ${allDebts.length} total debts', tag: 'DEBTS_PAGE');

      // Filter debts by type
      print('📋 [DEBTS_PAGE] Filtering debts by categories...');

      final myDebtsList = allDebts.where((debt) => debt.isMyDebt && !debt.isPaidBack).toList();
      print('📋 [DEBTS_PAGE] Found ${myDebtsList.length} debts I owe');

      final theirDebtsList = allDebts.where((debt) => !debt.isMyDebt && !debt.isPaidBack).toList();
      print('📋 [DEBTS_PAGE] Found ${theirDebtsList.length} debts they owe me');

      final overdueDebtsList = allDebts.where((debt) => !debt.isPaidBack && debt.isOverdue).toList();
      print('📋 [DEBTS_PAGE] Found ${overdueDebtsList.length} overdue debts');

      // Log detailed breakdown
      double myTotal = myDebtsList.fold(0.0, (sum, debt) => sum + debt.debtAmount);
      double theirTotal = theirDebtsList.fold(0.0, (sum, debt) => sum + debt.debtAmount);
      double overdueTotal = overdueDebtsList.fold(0.0, (sum, debt) => sum + debt.debtAmount);

      print('📋 [DEBTS_PAGE] My debts total: \$${myTotal.toStringAsFixed(2)}');
      print('📋 [DEBTS_PAGE] Their debts total: \$${theirTotal.toStringAsFixed(2)}');
      print('📋 [DEBTS_PAGE] Overdue debts total: \$${overdueTotal.toStringAsFixed(2)}');

      stopwatch.stop();
      AppLogger.performance('Debts load', stopwatch.elapsed, data: {
        'totalDebts': allDebts.length,
        'myDebtsCount': myDebtsList.length,
        'theirDebtsCount': theirDebtsList.length,
        'overdueDebtsCount': overdueDebtsList.length,
        'myDebtsTotal': myTotal,
        'theirDebtsTotal': theirTotal,
        'overdueDebtsTotal': overdueTotal,
      });

      setState(() {
        myDebts = myDebtsList;
        theirDebts = theirDebtsList;
        overdueDebts = overdueDebtsList;
        isLoading = false;
      });

      print('✅ [DEBTS_PAGE] Successfully loaded and categorized all debts');
      AppLogger.info('Debts loading completed successfully', tag: 'DEBTS_PAGE');

    } catch (e, stackTrace) {
      stopwatch.stop();
      print('❌ [DEBTS_PAGE] Error loading debts: $e');
      print('❌ [DEBTS_PAGE] Stack trace: $stackTrace');
      AppLogger.error('Failed to load debts', tag: 'DEBTS_PAGE', error: e);

      setState(() => isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load debts: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadDebts,
            ),
          ),
        );
      }
    }
  }

  // FIXED: Now using the working API endpoint
  Future<void> _markDebtAsPaid(DebtRecordModelBackend debt) async {
    AppLogger.userAction('Mark debt as paid attempt', context: {
      'debtId': debt.recordId,
      'amount': debt.debtAmount,
    });

    try {
      // Show loading feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Marking debt as paid...'),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      final result = await DebtRecordModelBackend.markDebtAsPaid(debt.recordId);

      if (!mounted) return;

      // Clear the loading snackbar
      ScaffoldMessenger.of(context).clearSnackBars();

      if (result['success'] == true) {
        AppLogger.dataOperation('UPDATE', 'DebtPayment', id: debt.recordId, success: true);
        _loadDebts(); // Refresh all debt lists

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Debt marked as paid successfully!'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        AppLogger.dataOperation('UPDATE', 'DebtPayment', id: debt.recordId, success: false);

        String errorMessage = result['message'] ?? 'Failed to mark debt as paid';
        if (result['errors'] != null && result['errors'] is Map) {
          final errors = result['errors'] as Map;
          if (errors.isNotEmpty) {
            errorMessage = errors.values.first.toString();
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Mark debt as paid error', tag: 'DEBTS', error: e);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // NEW: Edit debt functionality
  Future<void> _editDebt(DebtRecordModelBackend debt) async {
    AppLogger.userAction('Navigate to edit debt from overview', context: {
      'debtId': debt.recordId,
      'contactId': debt.contactId,
    });

    try {
      // We need to get the contact info first
      // For simplicity, we'll create a minimal contact object
      final contact = ContactModel(
        id: debt.contactId,
        fullName: debt.contactName,
        phoneNumber: debt.contactPhone ?? '',
        createdDate: DateTime.now(),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditDebtPage(
            contact: contact,
            debt: debt,
          ),
        ),
      ).then((_) {
        AppLogger.info('Returned from edit debt, refreshing all debts', tag: 'DEBTS_PAGE');
        _loadDebts();
      });
    } catch (e) {
      AppLogger.error('Edit debt navigation error', tag: 'DEBTS_PAGE', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening edit page: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // NEW: Delete debt functionality
  Future<void> _deleteDebt(DebtRecordModelBackend debt) async {
    AppLogger.userAction('Delete debt attempt', context: {
      'debtId': debt.recordId,
      'amount': debt.debtAmount,
    });

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Debt Record'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this debt record?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact: ${debt.contactName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Amount: \$${debt.debtAmount.toStringAsFixed(2)}'),
                  Text('Description: ${debt.debtDescription}'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await DebtRecordModelBackend.deleteDebtRecord(debt.recordId);

        if (!mounted) return;

        if (result['success'] == true) {
          AppLogger.dataOperation('DELETE', 'Debt', id: debt.recordId, success: true);
          _loadDebts(); // Refresh all debt lists

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Debt record deleted successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          AppLogger.dataOperation('DELETE', 'Debt', id: debt.recordId, success: false);

          String errorMessage = result['message'] ?? 'Failed to delete debt record';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        AppLogger.error('Delete debt error', tag: 'DEBTS', error: e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final financialColors = DebtThemeUtils.getFinancialColors(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('All Debts'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              AppLogger.userAction('Manual refresh triggered');
              _loadDebts();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: financialColors.debt,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: financialColors.debt,
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: theme.textTheme.labelLarge,
          tabs: [
            Tab(
              text: 'I Owe (${myDebts.length})',
              icon: Icon(Icons.arrow_upward, size: 16, color: financialColors.debt),
            ),
            Tab(
              text: 'They Owe (${theirDebts.length})',
              icon: Icon(Icons.arrow_downward, size: 16, color: financialColors.credit),
            ),
            Tab(
              text: 'Overdue (${overdueDebts.length})',
              icon: Icon(Icons.warning, size: 16, color: theme.colorScheme.error),
            ),
          ],
          onTap: (index) {
            AppLogger.userAction('Debt tab changed', context: {'tabIndex': index});
          },
        ),
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Loading debts...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      )
          : TabBarView(
        controller: _tabController,
        children: [
          _buildDebtsList(myDebts, true, theme, financialColors),
          _buildDebtsList(theirDebts, false, theme, financialColors),
          _buildDebtsList(overdueDebts, null, theme, financialColors),
        ],
      ),
    );
  }

  Widget _buildDebtsList(
      List<DebtRecordModelBackend> debts,
      bool? isMyDebt,
      ThemeData theme,
      FinancialColors financialColors,
      ) {
    if (debts.isEmpty) {
      return _buildEmptyState(isMyDebt, theme);
    }

    // Calculate total for this tab
    double total = debts.fold(0.0, (sum, debt) => sum + debt.debtAmount);

    Color summaryColor;
    if (isMyDebt == true) {
      summaryColor = financialColors.debt!;
    } else if (isMyDebt == false) {
      summaryColor = financialColors.credit!;
    } else {
      summaryColor = theme.colorScheme.error;
    }

    return Column(
      children: [
        // Total Summary Card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: DebtThemeUtils.getFinancialCardDecoration(context),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    isMyDebt == true
                        ? Icons.arrow_upward
                        : isMyDebt == false
                        ? Icons.arrow_downward
                        : Icons.warning,
                    color: summaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total Amount',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: summaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${debts.length} ${debts.length == 1 ? 'debt' : 'debts'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Debts List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () {
              AppLogger.userAction('Pull to refresh triggered');
              return _loadDebts();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: debts.length,
              itemBuilder: (context, index) {
                final debt = debts[index];
                return _buildDebtCard(debt, theme, financialColors);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool? isMyDebt, ThemeData theme) {
    String title;
    String subtitle;
    IconData icon;
    Color iconColor;

    if (isMyDebt == true) {
      title = 'No debts you owe';
      subtitle = 'You don\'t owe anyone money right now';
      icon = Icons.sentiment_satisfied;
      iconColor = theme.colorScheme.primary;
    } else if (isMyDebt == false) {
      title = 'No one owes you';
      subtitle = 'No one owes you money right now';
      icon = Icons.sentiment_neutral;
      iconColor = theme.colorScheme.secondary;
    } else {
      title = 'No overdue debts';
      subtitle = 'All debts are on track!';
      icon = Icons.check_circle_outline;
      iconColor = theme.colorScheme.primary;
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
              color: iconColor.withOpacity(0.6),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtCard(DebtRecordModelBackend debt, ThemeData theme, FinancialColors financialColors) {
    final isOverdue = debt.isOverdue; // Uses calculated overdue logic
    final daysDifference = debt.dueDate.difference(DateTime.now()).inDays; // Uses calculated due date
    final debtColor = debt.isMyDebt ? financialColors.debt! : financialColors.credit!;
    final debtBackgroundColor = debt.isMyDebt ? financialColors.debtBackground! : financialColors.creditBackground!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      color: theme.colorScheme.surface,
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
                  backgroundColor: debtBackgroundColor,
                  child: Text(
                    debt.contactName.isNotEmpty
                        ? debt.contactName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: debtColor,
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
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: debtBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: debtColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          debt.isMyDebt ? 'I Owe' : 'They Owe',
                          style: TextStyle(
                            color: debtColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // More options menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editDebt(debt);
                    } else if (value == 'delete') {
                      _deleteDebt(debt);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Edit',
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: theme.colorScheme.error, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Amount and Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${debt.debtAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: debtColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (debt.isPaidBack)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'PAID',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'OVERDUE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                debt.debtDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Date Information
            Row(
              children: [
                // Created Date
                Expanded(
                  child: _buildDateInfo(
                    icon: Icons.calendar_today,
                    label: 'Created',
                    date: DateFormat('MMM dd').format(debt.createdDate),
                    theme: theme,
                  ),
                ),

                // Due Date (calculated - 30 days from creation)
                Expanded(
                  child: _buildDateInfo(
                    icon: isOverdue ? Icons.warning : Icons.schedule,
                    label: 'Due Date',
                    date: DateFormat('MMM dd').format(debt.dueDate),
                    theme: theme,
                    isOverdue: isOverdue,
                  ),
                ),

                // Days Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isOverdue ? 'Overdue by' : 'Due in',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${daysDifference.abs()} ${daysDifference.abs() == 1 ? 'day' : 'days'}${isOverdue ? ' ago' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isOverdue ? theme.colorScheme.error : theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Mark as Paid Button (now working with backend API)
            if (!debt.isPaidBack)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _markDebtAsPaid(debt),
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text('Mark as Paid'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInfo({
    required IconData icon,
    required String label,
    required String date,
    required ThemeData theme,
    bool isOverdue = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: isOverdue ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isOverdue ? theme.colorScheme.error : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}