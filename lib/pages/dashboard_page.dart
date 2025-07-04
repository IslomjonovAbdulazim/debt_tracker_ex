import 'package:debt_tracker_ex/config/app_logger.dart';
import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../models/debt_record_model_backend.dart';
import '../models/auth_model.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'contacts_page.dart';
import 'debts_overview_page.dart';
import 'add_debt_page.dart';
import 'auth/login_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();

  double totalIOwe = 0.0;
  double totalTheyOwe = 0.0;
  int activeDebts = 0;
  int overdueCount = 0;
  int totalContacts = 0;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppLogger.lifecycle('Dashboard initialized');
    _loadDashboardData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppLogger.lifecycle('Dashboard disposed');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLogger.lifecycle('App state changed: $state');
    if (state == AppLifecycleState.resumed) {
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    final stopwatch = Stopwatch()..start();

    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    AppLogger.info('Loading dashboard data', tag: 'DASHBOARD');

    try {
      // Check authentication first
      final isLoggedIn = await AuthModel.isLoggedIn();
      if (!isLoggedIn) {
        AppLogger.warning('User not logged in, redirecting to login', tag: 'DASHBOARD');
        _navigateToLogin();
        return;
      }

      // Load dashboard data using new API methods
      final results = await Future.wait([
        _loadHomeOverview(),
        _loadContactsCount(),
      ]);

      final overviewSuccess = results[0] as bool;
      final contactsSuccess = results[1] as bool;

      stopwatch.stop();
      AppLogger.performance('Dashboard load', stopwatch.elapsed);

      if (mounted) {
        setState(() {
          isLoading = false;
          if (!overviewSuccess && !contactsSuccess) {
            errorMessage = 'Failed to load dashboard data';
            AppLogger.error('Dashboard load failed completely', tag: 'DASHBOARD');
          } else if (!overviewSuccess) {
            errorMessage = 'Could not load debt summary';
            AppLogger.warning('Overview load failed but contacts succeeded', tag: 'DASHBOARD');
          }
        });
      }
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Dashboard load error', tag: 'DASHBOARD', error: e);

      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = _getErrorMessage(e);
        });
      }
    }
  }

  Future<bool> _loadHomeOverview() async {
    try {
      AppLogger.info('Loading home overview', tag: 'DASHBOARD');

      // Use the new getHomeOverview method with correct field names
      final overview = await DebtRecordModelBackend.getHomeOverview();

      if (overview['success'] == true) {
        if (mounted) {
          setState(() {
            // FIXED: Use the correct field names from API documentation
            totalIOwe = overview['total_i_owe']?.toDouble() ?? 0.0;
            totalTheyOwe = overview['total_they_owe']?.toDouble() ?? 0.0;
            activeDebts = overview['active_debts_count'] ?? 0;
            overdueCount = overview['overdue_debts_count'] ?? 0;
          });
        }

        AppLogger.info('Home overview loaded successfully', tag: 'DASHBOARD', data: {
          'totalIOwe': totalIOwe,
          'totalTheyOwe': totalTheyOwe,
          'activeDebts': activeDebts,
          'overdueCount': overdueCount,
        });

        return true;
      } else {
        AppLogger.warning('Home overview API failed, trying fallback calculations', tag: 'DASHBOARD');
        return await _loadOverviewFallback();
      }
    } catch (e) {
      AppLogger.error('Home overview load error', tag: 'DASHBOARD', error: e);
      return await _loadOverviewFallback();
    }
  }

  Future<bool> _loadOverviewFallback() async {
    try {
      AppLogger.info('Using fallback calculations for overview', tag: 'DASHBOARD');

      // Fallback to client-side calculations using updated methods
      final results = await Future.wait([
        DebtRecordModelBackend.getTotalAmountIOwe(),
        DebtRecordModelBackend.getTotalAmountTheyOweMe(),
        DebtRecordModelBackend.getAllDebtRecords(),
        DebtRecordModelBackend.getOverdueDebts(),
      ]);

      final myDebtsAmount = results[0] as double;
      final theirDebtsAmount = results[1] as double;
      final allDebts = results[2] as List<DebtRecordModelBackend>;
      final overdueDebts = results[3] as List<DebtRecordModelBackend>;

      if (mounted) {
        setState(() {
          totalIOwe = myDebtsAmount;
          totalTheyOwe = theirDebtsAmount;
          activeDebts = allDebts.where((debt) => !debt.isPaidBack).length;
          overdueCount = overdueDebts.length;
        });
      }

      AppLogger.info('Fallback calculations completed', tag: 'DASHBOARD', data: {
        'totalIOwe': totalIOwe,
        'totalTheyOwe': totalTheyOwe,
        'activeDebts': activeDebts,
        'overdueCount': overdueCount,
      });

      return true;
    } catch (e) {
      AppLogger.error('Fallback calculations failed', tag: 'DASHBOARD', error: e);
      return false;
    }
  }

  Future<bool> _loadContactsCount() async {
    try {
      AppLogger.info('Loading contacts count', tag: 'DASHBOARD');

      final contacts = await ContactModel.getAllContacts();
      if (mounted) {
        setState(() {
          totalContacts = contacts.length;
        });
      }

      AppLogger.info('Contacts count loaded: $totalContacts', tag: 'DASHBOARD');
      return true;
    } catch (e) {
      AppLogger.error('Contacts count load error', tag: 'DASHBOARD', error: e);
      return false;
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('socketexception') || errorStr.contains('network')) {
      return 'No internet connection. Please check your network.';
    }
    if (errorStr.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return 'Session expired. Please login again.';
    }
    return 'Failed to load data. Please try again.';
  }

  void _navigateToLogin() {
    AppLogger.navigation('Dashboard', 'Login');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }

  Future<void> _showContactSelectionDialog(bool isMyDebt) async {
    try {
      AppLogger.userAction('Quick add debt initiated', context: {'isMyDebt': isMyDebt});

      setState(() => isLoading = true);
      final contacts = await ContactModel.getAllContacts();
      setState(() => isLoading = false);

      if (!mounted) return;

      if (contacts.isEmpty) {
        AppLogger.info('No contacts found, showing add contact dialog', tag: 'DASHBOARD');
        _showAddContactFirstDialog();
        return;
      }

      AppLogger.info('Showing contact selection for ${contacts.length} contacts', tag: 'DASHBOARD');
      _showContactSelectionSheet(contacts, isMyDebt);
    } catch (e) {
      setState(() => isLoading = false);
      AppLogger.error('Contact selection error', tag: 'DASHBOARD', error: e);
      _showErrorSnackBar('Failed to load contacts: ${_getErrorMessage(e)}');
    }
  }

  void _showAddContactFirstDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Contacts Found'),
        content: const Text('You need to add contacts first before creating debt records.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToContacts();
            },
            child: const Text('Add Contact'),
          ),
        ],
      ),
    );
  }

  void _showContactSelectionSheet(List<ContactModel> contacts, bool isMyDebt) {
    final financialColors = DebtThemeUtils.getFinancialColors(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                isMyDebt ? 'I Owe Money To...' : 'Someone Owes Me...',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isMyDebt
                            ? financialColors.debtBackground
                            : financialColors.creditBackground,
                        child: Text(
                          contact.fullName.isNotEmpty ? contact.fullName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: isMyDebt
                                ? financialColors.debt
                                : financialColors.credit,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        contact.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(contact.phoneNumber),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: Theme.of(context).colorScheme.outline,
                        size: 16,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToAddDebt(contact, isMyDebt);
                      },
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToContacts();
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add New Contact'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddDebt(ContactModel contact, bool isMyDebt) {
    AppLogger.navigation('Dashboard', 'AddDebt');
    AppLogger.userAction('Navigate to add debt', context: {
      'contactId': contact.id,
      'contactName': contact.fullName,
      'isMyDebt': isMyDebt,
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDebtPage(
          contact: contact,
          isMyDebt: isMyDebt,
        ),
      ),
    ).then((_) {
      AppLogger.info('Returned from add debt, refreshing dashboard', tag: 'DASHBOARD');
      _loadDashboardData();
    });
  }

  void _navigateToContacts() {
    AppLogger.navigation('Dashboard', 'Contacts');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ContactsPage()),
    ).then((_) {
      AppLogger.info('Returned from contacts, refreshing dashboard', tag: 'DASHBOARD');
      _loadDashboardData();
    });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadDashboardData,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    AppLogger.userAction('Logout initiated');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AuthModel.logout();
        AppLogger.authEvent('Logout successful');
        _navigateToLogin();
      } catch (e) {
        AppLogger.error('Logout error', tag: 'DASHBOARD', error: e);
        _showErrorSnackBar('Failed to logout: ${_getErrorMessage(e)}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text(
          'Debt Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : () {
              AppLogger.userAction('Manual refresh triggered');
              _loadDashboardData();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    const Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Loading dashboard...',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: () {
        AppLogger.userAction('Pull to refresh triggered');
        return _loadDashboardData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            _buildMoneyOverviewCards(),
            const SizedBox(height: 16),
            _buildStatusCards(),
            const SizedBox(height: 24),
            _buildQuickAddSection(),
            const SizedBox(height: 32),
            _buildNavigationActions(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 20),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                AppLogger.userAction('Error retry button pressed');
                _loadDashboardData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Financial Overview',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track and manage your debts easily',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoneyOverviewCards() {
    final financialColors = DebtThemeUtils.getFinancialColors(context);

    return Row(
      children: [
        Expanded(
          child: _buildMoneyCardWithAction(
            'I Owe',
            totalIOwe,
            financialColors.debt!,
            Icons.arrow_upward,
            0,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMoneyCardWithAction(
            'They Owe',
            totalTheyOwe,
            financialColors.credit!,
            Icons.arrow_downward,
            1,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            'Active Debts',
            activeDebts.toString(),
            Theme.of(context).colorScheme.tertiary,
            Icons.receipt_long,
            null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatusCard(
            'Overdue',
            overdueCount.toString(),
            Theme.of(context).colorScheme.error,
            Icons.warning_amber,
            2,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAddSection() {
    final financialColors = DebtThemeUtils.getFinancialColors(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: DebtThemeUtils.getFinancialCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Quick Add Debt',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Quickly record a new debt without navigating through contacts',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  onPressed: () => _showContactSelectionDialog(false),
                  icon: const Icon(Icons.add),
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
        ],
      ),
    );
  }

  Widget _buildNavigationActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More Options',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          'Manage Contacts',
          'Add, edit, or view your contacts ($totalContacts total)',
          Icons.people_outline,
          Theme.of(context).colorScheme.secondary,
          _navigateToContacts,
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          'View All Debts',
          'See all active and completed debts',
          Icons.receipt_long_outlined,
          Theme.of(context).colorScheme.tertiary,
              () {
            AppLogger.navigation('Dashboard', 'DebtsPage');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DebtsPage()),
            ).then((_) => _loadDashboardData());
          },
        ),
      ],
    );
  }

  Widget _buildMoneyCardWithAction(String title, double amount, Color color, IconData icon, int tabIndex) {
    return GestureDetector(
      onTap: () {
        AppLogger.userAction('Money card tapped', context: {'title': title, 'tabIndex': tabIndex});
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DebtsPage(initialTabIndex: tabIndex),
          ),
        ).then((_) => _loadDashboardData());
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: DebtThemeUtils.getFinancialCardDecoration(
          context,
          borderRadius: 12,
        ).copyWith(
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
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
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, Color color, IconData icon, int? tabIndex) {
    return GestureDetector(
      onTap: tabIndex != null ? () {
        AppLogger.userAction('Status card tapped', context: {'title': title, 'tabIndex': tabIndex});
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DebtsPage(initialTabIndex: tabIndex),
          ),
        ).then((_) => _loadDashboardData());
      } : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: DebtThemeUtils.getFinancialCardDecoration(
          context,
          borderRadius: 12,
        ).copyWith(
          border: tabIndex != null ? Border.all(
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (tabIndex != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Tap to view',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
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
        onTap: () {
          AppLogger.userAction('Action card tapped', context: {'title': title});
          onTap();
        },
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
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.outline,
                  size: 16
              ),
            ],
          ),
        ),
      ),
    );
  }
}