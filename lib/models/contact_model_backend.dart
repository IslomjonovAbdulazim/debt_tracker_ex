import '../services/api_service.dart';
import '../config/api_config.dart';

class ContactModelBackend {
  static final ApiService _apiService = ApiService();

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

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  // Create from JSON response
  factory ContactModelBackend.fromJson(Map<String, dynamic> json) {
    return ContactModelBackend(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone_number'] ?? '',
      createdDate: DateTime.parse(
          json['createdDate'] ?? json['created_date'] ?? json['created_at'] ?? DateTime.now().toIso8601String()
      ),
    );
  }

  // Create: Save new contact
  static Future<bool> createContact(ContactModelBackend contact) async {
    try {
      final response = await _apiService.post(
        ApiConfig.createContactEndpoint,
        {
          'fullName': contact.fullName,
          'phoneNumber': contact.phoneNumber,
        },
      );

      return response['success'] ?? false;
    } catch (e) {
      print('Create contact error: $e');
      return false;
    }
  }

  // Read: Get all contacts
  static Future<List<ContactModelBackend>> getAllContacts() async {
    try {
      final response = await _apiService.get(ApiConfig.contactsEndpoint);

      if (response['success']) {
        final List<dynamic> contactsData = response['contacts'] ?? response['data'] ?? [];
        return contactsData
            .map((json) => ContactModelBackend.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print('Get all contacts error: $e');
      return [];
    }
  }

  // Read: Get contact by ID
  static Future<ContactModelBackend?> getContactById(String id) async {
    try {
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
  static Future<bool> updateContact(ContactModelBackend updatedContact) async {
    try {
      final response = await _apiService.put(
        '${ApiConfig.updateContactEndpoint}/${updatedContact.id}',
        {
          'fullName': updatedContact.fullName,
          'phoneNumber': updatedContact.phoneNumber,
        },
      );

      return response['success'] ?? false;
    } catch (e) {
      print('Update contact error: $e');
      return false;
    }
  }

  // Delete: Remove contact
  static Future<bool> deleteContact(String id) async {
    try {
      final response = await _apiService.delete('${ApiConfig.deleteContactEndpoint}/$id');
      return response['success'] ?? false;
    } catch (e) {
      print('Delete contact error: $e');
      return false;
    }
  }

  // Search: Find contacts by name
  static Future<List<ContactModelBackend>> searchContactsByName(String searchQuery) async {
    try {
      final response = await _apiService.get(
          '${ApiConfig.searchContactsEndpoint}?q=${Uri.encodeComponent(searchQuery)}'
      );

      if (response['success']) {
        final List<dynamic> contactsData = response['contacts'] ?? response['data'] ?? [];
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
  static Future<bool> clearAllContacts() async {
    try {
      final response = await _apiService.delete(ApiConfig.contactsEndpoint);
      return response['success'] ?? false;
    } catch (e) {
      print('Clear all contacts error: $e');
      return false;
    }
  }
}