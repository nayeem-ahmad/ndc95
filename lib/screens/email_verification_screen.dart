import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import 'set_password_screen.dart';
import 'home_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final bool isExistingUser;
  final String? studentId; // Optional: if signing in via Student ID

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.isExistingUser,
    this.studentId,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String _getEnteredCode() {
    return _codeControllers.map((c) => c.text).join();
  }

  bool _isCodeComplete() {
    return _getEnteredCode().length == 6;
  }

  Future<void> _handleVerifyCode() async {
    if (!_isCodeComplete()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final code = _getEnteredCode();
      final isValid = await AuthService.verifyCode(widget.email, code);

      if (isValid && mounted) {
        // If signing in via Student ID, update the studentId field
        if (widget.studentId != null && widget.studentId!.isNotEmpty) {
          try {
            // Get current user's document
            final userQuery = await FirebaseService.firestore
                .collection('users')
                .where('email', isEqualTo: widget.email)
                .limit(1)
                .get();
            
            if (userQuery.docs.isNotEmpty) {
              final userId = userQuery.docs.first.id;
              await FirebaseService.firestore
                  .collection('users')
                  .doc(userId)
                  .update({'studentId': widget.studentId});
            }
          } catch (e) {
            // Log but don't fail the verification
            debugPrint('Error updating studentId: $e');
          }
        }
        
        if (widget.isExistingUser) {
          // Existing user - check if they have password
          try {
            await AuthService.signInExistingUser(widget.email);
            // If no exception, user doesn't have password, show error
          } catch (e) {
            if (e.toString().contains('Password required')) {
              // User has password, show password entry
              if (mounted) {
                _showPasswordDialog();
              }
              return;
            } else if (e.toString().contains('Google')) {
              // User signed up with Google
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 5),
                  ),
                );
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
              return;
            }
          }
        } else {
          // New user - navigate to set password
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => SetPasswordScreen(
                  email: widget.email,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
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

  Future<void> _showPasswordDialog() async {
    final passwordController = TextEditingController();
    bool obscureText = true;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Enter Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome back! Please enter your password to continue.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscureText,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        obscureText = !obscureText;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final password = passwordController.text;
                if (password.isEmpty) {
                  return;
                }

                try {
                  Navigator.of(context).pop(); // Close dialog
                  setState(() {
                    _isLoading = true;
                  });

                  await AuthService.signInWithPassword(
                    email: widget.email,
                    password: password,
                  );

                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
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
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleResendCode() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isResending = true;
    });

    try {
      await AuthService.resendVerificationCode(widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent!'),
            backgroundColor: Colors.green,
          ),
        );
        _startResendCountdown();
        
        // Clear existing code
        for (var controller in _codeControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
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
          _isResending = false;
        });
      }
    }
  }

  Future<void> _showCodeFromFirestore() async {
    try {
      final doc = await FirebaseService.firestore
          .collection('verificationCodes')
          .doc(widget.email.toLowerCase())
          .get();
      
      if (!doc.exists || !mounted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No verification code found in database'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      final data = doc.data();
      final code = data?['code'] ?? 'Not found';
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.developer_mode, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text('Development Mode'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your verification code:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200, width: 2),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Email: ${widget.email}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Auto-fill the code
                  for (int i = 0; i < code.length && i < 6; i++) {
                    _codeControllers[i].text = code[i];
                  }
                },
                child: const Text('Auto-Fill Code'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
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
                  Icons.mark_email_read_outlined,
                  size: 64,
                  color: Colors.green.shade400,
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Check Your Email',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Code input fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    height: 60,
                    child: TextField(
                      controller: _codeControllers[index],
                      focusNode: _focusNodes[index],
                      enabled: !_isLoading,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.blue.shade400,
                            width: 2,
                          ),
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        
                        // Auto-submit when all digits entered
                        if (_isCodeComplete()) {
                          _handleVerifyCode();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              
              // Verify button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading || !_isCodeComplete()
                      ? null
                      : _handleVerifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade400,
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
                          'Verify Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Resend code button
              Center(
                child: TextButton(
                  onPressed: _resendCountdown == 0 && !_isResending
                      ? _handleResendCode
                      : null,
                  child: _isResending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _resendCountdown > 0
                              ? 'Resend code in ${_resendCountdown}s'
                              : 'Resend Code',
                          style: TextStyle(
                            color: _resendCountdown > 0
                                ? Colors.grey
                                : Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Development helper - Show code from Firestore
              Center(
                child: OutlinedButton.icon(
                  onPressed: _showCodeFromFirestore,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,
                    side: BorderSide(color: Colors.orange.shade400, width: 1.5),
                  ),
                  icon: Icon(Icons.code, size: 18, color: Colors.orange.shade700),
                  label: const Text(
                    'Show Code (Dev Mode)',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Check your spam folder if you don\'t see the email. The code expires in 10 minutes.',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
