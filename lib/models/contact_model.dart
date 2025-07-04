// lib/models/contact_model.dart
import '../services/api_service.dart';
import '../config/api_config.dart';

class ContactModel {
  final ApiService _apiService = ApiService();

  final String id;
  final String fullName;
  final String phoneNumber;
  final DateTime createdDate;

  ContactModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.createdDate,
  });

  // JSON serialization - matching API documentation
  Map<String, dynamic> toJson() {
    return {
      'fullname': fullName.trim(),
      'phone_number': phoneNumber.trim(),
    };
  }

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullname'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      createdDate: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()
      ),
    );
  }

  // Validation methods - simple for teaching
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

  // API Methods - simplified for teaching (Create, Read, Delete only)
  static Future<Map<String, dynamic>> createContact(ContactModel contact) async {
    final apiService = ApiService();

    try {
      // Validate before sending
      final nameError = validateFullName(contact.fullName);
      final phoneError = validatePhoneNumber(contact.phoneNumber);

      if (nameError != null || phoneError != null) {
        return {
          'success': false,
          'message': 'Validation failed',
          'errors': {
            if (nameError != null) 'fullname': nameError,
            if (phoneError != null) 'phone_number': phoneError,
          }
        };
      }

      final response = await apiService.post(
        ApiConfig.createContactEndpoint,
        contact.toJson(),
      );

      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create contact: $e',
      };
    }
  }

  static Future<List<ContactModel>> getAllContacts() async {
    final apiService = ApiService();

    try {
      print('🔍 [CONTACTS] Making API call to: ${ApiConfig.contactsEndpoint}');
      final response = await apiService.get(ApiConfig.contactsEndpoint);

      print('🔍 [CONTACTS] Raw response: $response');

      // Handle 401 Unauthorized - redirect to login
      if (response['statusCode'] == 401 || response['needsLogin'] == true) {
        print('❌ [CONTACTS] 401 Unauthorized - clearing invalid token');
        await apiService.logout(); // Clear invalid token
        throw Exception('Authentication required');
      }

      List<dynamic> contactsData = [];

      // API service wraps array response as: {'success': true, 'data': [...]}
      if (response['success'] == true && response['data'] is List) {
        contactsData = response['data'] as List<dynamic>;
        print('🔍 [CONTACTS] Using success+data path, found ${contactsData.length} contacts');
      }
      else {
        print('❌ [CONTACTS] No valid data structure found!');
        print('❌ [CONTACTS] Response structure: ${response.toString()}');
        return [];
      }

      final contacts = contactsData
          .map((json) => ContactModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort alphabetically
      contacts.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

      print('✅ [CONTACTS] Successfully loaded ${contacts.length} contacts');

      return contacts;
    } catch (e, stackTrace) {
      print('❌ [CONTACTS] Exception: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> deleteContact(String id) async {
    final apiService = ApiService();

    try {
      final response = await apiService.delete(ApiConfig.deleteContactEndpoint(id));
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete contact: $e',
      };
    }
  }

  // Search functionality - client-side for simplicity
  static Future<List<ContactModel>> searchContactsByName(String searchQuery) async {
    try {
      if (searchQuery.trim().isEmpty) {
        return getAllContacts();
      }

      final allContacts = await getAllContacts();
      final query = searchQuery.toLowerCase().trim();

      final filteredContacts = allContacts.where((contact) =>
      contact.fullName.toLowerCase().contains(query) ||
          contact.phoneNumber.contains(query)
      ).toList();

      return filteredContacts;
    } catch (e) {
      return [];
    }
  }

  // Utility methods - for display purposes
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
          other is ContactModel &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ContactModel{id: $id, fullName: $fullName, phoneNumber: $phoneNumber}';
  }
}