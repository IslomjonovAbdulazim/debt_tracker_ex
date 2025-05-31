import '../services/api_service.dart';
import '../config/api_config.dart';
import '../config/app_logger.dart';

class ContactModelBackend {
  static final ApiService _apiService = ApiService();
  static List<ContactModelBackend>? _cachedContacts;
  static DateTime? _lastCacheUpdate;

  final String id;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final DateTime createdDate;

  ContactModelBackend({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.createdDate,
  });

  // =============================================
  // VALIDATION METHODS - Keep existing validation
  // =============================================

  static String? validateFullName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Full name is required';
    }
    if (name.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (name.trim().length > 50) {
      return 'Name cannot exceed 50 characters';
    }
    return null;
  }

  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Phone number is required';
    }

    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 9) {
      return 'Phone number must be at least 9 digits';
    }
    if (digitsOnly.length > 15) {
      return 'Phone number cannot exceed 15 digits';
    }
    return null;
  }

  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return null;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // =============================================
  // CACHE MANAGEMENT - Keep existing cache logic
  // =============================================

  static bool get _isCacheValid {
    if (_cachedContacts == null || _lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!).inMinutes < 5;
  }

  static void _updateCache(List<ContactModelBackend> contacts) {
    _cachedContacts = List.from(contacts);
    _lastCacheUpdate = DateTime.now();
  }

  static void clearCache() {
    _cachedContacts = null;
    _lastCacheUpdate = null;
    AppLogger.cache('CLEAR', 'Contacts');
  }

  // =============================================
  // JSON SERIALIZATION - Updated for API docs
  // =============================================

  // Convert to JSON for API requests - Updated to match API docs
  Map<String, dynamic> toJson() {
    return {
      'fullname': fullName.trim(), // API expects 'fullname'
      'phone_number': phoneNumber.trim(), // API expects 'phone_number'
      if (email != null && email!.trim().isNotEmpty) 'email': email!.trim(),
    };
  }

  // Create from JSON response - Updated based on API docs structure
  factory ContactModelBackend.fromJson(Map<String, dynamic> json) {
    return ContactModelBackend(
      id: json['id']?.toString() ?? '',
      fullName: json['fullname'] ?? '', // API returns 'fullname'
      phoneNumber: json['phone_number'] ?? '', // API returns 'phone_number'
      email: json['email'],
      createdDate: DateTime.parse(
          json['created_date'] ?? json['created_at'] ?? DateTime.now().toIso8601String()
      ),
    );
  }

  // =============================================
  // API METHODS - Updated to match actual API
  // =============================================

  // Create: Save new contact - Updated to use /contact
  static Future<Map<String, dynamic>> createContact(ContactModelBackend contact) async {
    try {
      AppLogger.dataOperation('CREATE', 'Contact', id: contact.id);

      // Validate before sending
      final nameError = validateFullName(contact.fullName);
      final phoneError = validatePhoneNumber(contact.phoneNumber);
      final emailError = validateEmail(contact.email);

      if (nameError != null || phoneError != null || emailError != null) {
        AppLogger.validation('Contact', 'Validation failed');
        return {
          'success': false,
          'message': 'Validation failed',
          'errors': {
            if (nameError != null) 'fullname': nameError,
            if (phoneError != null) 'phone_number': phoneError,
            if (emailError != null) 'email': emailError,
          }
        };
      }

      AppLogger.apiRequest('POST', ApiConfig.createContactEndpoint, data: contact.toJson());

      final response = await _apiService.post(
        ApiConfig.createContactEndpoint,
        contact.toJson(),
      );

      if (response['success']) {
        clearCache(); // Clear cache to force refresh
        AppLogger.dataOperation('CREATE', 'Contact', success: true);
      } else {
        AppLogger.dataOperation('CREATE', 'Contact', success: false);
      }

      return response;
    } catch (e) {
      AppLogger.error('Create contact error', tag: 'CONTACT', error: e);
      AppLogger.dataOperation('CREATE', 'Contact', success: false);
      return {
        'success': false,
        'message': 'Failed to create contact: $e',
      };
    }
  }

  // Read: Get all contacts - Updated to use /contacts
  static Future<List<ContactModelBackend>> getAllContacts({bool forceRefresh = false}) async {
    try {
      // Check cache first
      if (!forceRefresh && _isCacheValid) {
        AppLogger.cache('HIT', 'Contacts', hit: true);
        return _cachedContacts!;
      }

      AppLogger.info('Fetching all contacts from API', tag: 'CONTACT');
      AppLogger.cache('MISS', 'Contacts', hit: false);

      final response = await _apiService.get(ApiConfig.contactsEndpoint);

      if (response['success']) {
        // Handle different possible response structures
        List<dynamic> contactsData;

        if (response['data'] is List) {
          // Direct array response
          contactsData = response['data'];
        } else if (response['data'] is Map && response['data']['contacts'] != null) {
          // Nested in 'contacts' key
          contactsData = response['data']['contacts'];
        } else {
          // Fallback to empty array
          contactsData = [];
        }

        final contacts = contactsData
            .map((json) => ContactModelBackend.fromJson(json))
            .toList();

        // Sort contacts alphabetically
        contacts.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

        _updateCache(contacts);
        AppLogger.info('Retrieved and cached ${contacts.length} contacts', tag: 'CONTACT');
        return contacts;
      }

      AppLogger.warning('Failed to get contacts: ${response['message']}', tag: 'CONTACT');
      return _cachedContacts ?? [];
    } catch (e) {
      AppLogger.error('Get all contacts error', tag: 'CONTACT', error: e);
      // Return cached data if available, empty list otherwise
      return _cachedContacts ?? [];
    }
  }

  // Read: Get contact by ID - Client-side lookup from cached data
  static Future<ContactModelBackend?> getContactById(String id) async {
    try {
      AppLogger.info('Looking up contact by ID: $id', tag: 'CONTACT');

      // Try cache first
      if (_isCacheValid) {
        try {
          final cached = _cachedContacts?.firstWhere((contact) => contact.id == id);
          if (cached != null) {
            AppLogger.cache('HIT', 'Contact-$id', hit: true);
            return cached;
          }
        } catch (e) {
          // Contact not found in cache, proceed to API
          AppLogger.cache('MISS', 'Contact-$id', hit: false);
        }
      }

      // Refresh all contacts and try again
      final contacts = await getAllContacts(forceRefresh: true);
      try {
        final contact = contacts.firstWhere((contact) => contact.id == id);
        AppLogger.info('Found contact $id after refresh', tag: 'CONTACT');
        return contact;
      } catch (e) {
        AppLogger.warning('Contact $id not found even after refresh', tag: 'CONTACT');
        return null;
      }
    } catch (e) {
      AppLogger.error('Get contact by ID error', tag: 'CONTACT', error: e);
      return null;
    }
  }

  // =============================================
  // CLIENT-SIDE SEARCH - Since API search unclear
  // =============================================

  // Search: Find contacts by name - Client-side filtering
  static Future<List<ContactModelBackend>> searchContactsByName(String searchQuery) async {
    try {
      if (searchQuery.trim().isEmpty) {
        return getAllContacts();
      }

      AppLogger.info('Searching contacts for: "$searchQuery"', tag: 'CONTACT');

      // Get all contacts (from cache if possible)
      final allContacts = await getAllContacts();

      // Filter client-side
      final query = searchQuery.toLowerCase().trim();
      final filteredContacts = allContacts.where((contact) =>
      contact.fullName.toLowerCase().contains(query) ||
          contact.phoneNumber.contains(query) ||
          (contact.email?.toLowerCase().contains(query) ?? false)
      ).toList();

      AppLogger.info('Found ${filteredContacts.length} contacts matching "$searchQuery"', tag: 'CONTACT');
      return filteredContacts;
    } catch (e) {
      AppLogger.error('Search contacts error', tag: 'CONTACT', error: e);
      return [];
    }
  }

  // =============================================
  // REMOVED/SIMPLIFIED METHODS
  // =============================================

  // NOTE: The following methods have been removed/simplified as they don't exist in the API docs:
  // - updateContact() - No update endpoint mentioned in API docs
  // - deleteContact() - Delete endpoint mentioned but may not be implemented
  // - clearAllContacts() - No clear endpoint in API docs

  // Delete: Remove contact - Keep but mark as potentially unsupported
  static Future<Map<String, dynamic>> deleteContact(String id) async {
    try {
      AppLogger.dataOperation('DELETE', 'Contact', id: id);
      AppLogger.warning('Attempting to delete contact - endpoint may not be implemented', tag: 'CONTACT');

      final response = await _apiService.delete('${ApiConfig.deleteContactEndpoint}/$id');

      if (response['success']) {
        clearCache(); // Clear cache to force refresh
        AppLogger.dataOperation('DELETE', 'Contact', id: id, success: true);
      } else {
        AppLogger.dataOperation('DELETE', 'Contact', id: id, success: false);
      }

      return response;
    } catch (e) {
      AppLogger.error('Delete contact error', tag: 'CONTACT', error: e);
      AppLogger.dataOperation('DELETE', 'Contact', success: false);
      return {
        'success': false,
        'message': 'Failed to delete contact: $e',
      };
    }
  }

  // =============================================
  // UTILITY METHODS - Keep existing helpers
  // =============================================

  String get displayName => fullName.trim();

  String get initials {
    final names = fullName.trim().split(' ');
    if (names.isEmpty) return '?';
    if (names.length == 1) return names[0][0].toUpperCase();
    return '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
  }

  String get formattedPhoneNumber {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('+998')) {
      if (cleaned.length == 13) {
        return '+998 ${cleaned.substring(4, 6)} ${cleaned.substring(6, 9)} ${cleaned.substring(9, 11)} ${cleaned.substring(11)}';
      }
    }
    return phoneNumber;
  }

  bool get hasEmail => email != null && email!.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ContactModelBackend &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ContactModelBackend{id: $id, fullName: $fullName, phoneNumber: $phoneNumber, hasEmail: $hasEmail}';
  }
}