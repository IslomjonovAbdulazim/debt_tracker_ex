// lib/services/contacts_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/contact_model.dart';

class ContactsService {
  static const String _tokenKey = 'access_token';

  static Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      print('🔑 [CONTACTS] Retrieved token: ${token != null ? '${token.substring(0, 20)}...' : 'null'}');
      return token;
    } catch (e) {
      print('❌ [CONTACTS] Token retrieval error: $e');
      return null;
    }
  }

  static Future<List<ContactModel>> getAllContacts() async {
    try {
      print('🌐 [CONTACTS] Starting getAllContacts request');

      // Get token
      final token = await _getToken();
      if (token == null) {
        print('❌ [CONTACTS] No token available');
        throw Exception('No authentication token');
      }

      // Prepare request
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.contactsEndpoint}');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('🌐 [CONTACTS] Request URL: $url');
      print('🌐 [CONTACTS] Request headers: ${headers.keys.join(', ')}');
      print('🌐 [CONTACTS] Authorization: Bearer ${token.substring(0, 20)}...');

      // Make request
      final response = await http.get(url, headers: headers).timeout(
        ApiConfig.requestTimeout,
        onTimeout: () => throw Exception('Request timeout'),
      );

      print('📡 [CONTACTS] Response status: ${response.statusCode}');
      print('📡 [CONTACTS] Response headers: ${response.headers}');
      print('📡 [CONTACTS] Response body length: ${response.body.length}');
      print('📡 [CONTACTS] Response body: ${response.body}');

      // Handle response
      if (response.statusCode == 401) {
        print('❌ [CONTACTS] 401 Unauthorized - clearing token');
        await _clearToken();
        throw Exception('Authentication failed');
      }

      if (response.statusCode != 200) {
        print('❌ [CONTACTS] HTTP ${response.statusCode}: ${response.body}');
        throw Exception('HTTP ${response.statusCode}');
      }

      // Parse response
      dynamic responseData;
      try {
        responseData = jsonDecode(response.body);
        print('✅ [CONTACTS] JSON decoded successfully: ${responseData.runtimeType}');
      } catch (e) {
        print('❌ [CONTACTS] JSON decode error: $e');
        throw Exception('Invalid JSON response');
      }

      // Handle array response
      List<dynamic> contactsData = [];
      if (responseData is List) {
        contactsData = responseData;
        print('✅ [CONTACTS] Direct array with ${contactsData.length} items');
      } else if (responseData is Map && responseData['data'] is List) {
        contactsData = responseData['data'];
        print('✅ [CONTACTS] Wrapped array with ${contactsData.length} items');
      } else {
        print('❌ [CONTACTS] Unexpected response structure: $responseData');
        return [];
      }

      // Convert to models
      final contacts = <ContactModel>[];
      for (int i = 0; i < contactsData.length; i++) {
        try {
          final contact = ContactModel.fromJson(contactsData[i]);
          contacts.add(contact);
          print('✅ [CONTACTS] Parsed contact $i: ${contact.fullName} (${contact.id})');
        } catch (e) {
          print('❌ [CONTACTS] Failed to parse contact $i: $e');
        }
      }

      // Sort alphabetically
      contacts.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

      print('🎉 [CONTACTS] Successfully loaded ${contacts.length} contacts');
      return contacts;

    } catch (e, stackTrace) {
      print('❌ [CONTACTS] Exception in getAllContacts: $e');
      print('❌ [CONTACTS] Stack trace: $stackTrace');
      return [];
    }
  }

  static Future<Map<String, dynamic>> createContact(ContactModel contact) async {
    try {
      print('🌐 [CONTACTS] Starting createContact request');

      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token'};
      }

      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.createContactEndpoint}');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode(contact.toJson());

      print('🌐 [CONTACTS] POST URL: $url');
      print('🌐 [CONTACTS] POST headers: ${headers.keys.join(', ')}');
      print('🌐 [CONTACTS] POST body: $body');

      final response = await http.post(url, headers: headers, body: body);

      print('📡 [CONTACTS] Create response status: ${response.statusCode}');
      print('📡 [CONTACTS] Create response body: ${response.body}');

      if (response.statusCode == 401) {
        await _clearToken();
        return {'success': false, 'message': 'Authentication failed'};
      }

      dynamic responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        return {'success': false, 'message': 'Invalid response format'};
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': 'Contact created successfully',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create contact',
          'errors': responseData['errors'] ?? {},
        };
      }

    } catch (e) {
      print('❌ [CONTACTS] Create contact error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteContact(String id) async {
    try {
      print('🌐 [CONTACTS] Starting deleteContact request for ID: $id');

      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token'};
      }

      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.deleteContactEndpoint(id)}');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      print('🌐 [CONTACTS] DELETE URL: $url');

      final response = await http.delete(url, headers: headers);

      print('📡 [CONTACTS] Delete response status: ${response.statusCode}');
      print('📡 [CONTACTS] Delete response body: ${response.body}');

      if (response.statusCode == 401) {
        await _clearToken();
        return {'success': false, 'message': 'Authentication failed'};
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': 'Contact deleted successfully'};
      } else {
        dynamic responseData;
        try {
          responseData = jsonDecode(response.body);
        } catch (e) {
          responseData = {'message': 'Delete failed'};
        }
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete contact',
        };
      }

    } catch (e) {
      print('❌ [CONTACTS] Delete contact error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<void> _clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      print('🗑️ [CONTACTS] Token cleared');
    } catch (e) {
      print('❌ [CONTACTS] Token clear error: $e');
    }
  }
}