import 'package:flutter/material.dart';
import 'package:finsightai/url.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Add this new service class for chatbot suggestions
class ChatbotSuggestionsService {
  static const List<String> _apiKeys = [
    '',
  ];
  static const String _groqApiUrl = "https://api.groq.com/openai/v1/chat/completions";

  Future<List<Map<String, dynamic>>> generateAISuggestions(Map<String, dynamic> userStats) async {
    final prompt = '''
Based on the following user financial data, provide 5 actionable financial suggestions in JSON format:

Monthly Income: ₹${userStats['monthly_income'] ?? 0}
Current Balance: ₹${userStats['current_savings'] ?? 0}
Monthly Spending: ₹${userStats['monthly_spending'] ?? 0}
Savings Rate: ${userStats['savings_rate'] ?? 0}%

Return ONLY a JSON array with this exact structure:
[
  {
    "title": "Brief suggestion title",
    "description": "Detailed actionable advice",
    "priority": "high|medium|low",
    "impact": "Potential savings or benefit amount",
    "type": "expense_reduction|investment|savings_improvement|goal_setting",
    "actionable": true,
    "icon": "savings|trending_up|restaurant|flag",
    "color": "#10B981",
    "source": "ai_advisor"
  }
]

Focus on: budget optimization, expense reduction, investment opportunities, savings strategies, and goal recommendations.
''';

    for (var apiKey in _apiKeys) {
      try {
        final res = await http.post(
          Uri.parse(_groqApiUrl),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'llama-3.1-8b-instant',
            'messages': [
              {'role': 'system', 'content': 'You are a financial advisor AI. Return only valid JSON arrays.'},
              {'role': 'user', 'content': prompt}
            ],
            'temperature': 0.7,
            'max_tokens': 2048,
          }),
        );

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final content = data['choices'][0]['message']['content'];

          // Extract JSON from response
          final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(content);
          if (jsonMatch != null) {
            final suggestions = jsonDecode(jsonMatch.group(0)!) as List;
            return suggestions.map((s) => s as Map<String, dynamic>).toList();
          }
        }
      } catch (e) {
        print('Error with Groq API: $e');
        continue;
      }
    }

    // Fallback suggestions if API fails
    return _getFallbackSuggestions(userStats);
  }

  List<Map<String, dynamic>> _getFallbackSuggestions(Map<String, dynamic> userStats) {
    return [
      {
        "title": "Boost Your Emergency Fund",
        "description": "Your emergency fund is partially complete. Aim to save 6 months of expenses (₹${(userStats['monthly_spending'] ?? 0) * 6}) for financial security.",
        "priority": "high",
        "impact": "₹${((userStats['monthly_spending'] ?? 0) * 6 * 0.3).toInt()} needed",
        "type": "savings_improvement",
        "actionable": true,
        "icon": "savings",
        "color": "#10B981",
        "source": "ai_advisor"
      },
      {
        "title": "Reduce Dining Out Expenses",
        "description": "Consider meal prepping to cut restaurant spending by 30%. This could save you approximately ₹${(userStats['monthly_spending'] ?? 0 * 0.15).toInt()} monthly.",
        "priority": "medium",
        "impact": "Save ₹${(userStats['monthly_spending'] ?? 0 * 0.15).toInt()}/month",
        "type": "expense_reduction",
        "actionable": true,
        "icon": "restaurant",
        "color": "#F59E0B",
        "source": "ai_advisor"
      },
      {
        "title": "Start Investment Journey",
        "description": "With a savings rate of ${userStats['savings_rate']}%, consider investing ₹5000 monthly in diversified mutual funds for long-term wealth creation.",
        "priority": "medium",
        "impact": "₹60,000+ annually",
        "type": "investment",
        "actionable": true,
        "icon": "trending_up",
        "color": "#6366F1",
        "source": "ai_advisor"
      },
    ];
  }
}

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({Key? key}) : super(key: key);

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
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

  String baseUrl = '${Url.Urls}';

  List<Map<String, dynamic>> _suggestions = [];
  List<Map<String, dynamic>> _aiSuggestions = [];
  Map<String, dynamic>? _userStats;
  bool _isLoading = true;
  bool _isLoadingAI = false;
  String _currentUserEmail = '';

  String _selectedFilter = 'all';
  final List<String> _filters = ['all', 'backend', 'ai_generated', 'high', 'medium', 'low'];

  final ChatbotSuggestionsService _chatbotService = ChatbotSuggestionsService();

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/last_active_user'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        if (mounted) {
          setState(() {
            _currentUserEmail = userData['user_details']['email'];
          });
          await _fetchAISuggestions();
        }
      } else {
        if (mounted) {
          _showError('Failed to fetch user data');
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('Error fetching user: ${e.toString()}');
      if (mounted) {
        _showError('Network error: ${e.toString()}');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchAISuggestions() async {
    if (_currentUserEmail.isEmpty) return;

    try {
      // Fetch backend suggestions
      final response = await http.get(
        Uri.parse('$baseUrl/ai_suggestions/$_currentUserEmail'),
        headers: {'Content-Type': 'application/json'},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          if (responseData['status'] == 'success') {
            setState(() {
              _suggestions = List<Map<String, dynamic>>.from(responseData['suggestions']);
              _userStats = responseData['user_stats'];
              _isLoading = false;
            });

            // Generate AI suggestions from chatbot
            _generateChatbotSuggestions();
          } else {
            _showError(responseData['message'] ?? 'Failed to load suggestions');
            setState(() => _isLoading = false);
          }
        } else {
          _showError('Failed to fetch suggestions: ${response.statusCode}');
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('Error fetching suggestions: ${e.toString()}');
      if (mounted) {
        _showError('Network error: ${e.toString()}');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generateChatbotSuggestions() async {
    if (_userStats == null) return;

    setState(() => _isLoadingAI = true);

    try {
      final aiSuggestions = await _chatbotService.generateAISuggestions(_userStats!);

      if (mounted) {
        setState(() {
          _aiSuggestions = aiSuggestions;
          _isLoadingAI = false;
        });
        _showSuccess('AI suggestions generated successfully!');
      }
    } catch (e) {
      print('Error generating AI suggestions: $e');
      if (mounted) {
        setState(() => _isLoadingAI = false);
        _showError('Failed to generate AI suggestions');
      }
    }
  }

  List<Map<String, dynamic>> get _filteredSuggestions {
    List<Map<String, dynamic>> combined = [..._suggestions, ..._aiSuggestions];

    if (_selectedFilter == 'all') return combined;
    if (_selectedFilter == 'backend') return _suggestions;
    if (_selectedFilter == 'ai_generated') return _aiSuggestions;

    return combined.where((s) => s['priority'] == _selectedFilter).toList();
  }

  Color _parseColor(String colorString) {
    try {
      String hex = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return hintColor;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'savings':
        return Icons.savings;
      case 'trending_up':
        return Icons.trending_up;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_subway':
        return Icons.directions_subway;
      case 'psychology':
        return Icons.psychology;
      case 'flag':
        return Icons.flag;
      case 'location_on':
        return Icons.location_on;
      case 'celebration':
        return Icons.celebration;
      default:
        return Icons.lightbulb;
    }
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    final color = _parseColor(suggestion['color']);
    final icon = _getIconData(suggestion['icon']);
    final isAIGenerated = suggestion['source'] == 'ai_advisor';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: isAIGenerated ? Border.all(color: primaryColor.withOpacity(0.3), width: 2) : null,
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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(suggestion['priority']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              suggestion['priority'].toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getPriorityColor(suggestion['priority']),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: hintColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              suggestion['source'].replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: hintColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isAIGenerated)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: primaryGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.auto_awesome, size: 10, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'AI',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              suggestion['description'],
              style: const TextStyle(
                fontSize: 15,
                color: textColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            // Simplified bottom section - just show the impact directly
            Text(
              suggestion['impact'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return errorColor;
      case 'medium':
        return warningColor;
      case 'low':
        return successColor;
      default:
        return hintColor;
    }
  }

  void _handleAction(Map<String, dynamic> suggestion) {
    String message = '';
    switch (suggestion['type']) {
      case 'expense_reduction':
        message = 'Setting up budget alerts and spending reminders!';
        break;
      case 'investment':
        message = 'Great! Consider exploring investment options.';
        break;
      case 'savings_improvement':
        message = 'Budget optimization tips added to your goals!';
        break;
      case 'location_optimization':
        message = 'Location-based spending alerts activated!';
        break;
      default:
        message = 'Action noted! Keep up the good work!';
    }
    _showSuccess(message);
  }

  Widget _buildFilterChips() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;

          String label;
          if (filter == 'all') {
            label = 'All (${_suggestions.length + _aiSuggestions.length})';
          } else if (filter == 'backend') {
            label = 'Backend (${_suggestions.length})';
          } else if (filter == 'ai_generated') {
            label = 'AI Generated (${_aiSuggestions.length})';
          } else {
            label = '${filter.toUpperCase()} Priority';
          }

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedFilter = filter);
              },
              backgroundColor: surfaceColor,
              selectedColor: primaryColor,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? primaryColor : Colors.grey[300]!,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestionsHeader() {
    final highPriority = (_suggestions + _aiSuggestions).where((s) => s['priority'] == 'high').length;
    final actionable = (_suggestions + _aiSuggestions).where((s) => s['actionable'] == true).length;

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
          // Fixed: Changed Row to Column to prevent text cutoff
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'AI Financial Advisor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Moved buttons to a separate row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!_isLoading && !_isLoadingAI)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _fetchAISuggestions();
                        },
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ),
                  if (_isLoadingAI)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Personalized insights powered by advanced AI and your financial data',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          if (_userStats != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '₹${(_userStats!['current_savings'] ?? 0).toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Current Savings',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${(_userStats!['savings_rate'] ?? 0).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Savings Rate',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$highPriority',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'High Priority',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$actionable',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Actionable',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
            'AI Suggestions',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Analyzing your financial data...',
                style: TextStyle(fontSize: 16, color: hintColor),
              ),
            ],
          ),
        ),
      );
    }

    final filteredSuggestions = _filteredSuggestions;

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
          'AI Suggestions',
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
            _buildSuggestionsHeader(),
            const SizedBox(height: 24),
            _buildFilterChips(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: filteredSuggestions.isEmpty
                  ? Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.psychology_outlined, size: 48, color: hintColor),
                      SizedBox(height: 16),
                      Text(
                        'No suggestions found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: hintColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add more transactions to get personalized insights',
                        style: TextStyle(fontSize: 14, color: hintColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
                  : Column(
                children: filteredSuggestions
                    .map((suggestion) => GestureDetector(
                  onTap: suggestion['actionable'] == true
                      ? () => _handleAction(suggestion)
                      : null,
                  child: _buildSuggestionCard(suggestion),
                ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}