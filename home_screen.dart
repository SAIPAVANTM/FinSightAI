import 'package:finsightai/profile_screen.dart';
import 'package:finsightai/shared_expense.dart';
import 'package:finsightai/suggestions_screen.dart';
import 'package:finsightai/transaction_screen.dart';
import 'package:finsightai/url.dart';
import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'calender_screen.dart';
import 'chatbot_screen.dart';
import 'goals_screen.dart';
import 'live_map_screen.dart';
import 'menu_screen.dart';
import 'moods_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {

  // App Colors
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color secondaryColor = Color(0xFF10B981);
  static const Color accentColor = Color(0xFFF59E0B);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1F2937);
  static const Color hintColor = Color(0xFF9CA3AF);
  static const Color errorColor = Color(0xFFEF4444);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // API Base URL
  String baseUrl = '${Url.Urls}';

  int _bottomNavIndex = 0;
  bool _isBalanceVisible = true;
  bool _isLoadingData = true;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  // Financial data variables
  String _currentUserEmail = '';
  double _totalBalance = 0.0;
  double _monthlyIncome = 0.0;
  double _totalExpenses = 0.0;
  double _currentSavings = 0.0;

  final List<IconData> iconList = [
    Icons.home_outlined,
    Icons.swap_horiz_outlined,
    Icons.location_on_outlined,
    Icons.calendar_today_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fetchFinancialData();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
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

  Future<void> _fetchFinancialData() async {
    try {
      // First get current user
      final userResponse = await http.get(
        Uri.parse('$baseUrl/last_active_user'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);
        final email = userData['user_details']['email'];

        setState(() {
          _currentUserEmail = email;
          _monthlyIncome = double.parse(userData['user_details']['income'] ?? '0');
        });

        print('Current user email: $_currentUserEmail'); // Debug print

        // Only call dashboard if we have email
        if (_currentUserEmail.isNotEmpty) {
          await _fetchDashboardData();
        } else {
          print('Error: Email is empty');
          _showError('Failed to get user email');
          setState(() {
            _isLoadingData = false;
          });
        }
      } else {
        print('User API Error: ${userResponse.statusCode}');
        _showError('Failed to fetch user data');
        setState(() {
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print('Network error in _fetchFinancialData: ${e.toString()}');
      _showError('Network error: ${e.toString()}');
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      if (_currentUserEmail.isEmpty) {
        print('Error: Cannot fetch dashboard - email is empty');
        return;
      }

      print('Fetching dashboard for: $_currentUserEmail'); // Debug print

      final response = await http.get(
        Uri.parse('$baseUrl/user_dashboard/$_currentUserEmail'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Dashboard API Status: ${response.statusCode}'); // Debug print
      print('Dashboard API Response: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final dashboardData = json.decode(response.body);
        final financialSummary = dashboardData['financial_summary'];

        setState(() {
          _monthlyIncome = financialSummary['monthly_income']?.toDouble() ?? 0.0;
          _totalExpenses = financialSummary['total_expenses']?.toDouble() ?? 0.0;
          _currentSavings = financialSummary['current_savings']?.toDouble() ?? 0.0;
          _totalBalance = _currentSavings;
          _isLoadingData = false;
        });
      } else {
        print('Dashboard API Error: ${response.statusCode} - ${response.body}');
        setState(() {
          _isLoadingData = false;
        });
        _showError('Failed to fetch financial data');
      }
    } catch (e) {
      print('Network error in _fetchDashboardData: ${e.toString()}');
      setState(() {
        _isLoadingData = false;
      });
      _showError('Network error: ${e.toString()}');
    }
  }


  // Refresh data when returning from other screens
  void _onScreenResume() {
    _fetchDashboardData();
  }

  void _toggleBalanceVisibility() {
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0)}';
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            onTap();
            // Wait a bit for the new screen to load, then refresh data when user returns
            await Future.delayed(const Duration(milliseconds: 500));
            _onScreenResume();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: hintColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoadingData
            ? const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Savings',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: _toggleBalanceVisibility,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isBalanceVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isBalanceVisible ? 'Hide' : 'Show',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _isBalanceVisible
                    ? _formatCurrency(_currentSavings)
                    : '₹••••••••',
                key: ValueKey(_isBalanceVisible),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              color: secondaryColor,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Income',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _isBalanceVisible
                                ? _formatCurrency(_monthlyIncome)
                                : '₹•••••',
                            key: ValueKey('income_$_isBalanceVisible'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.arrow_upward,
                              color: errorColor,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Expense',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _isBalanceVisible
                                ? _formatCurrency(_totalExpenses)
                                : '₹••••',
                            key: ValueKey('expense_$_isBalanceVisible'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
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
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading financial data...',
              style: TextStyle(
                color: hintColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
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
        toolbarHeight: kToolbarHeight,
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
            icon: const Icon(Icons.menu, color: textColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MenuScreen()),
              );
            },
          ),
        ),
        title: const Text(
          'FinSightAI',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Container(
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
              icon: const Icon(Icons.person_outline, color: textColor),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
                // Refresh data when returning from profile
                _fetchDashboardData();
              },
            ),
          ),
          // Add refresh button
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
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
              icon: Icon(
                Icons.refresh,
                color: _isLoadingData ? hintColor : primaryColor,
              ),
              onPressed: _isLoadingData ? null : () {
                setState(() {
                  _isLoadingData = true;
                });
                _fetchDashboardData();
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100), // Space for bottom nav + FAB
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Balance Card
                _buildBalanceCard(),

                const SizedBox(height: 24),

                // Quick Actions Header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Quick Actions Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _buildQuickActionCard(
                        title: 'Fin AI',
                        icon: Icons.smart_toy_outlined,
                        color: primaryColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChatbotScreen()),
                          );
                        },
                        subtitle: 'AI Assistant',
                      ),
                      _buildQuickActionCard(
                        title: 'Transaction',
                        icon: Icons.receipt_long_outlined,
                        color: secondaryColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TransactionsScreen()),
                          );
                        },
                        subtitle: 'Add & View',
                      ),
                      _buildQuickActionCard(
                        title: 'Live Map',
                        icon: Icons.map_outlined,
                        color: accentColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LiveMapScreen()),
                          );
                        },
                        subtitle: 'Spending Map',
                      ),
                      _buildQuickActionCard(
                        title: 'Suggestions',
                        icon: Icons.lightbulb_outline,
                        color: errorColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SuggestionsScreen()),
                          );
                        },
                        subtitle: 'Smart Tips',
                      ),
                      _buildQuickActionCard(
                        title: 'Moods',
                        icon: Icons.psychology_outlined,
                        color: const Color(0xFF8B5CF6),
                        onTap: () async {
                          try {
                            // Fetch the last active user email from your Flask API
                            final response = await http.get(
                              Uri.parse('${Url.Urls}/last_active_user'),
                            );

                            if (response.statusCode == 200) {
                              final data = json.decode(response.body);
                              final userEmail = data['active_entry']['mail']; // or data['user_details']['email']

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MoodsScreen(userEmail: userEmail),
                                ),
                              );
                            } else {
                              // Handle error
                              print('Failed to fetch user email');
                            }
                          } catch (e) {
                            print('Error: $e');
                          }
                        },
                        subtitle: 'Track Feelings',
                      ),
                      _buildQuickActionCard(
                        title: 'Calendar',
                        icon: Icons.calendar_today_outlined,
                        color: const Color(0xFF06B6D4),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CalendarScreen()),
                          );
                        },
                        subtitle: 'Events & Goals',
                      ),
                      _buildQuickActionCard(
                        title: 'Goals',
                        icon: Icons.flag_outlined,
                        color: const Color(0xFF84CC16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const GoalsScreen()),
                          );
                        },
                        subtitle: 'Track Progress',
                      ),
                      _buildQuickActionCard(
                        title: 'Shared Expense',
                        icon: Icons.group_outlined,
                        color: const Color(0xFFEC4899),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SharedExpenseScreen()),
                          );
                        },
                        subtitle: 'Split Bills',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: Container(
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
            onPressed: () async {
              _fabAnimationController.forward().then((_) {
                _fabAnimationController.reverse();
              });
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TransactionsScreen()),
              );
              // Refresh data when returning from transactions
              _fetchDashboardData();
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: iconList,
        activeIndex: _bottomNavIndex,
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.softEdge,
        leftCornerRadius: 16,
        rightCornerRadius: 16,
        onTap: (index) async {
          setState(() {
            _bottomNavIndex = index;
          });

          // Navigate based on index
          switch (index) {
            case 1:
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TransactionsScreen()),
              );
              _fetchDashboardData(); // Refresh when returning
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LiveMapScreen()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalendarScreen()),
              );
              break;
          }
        },
        activeColor: primaryColor,
        inactiveColor: hintColor,
        backgroundColor: surfaceColor,
        height: 60,
      ),
    );
  }
}
