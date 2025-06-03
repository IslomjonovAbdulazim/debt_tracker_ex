// lib/models/contact_model_backend.dart
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
  final DateTime createdDate;

  ContactModelBackend({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.createdDate,
  });

  // =============================================
  // JSON SERIALIZATION - FIXED for backend API
  // =============================================

  // FIXED: Backend expects 'name' and 'phone' fields
  Map<String, dynamic> toJson() {
    return {
      'name': fullName.trim(),
      'phone': phoneNumber.trim(),
    };
  }

  // FIXED: Backend returns 'name', 'phone', 'created_at' fields
  factory ContactModelBackend.fromJson(Map<String, dynamic> json) {
    return ContactModelBackend(
      id: json['id']?.toString() ?? '',
      fullName: json['name'] ?? '',
      phoneNumber: json['phone'] ?? '',
      createdDate: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()
      ),
    );
  }

  // =============================================
  // VALIDATION METHODS
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

  // =============================================
  // CACHE MANAGEMENT
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
  // API METHODS - FIXED for backend
  // =============================================

  // FIXED: Create contact using backend ContactCreate model
  static Future<Map<String, dynamic>> createContact(ContactModelBackend contact) async {
    try {
      AppLogger.dataOperation('CREATE', 'Contact');

      // Validate before sending
      final nameError = validateFullName(contact.fullName);
      final phoneError = validatePhoneNumber(contact.phoneNumber);

      if (nameError != null || phoneError != null) {
        return {
          'success': false,
          'message': 'Validation failed',
          'errors': {
            if (nameError != null) 'name': nameError,
            if (phoneError != null) 'phone': phoneError,
          }
        };
      }

      final response = await _apiService.post(
        ApiConfig.contactsEndpoint,
        contact.toJson(),
      );

      if (response['success'] == true) {
        clearCache();
        AppLogger.dataOperation('CREATE', 'Contact', success: true);
      }

      return response;
    } catch (e) {
      AppLogger.error('Create contact error', tag: 'CONTACT', error: e);
      return {
        'success': false,
        'message': 'Failed to create contact: $e',
      };
    }
  }

  // FIXED: Get all contacts with backend response structure
  static Future<List<ContactModelBackend>> getAllContacts({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _isCacheValid) {
        AppLogger.cache('HIT', 'Contacts', hit: true);
        return _cachedContacts!;
      }

      AppLogger.info('Fetching contacts from API', tag: 'CONTACT');

      final response = await _apiService.get(ApiConfig.contactsEndpoint);

      if (response['success'] == true) {
        // FIXED: Backend returns data.contacts array
        List<dynamic> contactsData = [];

        if (response['data'] != null && response['data']['contacts'] is List) {
          contactsData = response['data']['contacts'];
        } else if (response['data'] is List) {
          contactsData = response['data'];
        }

        final contacts = contactsData
            .map((json) => ContactModelBackend.fromJson(json))
            .toList();

        // Sort alphabetically
        contacts.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

        _updateCache(contacts);
        AppLogger.info('Retrieved ${contacts.length} contacts', tag: 'CONTACT');
        return contacts;
      }

      AppLogger.warning('Failed to get contacts: ${response['message']}', tag: 'CONTACT');
      return _cachedContacts ?? [];
    } catch (e) {
      AppLogger.error('Get contacts error', tag: 'CONTACT', error: e);
      return _cachedContacts ?? [];
    }
  }

  // FIXED: Get contact by ID
  static Future<ContactModelBackend?> getContactById(String id) async {
    try {
      AppLogger.info('Getting contact by ID: $id', tag: 'CONTACT');

      // Try cache first
      if (_isCacheValid) {
        try {
          final cached = _cachedContacts?.firstWhere((c) => c.id == id);
          if (cached != null) {
            AppLogger.cache('HIT', 'Contact-$id', hit: true);
            return cached;
          }
        } catch (e) {
          // Not found in cache
        }
      }

      final response = await _apiService.get(ApiConfig.getContactEndpoint(id));

      if (response['success'] == true && response['data'] != null) {
        final contact = ContactModelBackend.fromJson(response['data']);
        AppLogger.info('Found contact $id', tag: 'CONTACT');
        return contact;
      }

      return null;
    } catch (e) {
      AppLogger.error('Get contact by ID error', tag: 'CONTACT', error: e);
      return null;
    }
  }

  // FIXED: Update contact
  static Future<Map<String, dynamic>> updateContact(String id, ContactModelBackend contact) async {
    try {
      AppLogger.dataOperation('UPDATE', 'Contact', id: id);

      // Validate
      final nameError = validateFullName(contact.fullName);
      final phoneError = validatePhoneNumber(contact.phoneNumber);

      if (nameError != null || phoneError != null) {
        return {
          'success': false,
          'message': 'Validation failed',
          'errors': {
            if (nameError != null) 'name': nameError,
            if (phoneError != null) 'phone': phoneError,
          }
        };
      }

      final response = await _apiService.put(
        ApiConfig.updateContactEndpoint(id),
        contact.toJson(),
      );

      if (response['success'] == true) {
        clearCache();
        AppLogger.dataOperation('UPDATE', 'Contact', id: id, success: true);
      }

      return response;
    } catch (e) {
      AppLogger.error('Update contact error', tag: 'CONTACT', error: e);
      return {
        'success': false,
        'message': 'Failed to update contact: $e',
      };
    }
  }

  // FIXED: Delete contact
  static Future<Map<String, dynamic>> deleteContact(String id) async {
    try {
      AppLogger.dataOperation('DELETE', 'Contact', id: id);

      final response = await _apiService.delete(ApiConfig.deleteContactEndpoint(id));

      if (response['success'] == true) {
        clearCache();
        AppLogger.dataOperation('DELETE', 'Contact', id: id, success: true);
      }

      return response;
    } catch (e) {
      AppLogger.error('Delete contact error', tag: 'CONTACT', error: e);
      return {
        'success': false,
        'message': 'Failed to delete contact: $e',
      };
    }
  }

  // =============================================
  // CLIENT-SIDE SEARCH
  // =============================================

  static Future<List<ContactModelBackend>> searchContactsByName(String searchQuery) async {
    try {
      if (searchQuery.trim().isEmpty) {
        return getAllContacts();
      }

      AppLogger.info('Searching contacts for: "$searchQuery"', tag: 'CONTACT');

      final allContacts = await getAllContacts();
      final query = searchQuery.toLowerCase().trim();

      final filteredContacts = allContacts.where((contact) =>
      contact.fullName.toLowerCase().contains(query) ||
          contact.phoneNumber.contains(query)
      ).toList();

      AppLogger.info('Found ${filteredContacts.length} contacts matching "$searchQuery"', tag: 'CONTACT');
      return filteredContacts;
    } catch (e) {
      AppLogger.error('Search contacts error', tag: 'CONTACT', error: e);
      return [];
    }
  }

  // =============================================
  // UTILITY METHODS
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
    return 'ContactModelBackend{id: $id, fullName: $fullName, phoneNumber: $phoneNumber}';
  }
}