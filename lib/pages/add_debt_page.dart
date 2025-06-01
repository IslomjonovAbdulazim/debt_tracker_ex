import 'package:flutter/material.dart';
import '../models/contact_model_backend.dart';
import '../models/debt_record_model_backend.dart';
import '../config/app_theme.dart';
import '../config/app_logger.dart';

class AddDebtPage extends StatefulWidget {
  final ContactModelBackend contact;
  final bool isMyDebt;

  const AddDebtPage({
    super.key,
    required this.contact,
    required this.isMyDebt,
  });

  @override
  State<AddDebtPage> createState() => _AddDebtPageState();
}

class _AddDebtPageState extends State<AddDebtPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    AppLogger.lifecycle('AddDebtPage initialized', data: {
      'contactId': widget.contact.id,
      'contactName': widget.contact.fullName,
      'isMyDebt': widget.isMyDebt,
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    AppLogger.lifecycle('AddDebtPage disposed');
    super.dispose();
  }

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) {
      AppLogger.validation('Form', 'Validation failed');
      return;
    }

    AppLogger.userAction('Save debt initiated', context: {
      'amount': _amountController.text,
      'isMyDebt': widget.isMyDebt,
      'contactId': widget.contact.id,
    });

    setState(() => _isLoading = true);

    final stopwatch = Stopwatch()..start();

    try {
      final double amount = double.parse(_amountController.text);

      // Create debt record - backend will set creation date and ID
      final newDebt = DebtRecordModelBackend(
        recordId: '', // Will be set by API
        contactId: widget.contact.id,
        contactName: widget.contact.fullName,
        debtAmount: amount,
        debtDescription: _descriptionController.text.trim(),
        createdDate: DateTime.now(),
        isMyDebt: widget.isMyDebt,
        isPaidBack: false,
      );

      final result = await DebtRecordModelBackend.createDebtRecord(newDebt);

      stopwatch.stop();
      AppLogger.performance('Debt creation', stopwatch.elapsed, data: {
        'success': result['success'],
        'amount': amount,
        'isMyDebt': widget.isMyDebt,
      });

      if (!mounted) return;

      if (result['success'] == true) {
        AppLogger.dataOperation('CREATE', 'Debt', success: true, data: {
          'contactId': widget.contact.id,
          'amount': amount,
          'isMyDebt': widget.isMyDebt,
        });

        Navigator.pop(context, true); // Return true to indicate success

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Debt record added successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        AppLogger.dataOperation('CREATE', 'Debt', success: false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to add debt record'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Save debt error', tag: 'ADD_DEBT', error: e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final financialColors = DebtThemeUtils.getFinancialColors(context);

    final String pageTitle = widget.isMyDebt ? 'I Owe Them' : 'They Owe Me';
    final Color themeColor = widget.isMyDebt ? financialColors.debt! : financialColors.credit!;
    final Color backgroundColor = widget.isMyDebt ? financialColors.debtBackground! : financialColors.creditBackground!;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(pageTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AppLogger.userAction('Back button pressed');
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Contact Info Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: DebtThemeUtils.getFinancialCardDecoration(context),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: backgroundColor,
                      child: Text(
                        widget.contact.fullName.isNotEmpty
                            ? widget.contact.fullName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: themeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.contact.fullName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.contact.phoneNumber,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: themeColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        pageTitle,
                        style: TextStyle(
                          color: themeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Amount Field
              Container(
                padding: const EdgeInsets.all(20),
                decoration: DebtThemeUtils.getFinancialCardDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        prefixText: '\$ ',
                        prefixStyle: TextStyle(
                          color: themeColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: themeColor, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.error),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        final double? amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                        if (amount > 999999.99) {
                          return 'Amount too large';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          AppLogger.userAction('Amount input changed', context: {'length': value.length});
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Description Field
              Container(
                padding: const EdgeInsets.all(20),
                decoration: DebtThemeUtils.getFinancialCardDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'What is this debt for? (e.g., lunch, loan, etc.)',
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: themeColor, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.error),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        if (value.trim().length < 3) {
                          return 'Description must be at least 3 characters';
                        }
                        if (value.trim().length > 500) {
                          return 'Description too long (max 500 characters)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Info Card (explaining backend behavior)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: DebtThemeUtils.getFinancialCardDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'How It Works',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This debt will be recorded immediately and considered "due" after 30 days from creation. You can mark it as paid later from your debt overview or contact details.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveDebt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: DebtThemeUtils.getContrastingTextColor(themeColor),
                    disabledBackgroundColor: theme.colorScheme.onSurface.withOpacity(0.12),
                    elevation: _isLoading ? 0 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        DebtThemeUtils.getContrastingTextColor(themeColor),
                      ),
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Add Debt Record',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: DebtThemeUtils.getContrastingTextColor(themeColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel Button
              TextButton(
                onPressed: _isLoading ? null : () {
                  AppLogger.userAction('Cancel button pressed');
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Cancel',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}