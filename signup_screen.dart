import 'package:finsightai/url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with TickerProviderStateMixin {

  // App Colors
  static const Color primaryColor = Color(0xFF6366F1);
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

  // Controllers
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _locationController = TextEditingController(); // Added location controller

  // Animation Controllers
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Form Data
  int _currentStep = 0;
  String _selectedRiskTolerance = 'Medium';
  String _selectedFinancialGoal = 'Savings';
  bool _isLoading = false;

  final List<String> _riskToleranceOptions = ['Low', 'Medium', 'High'];
  final List<String> _financialGoalOptions = [
    'Savings',
    'Investment',
    'Debt Repayment',
    'Emergency Fund',
    'Retirement',
    'Education',
    'Home Purchase',
    'Travel',
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _occupationController.dispose();
    _incomeController.dispose();
    _goalController.dispose();
    _locationController.dispose(); // Added location controller disposal
    _slideController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 7) { // Updated to 7 steps (was 6)
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _completeSignup();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_nameController.text.trim().isEmpty) {
          _showError('Please enter your full name');
          return false;
        }
        return true;
      case 1:
        if (_phoneController.text.trim().length != 10) {
          _showError('Please enter a valid 10-digit phone number');
          return false;
        }
        return true;
      case 2:
        if (!_isValidEmail(_emailController.text.trim())) {
          _showError('Please enter a valid email address');
          return false;
        }
        return true;
      case 3:
        if (_occupationController.text.trim().isEmpty) {
          _showError('Please enter your occupation');
          return false;
        }
        return true;
      case 4:
        if (_incomeController.text.trim().isEmpty) {
          _showError('Please enter your monthly income');
          return false;
        }
        return true;
      case 5:
        if (_locationController.text.trim().isEmpty) { // Added location validation
          _showError('Please enter your location');
          return false;
        }
        return true;
      case 6:
        return true; // Financial goal is selected from dropdown
      case 7:
        return true; // Risk tolerance is selected from options
      default:
        return true;
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
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

  Future<void> _completeSignup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare data for API including location
      final userData = {
        'name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'occupation': _occupationController.text.trim(),
        'income': _incomeController.text.trim(),
        'location': _locationController.text.trim(), // Added location data
        'financial_goal': _selectedFinancialGoal,
        'risk': _selectedRiskTolerance,
      };

      // Make API call
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(userData),
      );

      if (response.statusCode == 201) {
        // Success
        final responseData = json.decode(response.body);
        _showSuccess(responseData['message'] ?? 'Account created successfully!');

        // Navigate back to login screen
        Navigator.pop(context);
      } else {
        // Error
        final errorData = json.decode(response.body);
        _showError(errorData['message'] ?? 'Failed to create account');
      }
    } catch (e) {
      _showError('Network error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            children: List.generate(8, (index) { // Updated to 8 steps
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 7 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: index <= _currentStep ? primaryColor : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Step ${_currentStep + 1} of 8', // Updated to 8 steps
            style: const TextStyle(
              fontSize: 12,
              color: hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildRiskToleranceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Risk Tolerance',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: _riskToleranceOptions.map((option) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedRiskTolerance == option ? primaryColor : Colors.grey[300]!,
                  width: _selectedRiskTolerance == option ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: RadioListTile<String>(
                title: Text(
                  option,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: _selectedRiskTolerance == option ? primaryColor : textColor,
                  ),
                ),
                subtitle: Text(
                  _getRiskToleranceDescription(option),
                  style: const TextStyle(
                    fontSize: 12,
                    color: hintColor,
                  ),
                ),
                value: option,
                groupValue: _selectedRiskTolerance,
                onChanged: (value) {
                  setState(() {
                    _selectedRiskTolerance = value!;
                  });
                },
                activeColor: primaryColor,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getRiskToleranceDescription(String risk) {
    switch (risk) {
      case 'Low':
        return 'Prefer stable, low-risk investments';
      case 'Medium':
        return 'Balanced approach with moderate risk';
      case 'High':
        return 'Comfortable with high-risk, high-reward investments';
      default:
        return '';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What\'s your name?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              keyboardType: TextInputType.name,
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phone Number',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your phone number for account setup',
              style: TextStyle(
                fontSize: 14,
                color: hintColor,
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: 'Enter 10-digit phone number',
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              maxLength: 10,
              suffixIcon: const Icon(Icons.phone, color: primaryColor),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Email Address',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'Enter your email address',
              keyboardType: TextInputType.emailAddress,
              suffixIcon: const Icon(Icons.email, color: primaryColor),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Occupation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _occupationController,
              label: 'Current Occupation',
              hint: 'e.g., Software Engineer, Teacher, etc.',
              keyboardType: TextInputType.text,
              suffixIcon: const Icon(Icons.work, color: primaryColor),
            ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Income',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This helps us provide better financial insights',
              style: TextStyle(
                fontSize: 14,
                color: hintColor,
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _incomeController,
              label: 'Monthly Income (₹)',
              hint: 'Enter your monthly income',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              suffixIcon: const Icon(Icons.currency_rupee, color: primaryColor),
            ),
          ],
        );
      case 5: // New Location Step
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This helps us provide localized financial insights',
              style: TextStyle(
                fontSize: 14,
                color: hintColor,
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _locationController,
              label: 'Current Location',
              hint: 'e.g., Mumbai, Delhi, Bangalore, etc.',
              keyboardType: TextInputType.text,
              suffixIcon: const Icon(Icons.location_on, color: primaryColor),
            ),
          ],
        );
      case 6: // Updated Financial Goal (was case 5)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financial Goal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'What\'s your primary financial objective?',
              style: TextStyle(
                fontSize: 14,
                color: hintColor,
              ),
            ),
            const SizedBox(height: 32),
            _buildDropdownField(
              label: 'Primary Financial Goal',
              value: _selectedFinancialGoal,
              options: _financialGoalOptions,
              onChanged: (value) {
                setState(() {
                  _selectedFinancialGoal = value!;
                });
              },
            ),
          ],
        );
      case 7: // Updated Risk Assessment (was case 6)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Risk Assessment',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Help us understand your investment comfort level',
              style: TextStyle(
                fontSize: 14,
                color: hintColor,
              ),
            ),
            const SizedBox(height: 32),
            _buildRiskToleranceSelector(),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: surfaceColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: textColor),
            onPressed: _previousStep,
          ),
        )
            : Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: surfaceColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.close, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 8, // Updated to 8 steps
              itemBuilder: (context, index) {
                return SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildStepContent(),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  _currentStep == 7 ? 'Create Account' : 'Continue', // Updated final step
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
