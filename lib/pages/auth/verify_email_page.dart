// lib/pages/auth/verify_email_page.dart
import 'package:flutter/material.dart';
import '../../models/auth_model.dart';
import 'login_page.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;
  final bool isFromRegistration;
  final String? verificationCode; // ADDED: Display code in app

  const VerifyEmailPage({
    super.key,
    required this.email,
    required this.isFromRegistration,
    this.verificationCode,
  });

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _codeControllers = List.generate(
    6,
        (_) => TextEditingController(),
  );
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getCompleteCode() {
    return _codeControllers.map((c) => c.text).join();
  }

  // ADDED: Auto-fill code if provided
  void _fillCodeFromBackend() {
    if (widget.verificationCode != null && widget.verificationCode!.length == 6) {
      for (int i = 0; i < 6; i++) {
        _codeControllers[i].text = widget.verificationCode![i];
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Auto-fill code after a short delay to let UI settle
    Future.delayed(const Duration(milliseconds: 500), () {
      _fillCodeFromBackend();
    });
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    final code = _getCompleteCode();
    if (code.length != 6) {
      _showError('Please enter the complete verification code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthModel.verifyEmail(
        email: widget.email,
        code: code,
      );

      if (!mounted) return;

      if (result['success']) {
        _showSuccess('Email verified successfully!');

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
        );
      } else {
        _showError(result['message'] ?? 'Verification failed');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);

    try {
      final result = await AuthModel.resendCode(email: widget.email);

      if (!mounted) return;

      if (result['success']) {
        _showSuccess('New verification code sent to ${widget.email}');

        // Show the new code if available
        if (result['verificationCode'] != null) {
          _showCodeDialog(result['verificationCode']);
        }
      } else {
        _showError(result['message'] ?? 'Failed to resend code');
      }
    } catch (e) {
      _showError('Failed to resend code');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCodeDialog(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Verification Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your new verification code is:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Auto-fill the new code
              for (int i = 0; i < 6; i++) {
                _codeControllers[i].text = code[i];
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Icon
                Icon(
                  Icons.mark_email_unread,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Verify Your Email',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Enter the 6-digit code sent to',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Code Input Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 45,
                      child: TextFormField(
                        controller: _codeControllers[index],
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            FocusScope.of(context).nextFocus();
                          }
                          if (value.isEmpty && index > 0) {
                            FocusScope.of(context).previousFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),

                // Verify Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleVerify,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Verify Email'),
                  ),
                ),
                const SizedBox(height: 24),

                // Resend Code Button
                TextButton(
                  onPressed: _isLoading ? null : _resendCode,
                  child: const Text('Didn\'t receive the code? Resend'),
                ),

                // ADDED: Show verification code from backend
                if (widget.verificationCode != null) ...[
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Demo Verification Code',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.verificationCode!,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade600,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Code auto-filled above',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}