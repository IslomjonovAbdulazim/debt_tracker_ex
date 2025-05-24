import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ContactModel {
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

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  // Create from JSON
  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'],
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
      createdDate: DateTime.parse(json['createdDate']),
    );
  }

  // CRUD Operations - Local Database Connection

  // Create: Save new contact
  static Future<bool> createContact(ContactModel contact) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<ContactModel> contacts = await getAllContacts();
      contacts.add(contact);

      List<String> contactJsonList = contacts.map((c) => jsonEncode(c.toJson())).toList();
      return await prefs.setStringList('contacts', contactJsonList);
    } catch (e) {
      return false;
    }
  }

  // Read: Get all contacts
  static Future<List<ContactModel>> getAllContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? contactJsonList = prefs.getStringList('contacts');

      if (contactJsonList == null) return [];

      return contactJsonList
          .map((jsonStr) => ContactModel.fromJson(jsonDecode(jsonStr)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Read: Get contact by ID
  static Future<ContactModel?> getContactById(String id) async {
    try {
      List<ContactModel> contacts = await getAllContacts();
      return contacts.firstWhere((contact) => contact.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update: Update existing contact
  static Future<bool> updateContact(ContactModel updatedContact) async {
    try {
      List<ContactModel> contacts = await getAllContacts();
      int index = contacts.indexWhere((contact) => contact.id == updatedContact.id);

      if (index == -1) return false;

      contacts[index] = updatedContact;

      final prefs = await SharedPreferences.getInstance();
      List<String> contactJsonList = contacts.map((c) => jsonEncode(c.toJson())).toList();
      return await prefs.setStringList('contacts', contactJsonList);
    } catch (e) {
      return false;
    }
  }

  // Delete: Remove contact
  static Future<bool> deleteContact(String id) async {
    try {
      List<ContactModel> contacts = await getAllContacts();
      contacts.removeWhere((contact) => contact.id == id);

      final prefs = await SharedPreferences.getInstance();
      List<String> contactJsonList = contacts.map((c) => jsonEncode(c.toJson())).toList();
      return await prefs.setStringList('contacts', contactJsonList);
    } catch (e) {
      return false;
    }
  }

  // Search: Find contacts by name
  static Future<List<ContactModel>> searchContactsByName(String searchQuery) async {
    try {
      List<ContactModel> contacts = await getAllContacts();
      return contacts
          .where((contact) =>
          contact.fullName.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Clear: Delete all contacts
  static Future<bool> clearAllContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove('contacts');
    } catch (e) {
      return false;
    }
  }
}