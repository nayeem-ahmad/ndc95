import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import 'email_verification_screen.dart';

class StudentIdSignInScreen extends StatefulWidget {
  const StudentIdSignInScreen({super.key});

  @override
  State<StudentIdSignInScreen> createState() => _StudentIdSignInScreenState();
}

class _StudentIdSignInScreenState extends State<StudentIdSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _studentIdController.dispose();
    super.dispose();
  }

  String? _validateStudentId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your Student ID';
    }
    if (value.length < 3) {
      return 'Please enter a valid Student ID';
    }
    return null;
  }

  String _maskEmail(String email) {
    // Show first 2 chars and domain, mask the rest
    // Example: na****@gmail.com
    final parts = email.split('@');
    if (parts.length != 2) return email;
    
    final username = parts[0];
    final domain = parts[1];
    
    if (username.length <= 2) {
      return '${username[0]}***@$domain';
    }
    
    return '${username.substring(0, 2)}${'*' * (username.length - 2)}@$domain';
  }

  Future<void> _handleStudentIdSignIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final studentId = _studentIdController.text.trim();
      
      // Check if Student ID exists in database
      final QuerySnapshot result = await FirebaseService.firestore
          .collection('users')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (result.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Student ID not found. Please sign up first or contact admin.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
        return;
      }

      // Student ID exists, get the email
      final userData = result.docs.first.data() as Map<String, dynamic>;
      final email = userData['email'] as String?;

      if (email == null || email.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No email associated with this Student ID. Please contact admin.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show masked email and send verification code
      final maskedEmail = _maskEmail(email);
      
      if (mounted) {
        // Show dialog with masked email
        final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Student ID Found'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'We found your account!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Email address:'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email_outlined, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          maskedEmail,
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'We will send a verification code to this email address.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Send Code'),
              ),
            ],
          ),
        );

        if (confirmed != true) {
          return;
        }
      }

      // Send verification code
      await AuthService.sendVerificationCode(email);
      
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: email,
              isExistingUser: true,
              studentId: studentId, // Pass student ID to update after verification
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Sign In with Student ID'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.badge_outlined,
                    size: 64,
                    color: Colors.green.shade400,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'Enter Your Student ID',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'We\'ll verify your identity and send a code to your registered email',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Student ID Field
                TextFormField(
                  controller: _studentIdController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  validator: _validateStudentId,
                  decoration: InputDecoration(
                    labelText: 'Student ID (NDC Roll #)',
                    hintText: 'e.g., 95301023',
                    prefixIcon: const Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.green.shade400, width: 2),
                    ),
                  ),
                  onFieldSubmitted: (_) => _handleStudentIdSignIn(),
                ),
                const SizedBox(height: 32),
                
                // Continue Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleStudentIdSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade400,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.amber.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'How it works:',
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '1. Enter your Student ID\n'
                              '2. We\'ll show your masked email\n'
                              '3. Verify with code sent to email\n'
                              '4. Sign in successfully',
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Help text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Don\'t have a Student ID?',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'If you\'re a new member or don\'t have your Student ID yet, please sign up with Email or Google, or contact the admin.',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
