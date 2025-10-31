import 'package:flutter/material.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({Key? key}) : super(key: key);

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> with TickerProviderStateMixin {

  // App Colors
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1F2937);
  static const Color hintColor = Color(0xFF9CA3AF);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  final TextEditingController _goalTitleController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();
  final TextEditingController _currentAmountController = TextEditingController();

  final List<Map<String, dynamic>> _goals = [
    {
      'id': '1',
      'title': 'Emergency Fund',
      'target': 50000.0,
      'current': 35000.0,
      'category': 'Safety',
      'deadline': DateTime.now().add(const Duration(days: 60)),
      'color': successColor,
      'icon': Icons.security,
      'description': 'Build 6 months of expenses as emergency fund',
      'monthlyContribution': 2500.0,
    },
    {
      'id': '2',
      'title': 'Vacation Budget',
      'target': 25000.0,
      'current': 10000.0,
      'category': 'Lifestyle',
      'deadline': DateTime.now().add(const Duration(days: 120)),
      'color': const Color(0xFF06B6D4),
      'icon': Icons.flight_takeoff,
      'description': 'Dream vacation to Europe with family',
      'monthlyContribution': 3000.0,
    },
    {
      'id': '3',
      'title': 'New Laptop',
      'target': 80000.0,
      'current': 25000.0,
      'category': 'Technology',
      'deadline': DateTime.now().add(const Duration(days: 90)),
      'color': primaryColor,
      'icon': Icons.laptop_mac,
      'description': 'MacBook Pro for work and development',
      'monthlyContribution': 5000.0,
    },
    {
      'id': '4',
      'title': 'Investment Portfolio',
      'target': 100000.0,
      'current': 15000.0,
      'category': 'Investment',
      'deadline': DateTime.now().add(const Duration(days: 300)),
      'color': warningColor,
      'icon': Icons.trending_up,
      'description': 'Start building long-term investment portfolio',
      'monthlyContribution': 8000.0,
    },
  ];

  final List<Map<String, dynamic>> _achievements = [
    {
      'title': '5-day no-spend streak',
      'description': 'Completed 5 consecutive days without any unnecessary spending',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'icon': Icons.stars,
      'color': successColor,
    },
    {
      'title': 'Completed 2 goals this month',
      'description': 'Successfully achieved phone upgrade and course enrollment goals',
      'date': DateTime.now().subtract(const Duration(days: 15)),
      'icon': Icons.emoji_events,
      'color': warningColor,
    },
    {
      'title': 'Monthly savings target met',
      'description': 'Exceeded monthly savings target of ₹10,000 by 15%',
      'date': DateTime.now().subtract(const Duration(days: 30)),
      'icon': Icons.savings,
      'color': primaryColor,
    },
  ];

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    );
    _progressAnimationController.forward();
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _goalTitleController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  void _addGoal() {
    showDialog(
      context: context,
      builder: (context) => _buildAddGoalDialog(),
    );
  }

  Widget _buildAddGoalDialog() {
    String selectedCategory = 'Safety';
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 30));
    final categories = ['Safety', 'Lifestyle', 'Technology', 'Investment', 'Education', 'Health'];

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Add New Goal',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _goalTitleController,
                  decoration: InputDecoration(
                    labelText: 'Goal Title',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _targetAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Target Amount (₹)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _currentAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Current Amount (₹)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(value: category, child: Text(category));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDeadline,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 1000)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDeadline = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${selectedDeadline.day}/${selectedDeadline.month}/${selectedDeadline.year}'),
                        const Icon(Icons.calendar_today, color: primaryColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: hintColor)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () {
                  if (_goalTitleController.text.isNotEmpty && _targetAmountController.text.isNotEmpty) {
                    final newGoal = {
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': _goalTitleController.text,
                      'target': double.parse(_targetAmountController.text),
                      'current': double.tryParse(_currentAmountController.text) ?? 0.0,
                      'category': selectedCategory,
                      'deadline': selectedDeadline,
                      'color': _getCategoryColor(selectedCategory),
                      'icon': _getCategoryIcon(selectedCategory),
                      'description': 'Custom goal',
                      'monthlyContribution': 1000.0,
                    };

                    setState(() {
                      _goals.add(newGoal);
                    });

                    _goalTitleController.clear();
                    _targetAmountController.clear();
                    _currentAmountController.clear();
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Goal added successfully!'),
                        backgroundColor: successColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                },
                child: const Text('Add Goal', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Safety': return successColor;
      case 'Lifestyle': return const Color(0xFF06B6D4);
      case 'Technology': return primaryColor;
      case 'Investment': return warningColor;
      case 'Education': return const Color(0xFFEC4899);
      case 'Health': return const Color(0xFF84CC16);
      default: return hintColor;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Safety': return Icons.security;
      case 'Lifestyle': return Icons.flight_takeoff;
      case 'Technology': return Icons.laptop_mac;
      case 'Investment': return Icons.trending_up;
      case 'Education': return Icons.school;
      case 'Health': return Icons.favorite;
      default: return Icons.flag;
    }
  }

  Widget _buildProgressOverview() {
    final completedGoals = _goals.where((g) => g['current'] >= g['target']).length;
    final totalProgress = _goals.fold(0.0, (sum, goal) => sum + (goal['current'] / goal['target']).clamp(0.0, 1.0)) / _goals.length;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flag, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active Goals',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${_goals.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Completed',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$completedGoals',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall Progress',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${(totalProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final progress = (goal['current'] / goal['target']).clamp(0.0, 1.0);
    final daysLeft = goal['deadline'].difference(DateTime.now()).inDays;
    final isCompleted = progress >= 1.0;

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: goal['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        goal['icon'],
                        color: goal['color'],
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal['title'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            goal['description'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: hintColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: successColor,
                          size: 20,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${goal['current'].toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: goal['color'],
                      ),
                    ),
                    Text(
                      'of ₹${goal['target'].toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: hintColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                LinearProgressIndicator(
                  value: progress * _progressAnimation.value,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(goal['color']),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 8,
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}% complete',
                      style: const TextStyle(
                        fontSize: 14,
                        color: hintColor,
                      ),
                    ),
                    Text(
                      daysLeft > 0 ? '$daysLeft days left' : 'Overdue',
                      style: TextStyle(
                        fontSize: 14,
                        color: daysLeft > 0 ? hintColor : errorColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                if (!isCompleted) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.insights, color: goal['color'], size: 20),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Monthly Contribution',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: hintColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '₹${goal['monthlyContribution'].toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You can reach your goal 3 days early if you cut ₹150/day from shopping',
                          style: TextStyle(
                            fontSize: 12,
                            color: goal['color'],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievements() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Achievements',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),

          ..._achievements.map((achievement) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: achievement['color'].withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: achievement['color'].withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: achievement['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      achievement['icon'],
                      color: achievement['color'],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          achievement['description'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
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
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Goals',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: primaryColor),
              onPressed: _addGoal,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Overview
            _buildProgressOverview(),

            // Goals List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: _goals.map((goal) => _buildGoalCard(goal)).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Achievements
            _buildAchievements(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
