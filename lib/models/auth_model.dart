import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthModel {
  final String userId;
  final String email;
  final String fullName;
  final String password; // In real app, never store plain password
  final bool isVerified;
  final DateTime createdDate;

  AuthModel({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.password,
    required this.isVerified,
    required this.createdDate,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'fullName': fullName,
      'password': password,
      'isVerified': isVerified,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  // Create from JSON
  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      userId: json['userId'],
      email: json['email'],
      fullName: json['fullName'],
      password: json['password'],
      isVerified: json['isVerified'] ?? false,
      createdDate: DateTime.parse(json['createdDate']),
    );
  }

  // Simple Auth Operations - Ready for Backend Integration

  // Register new user
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Check if email already exists
      final existingUser = await getUserByEmail(email);
      if (existingUser != null) {
        return {
          'success': false,
          'message': 'Email already registered',
        };
      }

      // Create new user
      final newUser = AuthModel(
        userId: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email.toLowerCase(),
        fullName: fullName,
        password: password, // In real app, hash this
        isVerified: false,
        createdDate: DateTime.now(),
      );

      // Save user
      final prefs = await SharedPreferences.getInstance();
      List<AuthModel> users = await getAllUsers();
      users.add(newUser);

      List<String> userJsonList = users.map((u) => jsonEncode(u.toJson())).toList();
      await prefs.setStringList('users', userJsonList);

      // Generate verification code
      final verificationCode = _generateVerificationCode();
      await prefs.setString('verify_${email}', verificationCode);

      return {
        'success': true,
        'message': 'Registration successful',
        'userId': newUser.userId,
        'verificationCode': verificationCode, // In real app, send via email
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed: $e',
      };
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await getUserByEmail(email.toLowerCase());

      if (user == null) {
        return {
          'success': false,
          'message': 'Email not found',
        };
      }

      if (user.password != password) {
        return {
          'success': false,
          'message': 'Invalid password',
        };
      }

      if (!user.isVerified) {
        return {
          'success': false,
          'message': 'Please verify your email first',
          'needsVerification': true,
        };
      }

      // Save current user session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUserId', user.userId);

      return {
        'success': true,
        'message': 'Login successful',
        'user': user,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Login failed: $e',
      };
    }
  }

  // Verify email with code
  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString('verify_${email.toLowerCase()}');

      if (savedCode == null) {
        return {
          'success': false,
          'message': 'No verification code found',
        };
      }

      if (savedCode != code) {
        return {
          'success': false,
          'message': 'Invalid verification code',
        };
      }

      // Update user as verified
      final user = await getUserByEmail(email.toLowerCase());
      if (user == null) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }

      final verifiedUser = AuthModel(
        userId: user.userId,
        email: user.email,
        fullName: user.fullName,
        password: user.password,
        isVerified: true,
        createdDate: user.createdDate,
      );

      await updateUser(verifiedUser);
      await prefs.remove('verify_${email.toLowerCase()}');

      return {
        'success': true,
        'message': 'Email verified successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Verification failed: $e',
      };
    }
  }

  // Forgot password - Generate reset code
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final user = await getUserByEmail(email.toLowerCase());

      if (user == null) {
        return {
          'success': false,
          'message': 'Email not found',
        };
      }

      // Generate reset code
      final resetCode = _generateVerificationCode();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('reset_${email.toLowerCase()}', resetCode);

      return {
        'success': true,
        'message': 'Reset code sent',
        'resetCode': resetCode, // In real app, send via email
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to process request: $e',
      };
    }
  }

  // Verify reset code
  static Future<Map<String, dynamic>> verifyResetCode({
    required String email,
    required String code,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString('reset_${email.toLowerCase()}');

      if (savedCode == null) {
        return {
          'success': false,
          'message': 'No reset code found',
        };
      }

      if (savedCode != code) {
        return {
          'success': false,
          'message': 'Invalid reset code',
        };
      }

      return {
        'success': true,
        'message': 'Code verified',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Verification failed: $e',
      };
    }
  }

  // Reset password
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final user = await getUserByEmail(email.toLowerCase());

      if (user == null) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }

      // Update password
      final updatedUser = AuthModel(
        userId: user.userId,
        email: user.email,
        fullName: user.fullName,
        password: newPassword,
        isVerified: user.isVerified,
        createdDate: user.createdDate,
      );

      await updateUser(updatedUser);

      // Remove reset code
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('reset_${email.toLowerCase()}');

      return {
        'success': true,
        'message': 'Password reset successful',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Reset failed: $e',
      };
    }
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUserId');
  }

  // Get current user
  static Future<AuthModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('currentUserId');

      if (userId == null) return null;

      final users = await getAllUsers();
      return users.firstWhere((user) => user.userId == userId);
    } catch (e) {
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  // Helper Methods

  static Future<List<AuthModel>> getAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? userJsonList = prefs.getStringList('users');

      if (userJsonList == null) return [];

      return userJsonList
          .map((jsonStr) => AuthModel.fromJson(jsonDecode(jsonStr)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<AuthModel?> getUserByEmail(String email) async {
    try {
      final users = await getAllUsers();
      return users.firstWhere(
            (user) => user.email.toLowerCase() == email.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  static Future<bool> updateUser(AuthModel updatedUser) async {
    try {
      List<AuthModel> users = await getAllUsers();
      int index = users.indexWhere((user) => user.userId == updatedUser.userId);

      if (index == -1) return false;

      users[index] = updatedUser;

      final prefs = await SharedPreferences.getInstance();
      List<String> userJsonList = users.map((u) => jsonEncode(u.toJson())).toList();
      return await prefs.setStringList('users', userJsonList);
    } catch (e) {
      return false;
    }
  }

  static String _generateVerificationCode() {
    // Simple 6-digit code
    return (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
  }

  // Initialize demo data for testing
  static Future<void> initializeDemoData() async {
    try {
      // Check if demo user already exists
      final existingUser = await getUserByEmail('demo@example.com');
      if (existingUser != null) return;

      // Create demo user
      final demoUser = AuthModel(
        userId: 'demo_user_123',
        email: 'demo@example.com',
        fullName: 'Demo User',
        password: 'demo123',
        isVerified: true,
        createdDate: DateTime.now(),
      );

      // Save demo user
      final prefs = await SharedPreferences.getInstance();
      List<AuthModel> users = await getAllUsers();
      users.add(demoUser);

      List<String> userJsonList = users.map((u) => jsonEncode(u.toJson())).toList();
      await prefs.setStringList('users', userJsonList);
    } catch (e) {
      // Silently fail if demo data cannot be created
    }
  }

// Example structure for backend integration:
/*
  static Future<Map<String, dynamic>> loginWithBackend({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://your-api.com/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Save token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', data['token']);
        await prefs.setString('currentUserId', data['user']['id']);

        return {
          'success': true,
          'message': 'Login successful',
          'user': AuthModel.fromJson(data['user']),
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
  */
}