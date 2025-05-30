import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/contact_model_backend.dart';
import '../models/debt_record_model_backend.dart';
import '../config/app_theme.dart';
import '../config/app_logger.dart';
import 'add_debt_page.dart';

class ContactDetailsPage extends StatefulWidget {
  final ContactModelBackend contact;

  const ContactDetailsPage({super.key, required this.contact});

  @override
  State<ContactDetailsPage> createState() => _ContactDetailsPageState();
}

class _ContactDetailsPageState extends State<ContactDetailsPage> {
  List<DebtRecordModelBackend> contactDebts = [];
  bool isLoading = true;
  double totalIOwe = 0.0;
  double totalTheyOwe = 0.0;

  @override
  void initState() {
    super.initState();
    AppLogger.lifecycle('ContactDetailsPage initialized', data: {
      'contactId': widget.contact.id,
      'contactName': widget.contact.fullName,
    });
    _loadContactDebts();
  }

  @override
  void dispose() {
    AppLogger.lifecycle('ContactDetailsPage disposed');
    super.dispose();
  }

  Future<void> _loadContactDebts() async {
    setState(() => isLoading = true);

    final stopwatch = Stopwatch()..start();
    AppLogger.info('Loading contact debts', tag: 'CONTACT_DETAIL', data: {
      'contactId': widget.contact.id,
    });

    try {
      // Use the updated API method
      final debts = await DebtRecordModelBackend.getDebtsByContactId(widget.contact.id);

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

      stopwatch.stop();
      AppLogger.performance('Contact debts load', stopwatch.elapsed, data: {
        'debtCount': debts.length,
        'totalIOwe': myTotal,
        'totalTheyOwe': theirTotal,
      });

      setState(() {
        contactDebts = debts;
        totalIOwe = myTotal;
        totalTheyOwe = theirTotal;
        isLoading = false;
      });
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to load contact debts', tag: 'CONTACT_DETAIL', error: e);

      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load contact debts: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // NOTE: Removed _markDebtAsPaid method since markAsPaidBack API doesn't exist
  // This functionality would need to be implemented differently or the API would need to support it

  void _navigateToAddDebt(bool isMyDebt) {
    AppLogger.userAction('Navigate to add debt', context: {
      'contactId': widget.contact.id,
      'isMyDebt': isMyDebt,
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDebtPage(
          contact: widget.contact,
          isMyDebt: isMyDebt,
        ),
      ),
    ).then((_) {
      AppLogger.info('Returned from add debt, refreshing contact debts', tag: 'CONTACT_DETAIL');
      _loadContactDebts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final financialColors = DebtThemeUtils.getFinancialColors(context);
    final isDarkMode = DebtThemeUtils.isDark(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(widget.contact.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              AppLogger.userAction('Manual refresh triggered');
              _loadContactDebts();
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Loading contact details...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: () {
          AppLogger.userAction('Pull to refresh triggered');
          return _loadContactDebts();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Contact Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: DebtThemeUtils.getFinancialCardDecoration(context),
                margin: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        widget.contact.fullName.isNotEmpty
                            ? widget.contact.fullName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.contact.fullName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.contact.formattedPhoneNumber,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (widget.contact.hasEmail) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.contact.email!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Debt Summary Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'I Owe Them',
                        totalIOwe,
                        financialColors.debt!,
                        Icons.arrow_upward,
                        theme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'They Owe Me',
                        totalTheyOwe,
                        financialColors.credit!,
                        Icons.arrow_downward,
                        theme,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick Add Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToAddDebt(true),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('I Owe Them'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: financialColors.debt,
                          foregroundColor: DebtThemeUtils.getContrastingTextColor(financialColors.debt!),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToAddDebt(false),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('They Owe Me'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: financialColors.credit,
                          foregroundColor: DebtThemeUtils.getContrastingTextColor(financialColors.credit!),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Debts List
              if (contactDebts.isEmpty)
                _buildEmptyDebtsState(theme)
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Debt History',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${contactDebts.length}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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
                        return _buildDebtCard(debt, theme, financialColors);
                      },
                    ),
                  ],
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DebtThemeUtils.getFinancialCardDecoration(context, borderRadius: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDebtsState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'No debts recorded',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Use the buttons above to add a debt record with ${widget.contact.fullName}',
              style: theme.textTheme.bodyMedium?.copyWith(
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
    final isOverdue = debt.isOverdue;
    final daysDifference = debt.dueDate.difference(DateTime.now()).inDays;
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
            // Header Row
            Row(
              children: [
                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

                const Spacer(),

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

                // Due Date
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
                        '${daysDifference.abs()} ${daysDifference.abs() == 1 ? 'day' : 'days'}',
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

            // NOTE: Removed "Mark as Paid" button since the API doesn't support this functionality
            // This would need to be implemented differently or the API would need to support debt updates

            const SizedBox(height: 12),

            // Info message about payment functionality
            if (!debt.isPaidBack)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mark as paid functionality will be available when the API supports debt updates',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
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