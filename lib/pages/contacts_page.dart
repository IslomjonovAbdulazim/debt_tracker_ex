import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../models/contact_model.dart';
import '../models/debt_record_model.dart';
import 'contact_details_page.dart';

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
    _loadContacts();
    searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => isLoading = true);

    try {
      final loadedContacts = await ContactModel.getAllContacts();
      setState(() {
        contacts = loadedContacts;
        filteredContacts = loadedContacts;
        isLoading = false;
      });
    }