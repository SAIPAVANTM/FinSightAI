import 'package:finsightai/selecr_mood_screen.dart';
import 'package:finsightai/url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  // App Colors
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1F2937);
  static const Color hintColor = Color(0xFF9CA3AF);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // API Base URL - Change this to your Flask server URL
  String baseUrl = '${Url.Urls}'; // or your server IP

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _addToActiveList(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add_active'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'mail': email,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('User added to active list: ${responseData['message']}');
      } else {
        print('Failed to add user to active list: ${responseData['message']}');
      }
    } catch (e) {
      print('Error adding to active list: ${e.toString()}');
    }
  }

  Future<void> _sendOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('$baseUrl/send_otp'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'email': _emailController.text.trim(),
          }),
        );

        final responseData = json.decode(response.body);

        if (response.statusCode == 200) {
          setState(() {
            _isOtpSent = true;
          });
          _showSuccess(responseData['message'] ?? 'OTP sent successfully!');
        } else if (response.statusCode == 404) {
          _showError(responseData['message'] ?? 'Email not found. Please sign up first.');
        } else {
          _showError(responseData['message'] ?? 'Failed to send OTP');
        }
      } catch (e) {
        _showError('Network error: ${e.toString()}');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      _showError('Please enter OTP');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify_otp'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': _emailController.text.trim(),
          'otp': _otpController.text.trim(),
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _showSuccess(responseData['message'] ?? 'Login successful!');

        // Add user to active list after successful login
        await _addToActiveList(_emailController.text.trim());

        // Navigate to mood selection
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SelectMoodScreen()),
        );
      } else {
        _showError(responseData['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      _showError('Network error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        validator: validator,
        style: const TextStyle(
          fontSize: 16,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: hintColor,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              prefixIcon,
              color: Colors.white,
              size: 20,
            ),
          ),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: hintColor,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildCustomButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isOutlined = false,
  }) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isOutlined ? null : primaryGradient,
        borderRadius: BorderRadius.circular(16),
        border: isOutlined ? Border.all(color: primaryColor, width: 2) : null,
        boxShadow: isOutlined
            ? null
            : [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Text(
          text,
          style: TextStyle(
            color: isOutlined ? primaryColor : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Header section
                Center(
                  child: Column(
                    children: [
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          gradient: primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.trending_up,
                          color: Colors.white,
                          size: 35,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'FinSightAI',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isOtpSent
                            ? 'Enter the OTP sent to your email'
                            : 'Login to continue your financial journey',
                        style: const TextStyle(
                          fontSize: 16,
                          color: hintColor,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // Input fields
                if (!_isOtpSent) ...[
                  _buildCustomTextField(
                    controller: _emailController,
                    hint: 'Email',
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  // Show email (read-only)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.email, color: primaryColor),
                        const SizedBox(width: 12),
                        Text(
                          _emailController.text,
                          style: const TextStyle(
                            fontSize: 16,
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildCustomTextField(
                    controller: _otpController,
                    hint: 'Enter 6-digit OTP',
                    prefixIcon: Icons.lock_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter OTP';
                      }
                      if (value.length != 6) {
                        return 'OTP must be 6 digits';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 8),

                // Forgot password or resend OTP
                if (_isOtpSent)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isOtpSent = false;
                            _otpController.clear();
                          });
                        },
                        child: const Text(
                          'Change Email',
                          style: TextStyle(
                            color: hintColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _sendOtp,
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 32),

                // Login button
                _buildCustomButton(
                  text: _isOtpSent ? 'Verify & Login' : 'Send OTP',
                  onPressed: _isOtpSent ? _verifyOtp : _sendOtp,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 24),

                // Continue button (for demo)
                if (!_isOtpSent)
                  _buildCustomButton(
                    text: 'Continue',
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SelectMoodScreen()),
                      );
                    },
                    isOutlined: true,
                  ),

                const SizedBox(height: 40),

                // Sign up link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: hintColor,
                          fontSize: 16,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignupScreen()),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
