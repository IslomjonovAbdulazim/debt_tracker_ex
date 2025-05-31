import '../services/api_service.dart';
import '../config/api_config.dart';

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

  // Validation
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

  // Cache management
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
  }

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  // Create from JSON response
  factory ContactModelBackend.fromJson(Map<String, dynamic> json) {
    return ContactModelBackend(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone_number'] ?? '',
      email: json['email'],
      createdDate: DateTime.parse(
          json['createdDate'] ?? json['created_date'] ?? json['created_at'] ??
              DateTime.now().toIso8601String()
      ),
    );
  }

  // Create: Save new contact
  static Future<Map<String, dynamic>> createContact(ContactModelBackend contact) async {
    try {
      final nameError = validateFullName(contact.fullName);
      final phoneError = validatePhoneNumber(contact.phoneNumber);
      final emailError = validateEmail(contact.email);

      if (nameError != null || phoneError != null || emailError != null) {
        return {
          'success': false,
          'message': 'Validation failed',
          'errors': {
            if (nameError != null) 'fullName': nameError,
            if (phoneError != null) 'phoneNumber': phoneError,
            if (emailError != null) 'email': emailError,
          }
        };
      }

      final response = await _apiService.post(
        ApiConfig.createContactEndpoint,
        {
          'fullName': contact.fullName.trim(),
          'phoneNumber': contact.phoneNumber.trim(),
          if (contact.email != null) 'email': contact.email!.trim(),
        },
      );

      if (response['success']) {
        clearCache();
      }

      return response;
    } catch (e) {
      print('Create contact error: $e');
      return {
        'success': false,
        'message': 'Failed to create contact: $e',
      };
    }
  }

  // Read: Get all contacts with caching
  static Future<List<ContactModelBackend>> getAllContacts({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _isCacheValid) {
        return _cachedContacts!;
      }

      final response = await _apiService.get(ApiConfig.contactsEndpoint);

      if (response['success']) {
        final List<dynamic> contactsData = response['contacts'] ??
            response['data']?['contacts'] ??
            response['data'] ??
            [];

        final contacts = contactsData
            .map((json) => ContactModelBackend.fromJson(json))
            .toList();

        contacts.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

        _updateCache(contacts);
        return contacts;
      }

      return [];
    } catch (e) {
      print('Get all contacts error: $e');
      return _cachedContacts ?? [];
    }
  }

  // Read: Get contact by ID
  static Future<ContactModelBackend?> getContactById(String id) async {
    try {
      if (_isCacheValid) {
        try {
          final cached = _cachedContacts?.firstWhere((contact) => contact.id == id);
          if (cached != null) return cached;
        } catch (e) {
          // Contact not found in cache, proceed to API
        }
      }

      final response = await _apiService.get('${ApiConfig.contactsEndpoint}/$id');

      if (response['success']) {
        return ContactModelBackend.fromJson(response['contact'] ?? response['data']);
      }

      return null;
    } catch (e) {
      print('Get contact by ID error: $e');
      return null;
    }
  }

  // Update: Update existing contact
  static Future<Map<String, dynamic>> updateContact(ContactModelBackend updatedContact) async {
    try {
      final nameError = validateFullName(updatedContact.fullName);
      final phoneError = validatePhoneNumber(updatedContact.phoneNumber);
      final emailError = validateEmail(updatedContact.email);

      if (nameError != null || phoneError != null || emailError != null) {
        return {
          'success': false,
          'message': 'Validation failed',
          'errors': {
            if (nameError != null) 'fullName': nameError,
            if (phoneError != null) 'phoneNumber': phoneError,
            if (emailError != null) 'email': emailError,
          }
        };
      }

      final response = await _apiService.put(
        '${ApiConfig.updateContactEndpoint}/${updatedContact.id}',
        {
          'fullName': updatedContact.fullName.trim(),
          'phoneNumber': updatedContact.phoneNumber.trim(),
          if (updatedContact.email != null) 'email': updatedContact.email!.trim(),
        },
      );

      if (response['success']) {
        clearCache();
      }

      return response;
    } catch (e) {
      print('Update contact error: $e');
      return {
        'success': false,
        'message': 'Failed to update contact: $e',
      };
    }
  }

  // Delete: Remove contact
  static Future<Map<String, dynamic>> deleteContact(String id) async {
    try {
      final response = await _apiService.delete('${ApiConfig.deleteContactEndpoint}/$id');

      if (response['success']) {
        clearCache();
      }

      return response;
    } catch (e) {
      print('Delete contact error: $e');
      return {
        'success': false,
        'message': 'Failed to delete contact: $e',
      };
    }
  }

  // Search: Find contacts by name with caching
  static Future<List<ContactModelBackend>> searchContactsByName(String searchQuery) async {
    try {
      if (searchQuery.trim().isEmpty) {
        return getAllContacts();
      }

      if (_isCacheValid) {
        final query = searchQuery.toLowerCase().trim();
        return _cachedContacts!
            .where((contact) =>
        contact.fullName.toLowerCase().contains(query) ||
            contact.phoneNumber.contains(query) ||
            (contact.email?.toLowerCase().contains(query) ?? false))
            .toList();
      }

      final response = await _apiService.get(
          '${ApiConfig.searchContactsEndpoint}?search=${Uri.encodeComponent(searchQuery.trim())}'
      );

      if (response['success']) {
        final List<dynamic> contactsData = response['contacts'] ??
            response['data']?['contacts'] ??
            response['data'] ??
            [];
        return contactsData
            .map((json) => ContactModelBackend.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print('Search contacts error: $e');
      return [];
    }
  }

  // Clear: Delete all contacts
  static Future<Map<String, dynamic>> clearAllContacts() async {
    try {
      final response = await _apiService.delete(ApiConfig.contactsEndpoint);

      if (response['success']) {
        clearCache();
      }

      return response;
    } catch (e) {
      print('Clear all contacts error: $e');
      return {
        'success': false,
        'message': 'Failed to clear contacts: $e',
      };
    }
  }

  // Utility methods
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
    return 'ContactModelBackend{id: $id, fullName: $fullName, phoneNumber: $phoneNumber}';
  }
}