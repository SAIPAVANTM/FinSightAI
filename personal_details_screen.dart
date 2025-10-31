import 'package:finsightai/selecr_mood_screen.dart';
import 'package:flutter/material.dart';


class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({Key? key}) : super(key: key);

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {

  // App Colors
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color secondaryColor = Color(0xFF10B981);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1F2937);
  static const Color hintColor = Color(0xFF9CA3AF);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _financialGoalController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _selectedRiskTolerance;
  bool _isLoading = false;

  final List<String> _riskToleranceOptions = [
    'Conservative',
    'Moderate',
    'Aggressive',
    'Very Aggressive',
  ];

  final List<String> _financialGoals = [
    'Save for Emergency Fund',
    'Buy a House',
    'Retirement Planning',
    'Investment Growth',
    'Debt Reduction',
    'Education Fund',
    'Vacation Fund',
    'Other',
  ];

  @override
  void dispose() {
    _occupationController.dispose();
    _incomeController.dispose();
    _financialGoalController.dispose();
    super.dispose();
  }

  Future<void> _continueToMoodSelection() async {
    if (_formKey.currentState!.validate() && _selectedRiskTolerance != null) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call to save personal details
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SelectMoodScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all required fields'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    bool readOnly = false,
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
        keyboardType: keyboardType,
        validator: validator,
        onTap: onTap,
        readOnly: readOnly,
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
          suffixIcon: readOnly
              ? const Icon(Icons.keyboard_arrow_down, color: hintColor)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildRiskToleranceCard(String risk) {
    final bool isSelected = _selectedRiskTolerance == risk;
    Color cardColor;
    IconData cardIcon;

    switch (risk) {
      case 'Conservative':
        cardColor = const Color(0xFF10B981);
        cardIcon = Icons.security;
        break;
      case 'Moderate':
        cardColor = const Color(0xFF06B6D4);
        cardIcon = Icons.balance;
        break;
      case 'Aggressive':
        cardColor = const Color(0xFFF59E0B);
        cardIcon = Icons.trending_up;
        break;
      default:
        cardColor = const Color(0xFFEF4444);
        cardIcon = Icons.rocket_launch;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRiskTolerance = risk;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? cardColor.withOpacity(0.1) : surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? cardColor : Colors.grey[200]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? cardColor.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 15 : 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                cardIcon,
                color: cardColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                risk,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? cardColor : textColor,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: cardColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _showFinancialGoalPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Select Financial Goal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _financialGoals.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Icon(
                        Icons.flag_outlined,
                        color: primaryColor,
                      ),
                      title: Text(
                        _financialGoals[index],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        _financialGoalController.text = _financialGoals[index];
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Personal Details',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
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
                          Icons.person_outline,
                          color: Colors.white,
                          size: 35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'FinSightAI',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Help us personalize your financial journey',
                        style: TextStyle(
                          fontSize: 16,
                          color: hintColor,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Form Fields
                _buildCustomTextField(
                  controller: _occupationController,
                  hint: 'Occupation',
                  prefixIcon: Icons.work_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your occupation';
                    }
                    return null;
                  },
                ),

                _buildCustomTextField(
                  controller: _incomeController,
                  hint: 'Monthly Income (₹)',
                  prefixIcon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your income';
                    }
                    return null;
                  },
                ),

                _buildCustomTextField(
                  controller: _financialGoalController,
                  hint: 'Financial Goal',
                  prefixIcon: Icons.flag_outlined,
                  readOnly: true,
                  onTap: _showFinancialGoalPicker,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your financial goal';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Risk Tolerance Section
                const Text(
                  'Risk Tolerance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'How comfortable are you with investment risk?',
                  style: TextStyle(
                    fontSize: 14,
                    color: hintColor,
                  ),
                ),
                const SizedBox(height: 16),

                ..._riskToleranceOptions.map((risk) => _buildRiskToleranceCard(risk)),

                const SizedBox(height: 32),

                // Continue Button
                Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _continueToMoodSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
