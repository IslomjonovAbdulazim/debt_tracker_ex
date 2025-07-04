import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/contact_model.dart';
import '../models/debt_record_model_backend.dart';
import '../config/app_theme.dart';
import '../config/app_logger.dart';

class EditDebtPage extends StatefulWidget {
  final ContactModel contact;
  final DebtRecordModelBackend debt;

  const EditDebtPage({
    super.key,
    required this.contact,
    required this.debt,
  });

  @override
  State<EditDebtPage> createState() => _EditDebtPageState();
}

class _EditDebtPageState extends State<EditDebtPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDueDate;
  late bool _isMyDebt;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing debt data
    _amountController = TextEditingController(text: widget.debt.debtAmount.toString());
    _descriptionController = TextEditingController(text: widget.debt.debtDescription);
    _selectedDueDate = widget.debt.dueDate;
    _isMyDebt = widget.debt.isMyDebt;

    AppLogger.lifecycle('EditDebtPage initialized', data: {
      'contactId': widget.contact.id,
      'contactName': widget.contact.fullName,
      'debtId': widget.debt.recordId,
      'isMyDebt': widget.debt.isMyDebt,
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    AppLogger.lifecycle('EditDebtPage disposed');
    super.dispose();
  }

  Future<void> _updateDebt() async {
    if (!_formKey.currentState!.validate()) {
      AppLogger.validation('Form', 'Validation failed');
      return;
    }

    AppLogger.userAction('Update debt initiated', context: {
      'amount': _amountController.text,
      'isMyDebt': _isMyDebt,
      'debtId': widget.debt.recordId,
    });

    setState(() => _isLoading = true);

    final stopwatch = Stopwatch()..start();

    try {
      final double amount = double.parse(_amountController.text);

      // Create updated debt record
      final updatedDebt = widget.debt.copyWith(
        debtAmount: amount,
        debtDescription: _descriptionController.text.trim(),
        dueDate: _selectedDueDate,
        isMyDebt: _isMyDebt,
      );

      final result = await DebtRecordModelBackend.updateDebtRecord(updatedDebt);

      stopwatch.stop();
      AppLogger.performance('Debt update', stopwatch.elapsed, data: {
        'success': result['success'],
        'amount': amount,
        'isMyDebt': _isMyDebt,
      });

      if (!mounted) return;

      if (result['success'] == true) {
        AppLogger.dataOperation('UPDATE', 'Debt', success: true, data: {
          'debtId': widget.debt.recordId,
          'amount': amount,
          'isMyDebt': _isMyDebt,
        });

        Navigator.pop(context, true); // Return true to indicate success

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Debt record updated successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        AppLogger.dataOperation('UPDATE', 'Debt', success: false, data: result);

        String errorMessage = result['message'] ?? 'Failed to update debt record';

        // Handle validation errors specifically
        if (result['errors'] != null && result['errors'] is Map) {
          final errors = result['errors'] as Map;
          if (errors.isNotEmpty) {
            errorMessage = errors.values.first.toString();
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Update debt error', tag: 'EDIT_DEBT', error: e);

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

  Future<void> _selectDueDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDueDate) {
      setState(() {
        _selectedDueDate = pickedDate;
      });
      AppLogger.userAction('Due date changed', context: {
        'newDate': pickedDate.toIso8601String(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final financialColors = DebtThemeUtils.getFinancialColors(context);

    final String pageTitle = 'Edit Debt Record';
    final Color themeColor = _isMyDebt ? financialColors.debt! : financialColors.credit!;
    final Color backgroundColor = _isMyDebt ? financialColors.debtBackground! : financialColors.creditBackground!;

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
                        _isMyDebt ? 'I Owe' : 'They Owe',
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

              // Debt Type Switch
              Container(
                padding: const EdgeInsets.all(20),
                decoration: DebtThemeUtils.getFinancialCardDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debt Type',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('I Owe Them'),
                            value: true,
                            groupValue: _isMyDebt,
                            onChanged: (value) {
                              setState(() {
                                _isMyDebt = value!;
                              });
                              AppLogger.userAction('Debt type changed', context: {
                                'isMyDebt': value,
                              });
                            },
                            activeColor: financialColors.debt,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('They Owe Me'),
                            value: false,
                            groupValue: _isMyDebt,
                            onChanged: (value) {
                              setState(() {
                                _isMyDebt = value!;
                              });
                              AppLogger.userAction('Debt type changed', context: {
                                'isMyDebt': value,
                              });
                            },
                            activeColor: financialColors.credit,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

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

              const SizedBox(height: 16),

              // Due Date Field
              Container(
                padding: const EdgeInsets.all(20),
                decoration: DebtThemeUtils.getFinancialCardDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Due Date',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _selectDueDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                DateFormat('MMM dd, yyyy').format(_selectedDueDate),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Update Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateDebt,
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
                      const Icon(Icons.save_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Update Debt Record',
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