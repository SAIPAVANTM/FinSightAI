import 'package:finsightai/url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';

class SelectMoodScreen extends StatefulWidget {
  const SelectMoodScreen({Key? key}) : super(key: key);

  @override
  State<SelectMoodScreen> createState() => _SelectMoodScreenState();
}

class _SelectMoodScreenState extends State<SelectMoodScreen>
    with TickerProviderStateMixin {

  // App Colors
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1F2937);
  static const Color hintColor = Color(0xFF9CA3AF);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);

  // Mood colors
  static const Color happyColor = Color(0xFF10B981);
  static const Color sadColor = Color(0xFF6366F1);
  static const Color angryColor = Color(0xFFEF4444);
  static const Color neutralColor = Color(0xFF6B7280);
  static const Color joyfulColor = Color(0xFFF59E0B);

  // API Base URL
  String baseUrl = '${Url.Urls}';

  String? _selectedMood;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<Map<String, dynamic>> _moods = [
    {
      'name': 'Happy',
      'icon': Icons.sentiment_very_satisfied,
      'color': happyColor,
      'gradient': const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'name': 'Sad',
      'icon': Icons.sentiment_dissatisfied,
      'color': sadColor,
      'gradient': const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'name': 'Angry',
      'icon': Icons.sentiment_very_dissatisfied,
      'color': angryColor,
      'gradient': const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'name': 'Joy',
      'icon': Icons.sentiment_satisfied_alt,
      'color': joyfulColor,
      'gradient': const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'name': 'Neutral',
      'icon': Icons.sentiment_neutral,
      'color': neutralColor,
      'gradient': const LinearGradient(
        colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
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

  Future<void> _saveMoodToDatabase(String mood) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add_mood'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'mood': mood,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Mood saved: ${responseData['message']}');
        // _showSuccess('Mood saved successfully!');
      } else {
        print('Failed to save mood: ${responseData['message']}');
        // Don't show error to user as this is background operation
      }
    } catch (e) {
      print('Error saving mood: ${e.toString()}');
      // Don't show error to user as this is background operation
    }
  }

  void _selectMood(String mood) {
    setState(() {
      _selectedMood = mood;
    });
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Save mood to database in background
    _saveMoodToDatabase(mood);

    // Vibration feedback
    // HapticFeedback.lightImpact();
  }

  void _proceedToHome() async {
    if (_selectedMood != null) {
      setState(() {
        _isLoading = true;
      });

      // Show success message
      _showSuccess('Welcome to FinSightAI! Your mood has been recorded.');

      // Small delay for better UX
      await Future.delayed(const Duration(milliseconds: 1500));

      setState(() {
        _isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  Widget _buildMoodCard(Map<String, dynamic> mood) {
    final bool isSelected = _selectedMood == mood['name'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: isSelected ? mood['gradient'] : null,
        color: isSelected ? null : surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.transparent : Colors.grey[200]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? mood['color'].withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: isSelected ? 15 : 10,
            offset: Offset(0, isSelected ? 5 : 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectMood(mood['name']),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : mood['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    mood['icon'],
                    size: 30,
                    color: isSelected ? Colors.white : mood['color'],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mood['name'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : textColor,
                        ),
                      ),
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Selected for today',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryColor, Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
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
                        Icons.psychology_outlined,
                        color: Colors.white,
                        size: 35,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Select Your Mood',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'How are you feeling today?\nThis helps us provide better financial insights.',
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

              const SizedBox(height: 50),

              // Mood selection
              Expanded(
                child: ListView.builder(
                  itemCount: _moods.length,
                  itemBuilder: (context, index) {
                    return _buildMoodCard(_moods[index]);
                  },
                ),
              ),

              // Continue button
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 56,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: _selectedMood != null
                      ? const LinearGradient(
                    colors: [primaryColor, Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                  color: _selectedMood != null ? null : Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _selectedMood != null
                      ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ]
                      : null,
                ),
                child: ElevatedButton(
                  onPressed: (_selectedMood != null && !_isLoading) ? _proceedToHome : null,
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
                      : Text(
                    'Continue to FinSightAI',
                    style: TextStyle(
                      color: _selectedMood != null ? Colors.white : Colors.grey[500],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}