import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../models/contact_model.dart';
import '../models/debt_record_model_backend.dart';
import '../config/app_theme.dart';
import '../config/app_logger.dart';
import 'contacts_detail_page.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<ContactModel> contacts = [];
  List<ContactModel> filteredContacts = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    AppLogger.lifecycle('ContactsPage initialized');
    _loadContacts();
    searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    searchController.dispose();
    AppLogger.lifecycle('ContactsPage disposed');
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => isLoading = true);

    final stopwatch = Stopwatch()..start();
    AppLogger.info('Loading contacts', tag: 'CONTACTS');

    try {
      final loadedContacts = await ContactModel.getAllContacts();

      stopwatch.stop();
      AppLogger.performance('Contacts load', stopwatch.elapsed, data: {
        'contactCount': loadedContacts.length,
      });

      setState(() {
        contacts = loadedContacts;
        filteredContacts = loadedContacts;
        isLoading = false;
      });
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to load contacts', tag: 'CONTACTS', error: e);

      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load contacts: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _filterContacts() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredContacts = contacts
          .where((contact) =>
      contact.fullName.toLowerCase().contains(query) ||
          contact.phoneNumber.contains(query))
          .toList();
    });

    AppLogger.userAction('Contacts filtered', context: {
      'query': query,
      'resultCount': filteredContacts.length,
    });
  }

  Future<void> _showAddContactDialog() async {
    AppLogger.userAction('Add contact dialog opened');
    await _showContactDialog();
  }

  // NEW: Edit contact dialog
  Future<void> _showEditContactDialog(ContactModel contact) async {
    AppLogger.userAction('Edit contact dialog opened', context: {
      'contactId': contact.id,
      'contactName': contact.fullName,
    });
    await _showContactDialog(contactToEdit: contact);
  }

  // UPDATED: Unified dialog for add/edit
  Future<void> _showContactDialog({ContactModel? contactToEdit}) async {
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: contactToEdit?.fullName ?? '');
    final phoneController = TextEditingController(text: contactToEdit?.phoneNumber ?? '');
    final isEditing = contactToEdit != null;

    final phoneMaskFormatter = MaskTextInputFormatter(
      mask: '+998 ## ### ## ##',
      filter: {"#": RegExp(r'[0-9]')},
    );

    // Set initial phone value for editing
    if (isEditing && contactToEdit!.phoneNumber.isNotEmpty) {
      phoneController.text = contactToEdit.phoneNumber;
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEditing ? 'Edit Contact' : 'Add New Contact',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(
                  Icons.person,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              inputFormatters: [phoneMaskFormatter],
              keyboardType: TextInputType.phone,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(
                  Icons.phone,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                hintText: '+998 90 123 45 67',
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              AppLogger.userAction(isEditing ? 'Edit contact cancelled' : 'Add contact cancelled');
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              AppLogger.userAction(isEditing ? 'Edit contact submit attempt' : 'Add contact submit attempt');

              // Validate using the model's validation methods
              final nameError = ContactModel.validateFullName(nameController.text);
              final phoneError = ContactModel.validatePhoneNumber(phoneController.text);

              if (nameError != null || phoneError != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(nameError ?? phoneError ?? 'Please fill all fields correctly'),
                    backgroundColor: theme.colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              final contactData = ContactModel(
                id: isEditing ? contactToEdit!.id : '', // Keep existing ID for updates
                fullName: nameController.text.trim(),
                phoneNumber: phoneController.text.trim(),
                createdDate: isEditing ? contactToEdit!.createdDate : DateTime.now(),
              );

              Map<String, dynamic> result;
              if (isEditing) {
                result = await ContactModel.updateContact(contactData);
              } else {
                result = await ContactModel.createContact(contactData);
              }

              if (result['success'] == true) {
                AppLogger.dataOperation(isEditing ? 'UPDATE' : 'CREATE', 'Contact', success: true);
                Navigator.pop(context);
                _loadContacts();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? '${isEditing ? 'Contact updated' : 'Contact added'} successfully!'),
                    backgroundColor: theme.colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                AppLogger.dataOperation(isEditing ? 'UPDATE' : 'CREATE', 'Contact', success: false, data: result);

                String errorMessage = result['message'] ?? '${isEditing ? 'Failed to update' : 'Failed to add'} contact';
                if (result['errors'] != null && result['errors'] is Map) {
                  final errors = result['errors'] as Map;
                  if (errors.isNotEmpty) {
                    errorMessage = errors.values.first.toString();
                  }
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: theme.colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(isEditing ? 'Update Contact' : 'Add Contact'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContact(ContactModel contact) async {
    AppLogger.userAction('Delete contact attempt', context: {
      'contactId': contact.id,
      'contactName': contact.fullName,
    });

    final theme = Theme.of(context);

    try {
      // Check if contact has active debts using the updated method
      final contactDebts = await DebtRecordModelBackend.getDebtsByContactId(contact.id);
      final activeDebts = contactDebts.where((debt) => !debt.isPaidBack).toList();

      if (activeDebts.isNotEmpty) {
        AppLogger.warning('Cannot delete contact with active debts', tag: 'CONTACTS', data: {
          'contactId': contact.id,
          'activeDebtsCount': activeDebts.length,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot delete ${contact.fullName} - they have ${activeDebts.length} active debt(s)'),
            backgroundColor: theme.colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete Contact',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete ${contact.fullName}?',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (contactDebts.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'This will also delete ${contactDebts.length} completed debt record(s).',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final result = await ContactModel.deleteContact(contact.id);

        if (result['success'] == true) {
          AppLogger.dataOperation('DELETE', 'Contact', success: true, data: {
            'contactId': contact.id,
          });
          _loadContacts();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Contact deleted successfully!'),
              backgroundColor: theme.colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          AppLogger.dataOperation('DELETE', 'Contact', success: false, data: result);

          String errorMessage = result['message'] ?? 'Failed to delete contact';
          if (result['errors'] != null && result['errors'] is Map) {
            final errors = result['errors'] as Map;
            if (errors.isNotEmpty) {
              errorMessage = errors.values.first.toString();
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Delete contact error', tag: 'CONTACTS', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting contact: ${e.toString()}'),
          backgroundColor: theme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.people, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Contacts'),
            if (contacts.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${contacts.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              AppLogger.userAction('Manual refresh triggered');
              _loadContacts();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    searchController.clear();
                    _filterContacts();
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Contacts List
          Expanded(
            child: isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Loading contacts...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
                : filteredContacts.isEmpty
                ? _buildEmptyState(theme)
                : RefreshIndicator(
              onRefresh: () {
                AppLogger.userAction('Pull to refresh triggered');
                return _loadContacts();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = filteredContacts[index];
                  return _buildContactCard(contact, theme);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddContactDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Contact'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              contacts.isEmpty ? Icons.people_outline : Icons.search_off,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              contacts.isEmpty ? 'No contacts yet' : 'No contacts found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              contacts.isEmpty
                  ? 'Add your first contact to get started'
                  : 'Try a different search term',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            if (contacts.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showAddContactDialog,
                icon: const Icon(Icons.person_add),
                label: const Text('Add First Contact'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(ContactModel contact, ThemeData theme) {
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
      child: InkWell(
        onTap: () {
          AppLogger.userAction('Contact tapped', context: {
            'contactId': contact.id,
            'contactName': contact.fullName,
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContactDetailsPage(contact: contact),
            ),
          ).then((_) {
            AppLogger.info('Returned from contact details, refreshing', tag: 'CONTACTS');
            _loadContacts();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  contact.fullName.isNotEmpty ? contact.fullName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Contact Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.formattedPhoneNumber,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions - UPDATED: Added edit option
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                color: theme.colorScheme.surface,
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditContactDialog(contact);
                  } else if (value == 'delete') {
                    _deleteContact(contact);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: theme.colorScheme.primary),
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
                        Icon(Icons.delete, color: theme.colorScheme.error),
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
            ],
          ),
        ),
      ),
    );
  }
}