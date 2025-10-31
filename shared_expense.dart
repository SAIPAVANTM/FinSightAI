import 'package:flutter/material.dart';

class SharedExpenseScreen extends StatefulWidget {
  const SharedExpenseScreen({Key? key}) : super(key: key);

  @override
  State<SharedExpenseScreen> createState() => _SharedExpenseScreenState();
}

class _SharedExpenseScreenState extends State<SharedExpenseScreen>
    with TickerProviderStateMixin {

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

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  final TextEditingController _expenseDescriptionController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _personNameController = TextEditingController();
  final TextEditingController _personAmountController = TextEditingController();

  final List<Map<String, dynamic>> _participants = [
    {'name': 'You', 'paid': 1000.0, 'share': 700.0, 'balance': 300.0},
    {'name': 'Asha', 'paid': 500.0, 'share': 700.0, 'balance': -200.0},
  ];

  final List<Map<String, dynamic>> _sharedExpenses = [
    {
      'id': '1',
      'title': 'Dinner at Restaurant',
      'totalAmount': 2400.0,
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'participants': [
        {'name': 'You', 'paid': 2400.0, 'share': 800.0},
        {'name': 'Rahul', 'paid': 0.0, 'share': 800.0},
        {'name': 'Priya', 'paid': 0.0, 'share': 800.0},
      ],
      'category': 'Food & Dining',
      'settledUp': false,
    },
    {
      'id': '2',
      'title': 'Uber Split',
      'totalAmount': 450.0,
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'participants': [
        {'name': 'You', 'paid': 450.0, 'share': 150.0},
        {'name': 'Asha', 'paid': 0.0, 'share': 150.0},
        {'name': 'Mike', 'paid': 0.0, 'share': 150.0},
      ],
      'category': 'Transportation',
      'settledUp': true,
    },
    {
      'id': '3',
      'title': 'Movie Tickets',
      'totalAmount': 1200.0,
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'participants': [
        {'name': 'You', 'paid': 600.0, 'share': 400.0},
        {'name': 'Asha', 'paid': 600.0, 'share': 400.0},
        {'name': 'John', 'paid': 0.0, 'share': 400.0},
      ],
      'category': 'Entertainment',
      'settledUp': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _expenseDescriptionController.dispose();
    _totalAmountController.dispose();
    _personNameController.dispose();
    _personAmountController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food & Dining':
        return errorColor;
      case 'Transportation':
        return const Color(0xFF06B6D4);
      case 'Entertainment':
        return const Color(0xFF8B5CF6);
      case 'Shopping':
        return const Color(0xFFEC4899);
      default:
        return hintColor;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food & Dining':
        return Icons.restaurant;
      case 'Transportation':
        return Icons.directions_car;
      case 'Entertainment':
        return Icons.movie;
      case 'Shopping':
        return Icons.shopping_bag;
      default:
        return Icons.receipt;
    }
  }

  void _addSharedExpense() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildAddExpenseBottomSheet(),
    );
  }

  Widget _buildAddExpenseBottomSheet() {
    final List<Map<String, String>> tempParticipants = [
      {'name': 'You', 'amount': '0'}
    ];
    String selectedCategory = 'Food & Dining';
    final categories = ['Food & Dining', 'Transportation', 'Entertainment', 'Shopping', 'Others'];

    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Add Shared Expense',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 24),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description field
                        TextField(
                          controller: _expenseDescriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText: 'e.g., Dinner at Pizza Hut',
                            prefixIcon: const Icon(Icons.description, color: primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Amount field
                        TextField(
                          controller: _totalAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Total Amount (₹)',
                            prefixIcon: const Icon(Icons.currency_rupee, color: primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Category dropdown
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            prefixIcon: const Icon(Icons.category, color: primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Row(
                                children: [
                                  Icon(
                                    _getCategoryIcon(category),
                                    color: _getCategoryColor(category),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(category),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setSheetState(() {
                              selectedCategory = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // Participants section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Participants',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setSheetState(() {
                                  tempParticipants.add({'name': '', 'amount': '0'});
                                });
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Person'),
                              style: TextButton.styleFrom(
                                foregroundColor: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Participants list
                        ...tempParticipants.asMap().entries.map((entry) {
                          final index = entry.key;
                          final participant = entry.value;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      labelText: 'Name',
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    enabled: index != 0, // "You" is not editable
                                    controller: TextEditingController(text: participant['name']),
                                    onChanged: (value) {
                                      tempParticipants[index]['name'] = value;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      labelText: 'Paid (₹)',
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                    controller: TextEditingController(text: participant['amount']),
                                    onChanged: (value) {
                                      tempParticipants[index]['amount'] = value;
                                    },
                                  ),
                                ),
                                if (index != 0) // Can't remove "You"
                                  IconButton(
                                    onPressed: () {
                                      setSheetState(() {
                                        tempParticipants.removeAt(index);
                                      });
                                    },
                                    icon: const Icon(Icons.remove_circle, color: errorColor),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Add button
                Container(
                  height: 56,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    gradient: primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_expenseDescriptionController.text.isNotEmpty &&
                          _totalAmountController.text.isNotEmpty) {

                        final totalAmount = double.parse(_totalAmountController.text);
                        final validParticipants = tempParticipants
                            .where((p) => p['name']!.isNotEmpty)
                            .toList();
                        final sharePerPerson = totalAmount / validParticipants.length;

                        final newExpense = {
                          'id': DateTime.now().millisecondsSinceEpoch.toString(),
                          'title': _expenseDescriptionController.text,
                          'totalAmount': totalAmount,
                          'date': DateTime.now(),
                          'participants': validParticipants.map((p) {
                            return {
                              'name': p['name'],
                              'paid': double.tryParse(p['amount']!) ?? 0.0,
                              'share': sharePerPerson,
                            };
                          }).toList(),
                          'category': selectedCategory,
                          'settledUp': false,
                        };

                        setState(() {
                          _sharedExpenses.insert(0, newExpense);
                        });

                        _expenseDescriptionController.clear();
                        _totalAmountController.clear();
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Shared expense added successfully!'),
                            backgroundColor: successColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Add Shared Expense',
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
        );
      },
    );
  }

  Widget _buildBalanceSummary() {
    double totalOwed = 0;
    double totalOwing = 0;

    for (var expense in _sharedExpenses) {
      if (!expense['settledUp']) {
        final yourParticipation = expense['participants'].firstWhere(
              (p) => p['name'] == 'You',
          orElse: () => {'paid': 0.0, 'share': 0.0},
        );
        final balance = yourParticipation['paid'] - yourParticipation['share'];
        if (balance > 0) {
          totalOwed += balance;
        } else {
          totalOwing += balance.abs();
        }
      }
    }

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
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balance Summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Your overall balance with friends',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'You are owed',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${totalOwed.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'You owe',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${totalOwing.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    final yourParticipation = expense['participants'].firstWhere(
          (p) => p['name'] == 'You',
      orElse: () => {'paid': 0.0, 'share': 0.0},
    );
    final yourBalance = yourParticipation['paid'] - yourParticipation['share'];

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(_slideAnimation.value, 0),
        end: Offset.zero,
      ).animate(_animationController),
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(expense['category']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(expense['category']),
                      color: _getCategoryColor(expense['category']),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense['title'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '₹${expense['totalAmount'].toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: hintColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${expense['participants'].length} people',
                              style: const TextStyle(
                                fontSize: 14,
                                color: hintColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (expense['settledUp'])
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'SETTLED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: successColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Participants breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Split Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...expense['participants'].map<Widget>((participant) {
                      final balance = participant['paid'] - participant['share'];
                      final isYou = participant['name'] == 'You';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              height: 32,
                              width: 32,
                              decoration: BoxDecoration(
                                color: isYou ? primaryColor.withOpacity(0.1) : Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  participant['name'][0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isYou ? primaryColor : hintColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    participant['name'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isYou ? primaryColor : textColor,
                                    ),
                                  ),
                                  Text(
                                    'Paid ₹${participant['paid'].toStringAsFixed(0)} • Share ₹${participant['share'].toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              balance == 0
                                  ? 'Even'
                                  : balance > 0
                                  ? 'Gets ₹${balance.toStringAsFixed(0)}'
                                  : 'Owes ₹${balance.abs().toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: balance == 0
                                    ? hintColor
                                    : balance > 0
                                    ? successColor
                                    : errorColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              if (yourBalance != 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: yourBalance > 0
                        ? successColor.withOpacity(0.1)
                        : errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: yourBalance > 0
                          ? successColor.withOpacity(0.3)
                          : errorColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        yourBalance > 0 ? Icons.trending_up : Icons.trending_down,
                        color: yourBalance > 0 ? successColor : errorColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        yourBalance > 0
                            ? 'You are owed ₹${yourBalance.toStringAsFixed(0)}'
                            : 'You owe ₹${yourBalance.abs().toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: yourBalance > 0 ? successColor : errorColor,
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
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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
          'Shared Expense',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Summary
            _buildBalanceSummary(),

            // Recent Expenses Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Recent Expenses',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Expenses List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _sharedExpenses.isEmpty
                  ? Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 48,
                        color: hintColor,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No shared expenses yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: hintColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add your first shared expense to start splitting bills',
                        style: TextStyle(
                          fontSize: 14,
                          color: hintColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
                  : Column(
                children: _sharedExpenses.map((expense) => _buildExpenseCard(expense)).toList(),
              ),
            ),

            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          gradient: primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _addSharedExpense,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
