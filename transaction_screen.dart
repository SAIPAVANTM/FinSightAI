import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finsightai/url.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
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

  // API Base URL
  String baseUrl = '${Url.Urls}';

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  late AnimationController _fabAnimationController;

  String _selectedCategory = 'Food & Dining';
  String _selectedMood = 'Happy';
  String _selectedCurrency = 'INR';
  bool _showAddTransaction = false;
  bool _isLoading = false;
  bool _isInitialLoading = true;

  String _currentUserEmail = '';
  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic>? _dashboardData;

  final List<String> _categories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Healthcare',
    'Bills & Utilities',
    'Education',
    'Travel',
    'Others',
  ];

  final List<String> _moods = ['Happy', 'Sad', 'Angry', 'Neutral', 'Joyful'];

  // Exchange rates (INR as base)
  final Map<String, double> _exchangeRates = {
    'INR': 1.0,
    'USD': 83.12,
    'EUR': 90.15,
    'GBP': 105.23,
    'AED': 22.63,
    'SGD': 61.85,
    'AUD': 54.32,
    'CAD': 61.18,
    'JPY': 0.56,
  };

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fetchCurrentUser();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  // Currency conversion helper
  double _convertToINR(double amount, String currency) {
    return amount * (_exchangeRates[currency] ?? 1.0);
  }

  // Get currency symbol
  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'AED':
        return 'د.إ';
      case 'SGD':
        return 'S\$';
      case 'AUD':
        return 'A\$';
      case 'CAD':
        return 'C\$';
      case 'JPY':
        return '¥';
      case 'INR':
      default:
        return '₹';
    }
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

  Future<void> _fetchCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/last_active_user'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _currentUserEmail = responseData['user_details']['email'];
        });
        await _fetchUserTransactions();
        await _fetchDashboardData();
      } else {
        setState(() {
          _isInitialLoading = false;
        });
        _showError('Failed to fetch user data');
      }
    } catch (e) {
      setState(() {
        _isInitialLoading = false;
      });
      _showError('Network error: ${e.toString()}');
    }
  }

  Future<void> _fetchUserTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user_transactions/$_currentUserEmail'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _transactions = List<Map<String, dynamic>>.from(responseData['transactions']);
          _isInitialLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _transactions = [];
          _isInitialLoading = false;
        });
        print('No transactions found for user: $_currentUserEmail');
      } else {
        setState(() {
          _isInitialLoading = false;
        });
        _showError('Failed to fetch transactions');
      }
    } catch (e) {
      setState(() {
        _isInitialLoading = false;
      });
      _showError('Network error: ${e.toString()}');
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user_dashboard/$_currentUserEmail'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _dashboardData = responseData;
        });
      }
    } catch (e) {
      print('Error fetching dashboard data: ${e.toString()}');
    }
  }

  Future<void> _addTransactionToAPI() async {
    if (_amountController.text.isEmpty || _descriptionController.text.isEmpty) {
      _showError('Please fill all required fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert entered amount to INR
      final enteredAmount = double.parse(_amountController.text);
      final amountInINR = _convertToINR(enteredAmount, _selectedCurrency);

      final transactionData = {
        'user_email': _currentUserEmail,
        'amount': amountInINR, // Always save as INR
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'mood': _selectedMood,
        'location': _locationController.text.isEmpty
            ? 'Current Location'
            : _locationController.text.trim(),
        'transaction_type': 'expense',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/add_transaction'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(transactionData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        // Show conversion info if not INR
        if (_selectedCurrency != 'INR') {
          _showSuccess(
              'Transaction added! ${_getCurrencySymbol(_selectedCurrency)}${enteredAmount.toStringAsFixed(2)} = ₹${amountInINR.toStringAsFixed(2)}'
          );
        } else {
          _showSuccess('Transaction added successfully!');
        }

        // Clear form
        _amountController.clear();
        _descriptionController.clear();
        _locationController.clear();
        setState(() {
          _selectedCurrency = 'INR';
        });

        // Refresh transactions
        await _fetchUserTransactions();
        await _fetchDashboardData();
      } else {
        _showError(responseData['message'] ?? 'Failed to add transaction');
      }
    } catch (e) {
      _showError('Network error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeSampleData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.post(
        Uri.parse('$baseUrl/init_sample_transactions/$_currentUserEmail'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        _showSuccess('Sample transactions added successfully!');
        await _fetchUserTransactions();
        await _fetchDashboardData();
      } else {
        _showError(responseData['message'] ?? 'Failed to add sample data');
      }
    } catch (e) {
      _showError('Network error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleAddTransaction() {
    setState(() {
      _showAddTransaction = !_showAddTransaction;
    });

    if (_showAddTransaction) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  void _showAIInsights() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transaction_stats/$_currentUserEmail'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _showAIInsightsBottomSheet(responseData);
      } else {
        _showError('Failed to fetch insights');
      }
    } catch (e) {
      _showError('Network error: ${e.toString()}');
    }
  }

  void _showAIInsightsBottomSheet(Map<String, dynamic> stats) {
    final totalExpenses = stats['total_expenses'] ?? 0.0;
    final totalIncome = stats['profile_income'] ?? 0.0;
    final savingsRate = stats['savings_rate'] ?? 0.0;
    final categoryBreakdown = List<Map<String, dynamic>>.from(stats['category_breakdown'] ?? []);
    final moodBreakdown = List<Map<String, dynamic>>.from(stats['mood_breakdown'] ?? []);

    final avgDailySpend = totalExpenses / 30;
    final mostSpentCategory = categoryBreakdown.isNotEmpty ? categoryBreakdown[0]['category'] : 'None';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        gradient: primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.psychology,
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
                            'AI Financial Insights',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'Powered by FinSightAI',
                            style: TextStyle(
                              fontSize: 14,
                              color: hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildInsightCard(
                                'Total Expenses',
                                '₹${totalExpenses.toStringAsFixed(0)}',
                                Icons.trending_down,
                                errorColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInsightCard(
                                'Savings Rate',
                                '${savingsRate.toStringAsFixed(1)}%',
                                Icons.savings,
                                savingsRate >= 20 ? successColor : warningColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _buildInsightCard(
                                'Daily Average',
                                '₹${avgDailySpend.toStringAsFixed(0)}',
                                Icons.calendar_today,
                                primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInsightCard(
                                'Monthly Income',
                                '₹${totalIncome.toStringAsFixed(0)}',
                                Icons.account_balance_wallet,
                                successColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor.withOpacity(0.1),
                                successColor.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.lightbulb, color: primaryColor, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'AI Recommendations',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              ..._getAIRecommendations(savingsRate, mostSpentCategory, avgDailySpend)
                                  .map((recommendation) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      recommendation['icon'],
                                      color: recommendation['color'],
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        recommendation['text'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: textColor,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )).toList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.close, size: 16, color: hintColor),
                          label: const Text(
                            'Close',
                            style: TextStyle(color: hintColor, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showSuccess('Detailed report generated!');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.file_download, size: 16, color: Colors.white),
                          label: const Text(
                            'Export Report',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: hintColor,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getAIRecommendations(double savingsRate, String topCategory, double avgDaily) {
    final recommendations = <Map<String, dynamic>>[];

    if (savingsRate < 10) {
      recommendations.add({
        'text': 'Your savings rate is low. Try to save at least 20% of your income for financial security.',
        'icon': Icons.warning,
        'color': errorColor,
      });
    } else if (savingsRate >= 20) {
      recommendations.add({
        'text': 'Great job! Your savings rate is healthy. Consider investing surplus in SIPs or mutual funds.',
        'icon': Icons.check_circle,
        'color': successColor,
      });
    }

    if (topCategory == 'Food & Dining') {
      recommendations.add({
        'text': 'You spend most on dining. Try cooking at home 2-3 times per week to save ₹2,000 monthly.',
        'icon': Icons.restaurant,
        'color': warningColor,
      });
    }

    if (avgDaily > 500) {
      recommendations.add({
        'text': 'Your daily spending is ₹${avgDaily.toStringAsFixed(0)}. Set a daily budget of ₹400 to reduce expenses.',
        'icon': Icons.trending_down,
        'color': primaryColor,
      });
    }

    recommendations.add({
      'text': 'Track your mood while spending. Emotional spending can impact your financial goals.',
      'icon': Icons.psychology,
      'color': const Color(0xFF8B5CF6),
    });

    return recommendations;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food & Dining':
        return const Color(0xFFEF4444);
      case 'Transportation':
        return const Color(0xFF06B6D4);
      case 'Shopping':
        return const Color(0xFFEC4899);
      case 'Entertainment':
        return const Color(0xFF8B5CF6);
      case 'Healthcare':
        return successColor;
      case 'Bills & Utilities':
        return warningColor;
      case 'Income':
        return successColor;
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
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Entertainment':
        return Icons.movie;
      case 'Healthcare':
        return Icons.health_and_safety;
      case 'Bills & Utilities':
        return Icons.receipt_long;
      case 'Income':
        return Icons.account_balance_wallet;
      default:
        return Icons.category;
    }
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final isIncome = transaction['transaction_type'] == 'income';
    final categoryColor = _getCategoryColor(transaction['category']);
    final amount = transaction['amount'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(transaction['category']),
                color: categoryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction['description'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: hintColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          transaction['location'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: hintColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getMoodColor(transaction['mood']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          transaction['mood'],
                          style: TextStyle(
                            fontSize: 12,
                            color: _getMoodColor(transaction['mood']),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(transaction['transaction_date']),
                    style: const TextStyle(
                      fontSize: 12,
                      color: hintColor,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}₹${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isIncome ? successColor : errorColor,
                  ),
                ),
                Text(
                  transaction['category'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: hintColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'Happy':
        return successColor;
      case 'Sad':
        return primaryColor;
      case 'Angry':
        return errorColor;
      case 'Joyful':
        return warningColor;
      default:
        return hintColor;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  void _showAddTransactionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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

                    const Text(
                      'Add Transaction',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Currency Selector
                            DropdownButtonFormField<String>(
                              value: _selectedCurrency,
                              decoration: InputDecoration(
                                labelText: 'Currency',
                                prefixIcon: const Icon(Icons.attach_money, color: primaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: primaryColor),
                                ),
                              ),
                              items: _exchangeRates.keys.map((currency) {
                                return DropdownMenuItem(
                                  value: currency,
                                  child: Row(
                                    children: [
                                      Text(
                                        _getCurrencySymbol(currency),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(currency),
                                      if (currency != 'INR') ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '(1 = ₹${_exchangeRates[currency]!.toStringAsFixed(2)})',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setSheetState(() {
                                  _selectedCurrency = value!;
                                });
                                setState(() {
                                  _selectedCurrency = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Amount Field with Currency Symbol
                            TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    _getCurrencySymbol(_selectedCurrency),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                                suffixIcon: _amountController.text.isNotEmpty &&
                                    _selectedCurrency != 'INR'
                                    ? Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    '≈ ₹${_convertToINR(double.tryParse(_amountController.text) ?? 0, _selectedCurrency).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: primaryColor),
                                ),
                              ),
                              onChanged: (value) {
                                setSheetState(() {});
                              },
                            ),
                            const SizedBox(height: 16),

                            // Description Field
                            TextField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: 'Description',
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

                            // Category Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                prefixIcon: const Icon(Icons.category, color: primaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: _categories.map((category) {
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
                                  _selectedCategory = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Mood Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedMood,
                              decoration: InputDecoration(
                                labelText: 'Mood',
                                prefixIcon: const Icon(Icons.mood, color: primaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: _moods.map((mood) {
                                return DropdownMenuItem(
                                  value: mood,
                                  child: Text(mood),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setSheetState(() {
                                  _selectedMood = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Location Field
                            TextField(
                              controller: _locationController,
                              decoration: InputDecoration(
                                labelText: 'Location (Optional)',
                                hintText: 'Current Location',
                                prefixIcon: const Icon(Icons.location_on, color: primaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: primaryColor),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),

                    // Add Button
                    Container(
                      height: 56,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () async {
                          await _addTransactionToAPI();
                          Navigator.pop(context);
                        },
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
                          'Add Transaction',
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
      },
    );
  }

  Widget _buildExpenseChart() {
    double currentSavings = 0;
    if (_dashboardData != null) {
      currentSavings = _dashboardData!['financial_summary']['current_savings'] ?? 0;
    }

    return Container(
      height: 180,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Savings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              if (_transactions.isEmpty)
                GestureDetector(
                  onTap: _initializeSampleData,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Add Sample Data',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Text(
            '₹${currentSavings.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: successColor,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1),
                      FlSpot(1, 3),
                      FlSpot(2, 2),
                      FlSpot(3, 4),
                      FlSpot(4, 3.5),
                      FlSpot(5, 5),
                    ],
                    isCurved: true,
                    gradient: primaryGradient,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.3),
                          primaryColor.withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Transactions',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight -
        MediaQuery.of(context).padding.top -
        kToolbarHeight -
        100;

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
          'Transactions',
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
              icon: const Icon(Icons.analytics_outlined, color: primaryColor),
              onPressed: _showAIInsights,
            ),
          ),
        ],
      ),
      body: SizedBox(
        height: availableHeight,
        child: Column(
          children: [
            _buildExpenseChart(),

            Expanded(
              child: _transactions.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first transaction or load sample data',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _initializeSampleData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Add Sample Data',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  return _buildTransactionCard(_transactions[index]);
                },
              ),
            ),
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
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddTransactionBottomSheet,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}