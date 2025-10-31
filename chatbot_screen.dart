import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Hybrid Chat Service: Fake pretrained financial model + Groq LLM with strict financial filtering
class ChatService {
  static const List<String> _apiKeys = [
    '', // Example only
  ];
  static const String _groqApiUrl = "https://api.groq.com/openai/v1/chat/completions";

  // Comprehensive financial keywords for better detection
  static const Set<String> _financialKeywords = {
    // Core financial terms
    'save', 'saving', 'savings', 'budget', 'budgeting', 'investment', 'invest', 'investing',
    'goal', 'goals', 'expense', 'expenses', 'spend', 'spending', 'balance', 'money',
    'income', 'salary', 'earnings', 'profit', 'loss', 'debt', 'loan', 'credit',
    'bank', 'banking', 'account', 'deposit', 'withdrawal', 'transfer', 'payment',

    // Investment terms
    'stocks', 'bonds', 'mutual', 'fund', 'funds', 'portfolio', 'asset', 'assets',
    'equity', 'return', 'returns', 'yield', 'dividend', 'interest', 'compound',
    'sip', 'etf', 'gold', 'silver', 'crypto', 'cryptocurrency', 'trading',

    // Personal finance
    'retirement', 'pension', 'insurance', 'emergency',  'tax', 'taxes',
    'mortgage', 'rent', 'bills', 'utilities', 'groceries', 'shopping', 'purchase',
    'financial', 'finance', 'wealth', 'rich', 'poor', 'afford', 'cost', 'price',
    'cheap', 'expensive', 'value', 'worth', 'net worth', 'cash', 'cashflow',

    // Indian financial terms
    'rupees', 'inr', 'pf', 'epf', 'ppf', 'nsc', 'fd', 'rd', 'lic', 'ulip',
    'elss', 'nifty', 'sensex', 'sebi', 'rbi', 'gst', 'pan', 'aadhar',

    // Budgeting and planning
    'plan', 'planning', 'target', 'achieve', 'track', 'tracking', 'monitor',
    'allocate', 'allocation', 'distribute', 'manage', 'management', 'strategy',
    'advisor', 'consultation', 'guidance', 'tip', 'tips', 'advice',

    // Banking terms
    'atm', 'debit', 'upi', 'netbanking', 'mobile banking', 'ifsc', 'swift',
    'cheque', 'dd', 'neft', 'rtgs', 'imps', 'overdraft', 'emi', 'roi'
  };

  // Pretrained model
  static const String ModelBasePath = "assets/models/financial_dialogpt/";
  static const List<String> ModelFiles = [
    "vocab.json", "tokenizer.json", "merges.txt", "config.json",
    "special_token_map.json", "model.safetensors", "added_tokens.json",
    "tokenizer_config.json", "generation_config.json", "chat_template.jinja",
  ];

  final List<Map<String, String>> _conversationHistory = [];

  Future<String> _fakeFinancialModelReply(String message, String? userContext) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final lowerMsg = message.toLowerCase();

    if (lowerMsg.contains("save") || lowerMsg.contains("saving")) {
      return "Automate saving 20% of monthly income based on your spending.\nUse auto-transfer apps to keep consistency.";
    } else if (lowerMsg.contains("budget")) {
      return "Suggested budget allocation: 50% needs, 30% wants, 20% savings.\nTrack spends monthly.";
    } else if (lowerMsg.contains("invest")) {
      return "Start SIP with ₹3000 in diversified equity and debt mutual funds for balanced risk.";
    } else if (lowerMsg.contains("goal")) {
      return "Emergency fund 70% funded; vacation fund 40% funded.\nConsider increasing monthly SIPs.";
    } else if (lowerMsg.contains("expense") || lowerMsg.contains("spend")) {
      return "Major expenses: Food, Transport, Shopping.\nCut discretionary expenses to increase savings.";
    } else if (lowerMsg.contains("balance")) {
      return "Maintain a minimum balance of ₹19,150 as an emergency buffer.";
    } else {
      return "Revisit goals regularly and adjust saving rates for effective wealth building.";
    }
  }

  Future<String> _groqApiReply(String message, String? userContext) async {
    // Add financial context to system message
    if (_conversationHistory.isEmpty) {
      _conversationHistory.add({
        'role': 'system',
        'content': '''You are Fin AI, a specialized personal financial assistant. You ONLY provide advice on:
- Personal finance, budgeting, and money management
- Savings and investment strategies
- Financial planning and goal setting
- Banking and payment solutions
- Indian financial products (SIP, PPF, ELSS, etc.)
- Budget tracking and expense management

If asked about non-financial topics, politely redirect to financial matters.
${userContext ?? ''}'''
      });
    }

    _conversationHistory.add({'role': 'user', 'content': message});

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
            'messages': _conversationHistory,
            'temperature': 0.7,
            'max_tokens': 1024,
          }),
        );

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final content = data['choices'][0]['message']['content'];
          _conversationHistory.add({'role': 'assistant', 'content': content});
          return content;
        }
      } catch (_) {
        continue;
      }
    }
    return "I'm having trouble connecting right now. Please try again with a financial question.";
  }

  // Enhanced financial question detection
  bool _isFinancialQuestion(String msg) {
    final text = msg.toLowerCase();

    // Check for financial keywords
    bool hasFinancialKeywords = _financialKeywords.any((keyword) =>
        text.contains(keyword.toLowerCase()));

    // Check for currency symbols and amounts
    bool hasCurrency = text.contains('₹') || text.contains('rs') ||
        text.contains('rupee') || text.contains('dollar') ||
        RegExp(r'\d+\s*(lakh|crore|thousand|k|cr|lac)').hasMatch(text);

    // Check for percentage patterns (for returns, interest rates)
    bool hasPercentage = text.contains('%') || text.contains('percent');

    // Financial question patterns
    List<String> financialPatterns = [
      'how much should i',
      'what is the best way to',
      'should i invest',
      'how to save',
      'financial advice',
      'money management',
      'retirement planning',
      'tax saving',
      'loan emi',
      'credit score',
      'mutual fund',
      'stock market',
      'fixed deposit',
      'insurance policy'
    ];

    bool hasFinancialPattern = financialPatterns.any((pattern) =>
        text.contains(pattern));

    return hasFinancialKeywords || hasCurrency || hasPercentage || hasFinancialPattern;
  }

  Future<String> sendMessage(String message, {String? userContext}) async {
    // First check if it's a financial question
    if (!_isFinancialQuestion(message)) {
      return '''I'm Fin AI, your personal financial assistant! 🏦💰

I can help you with:
• Budget planning and expense tracking
• Investment advice and portfolio management  
• Savings strategies and goal setting
• Banking and payment solutions
• Indian financial products (SIP, PPF, ELSS, etc.)
• Tax planning and insurance guidance

Please ask me anything related to your finances, and I'll be happy to help!''';
    }

    // Process financial questions
    if (_isFinancialQuestion(message)) {
      // Use pretrained model for basic financial queries
      if (_hasBasicFinancialKeywords(message)) {
        return await _fakeFinancialModelReply(message, userContext);
      } else {
        // Use Groq for more complex financial questions
        return await _groqApiReply(message, userContext);
      }
    } else {
      return await _groqApiReply(message, userContext);
    }
  }

  // Helper method to determine if query should use pretrained model
  bool _hasBasicFinancialKeywords(String msg) {
    final text = msg.toLowerCase();
    List<String> basicKeywords = ['save', 'budget', 'invest', 'goal', 'expense', 'balance'];
    return basicKeywords.any((keyword) => text.contains(keyword));
  }
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with TickerProviderStateMixin {
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1F2937);
  static const Color hintColor = Color(0xFF9CA3AF);
  static const Color successColor = Color(0xFF10B981);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final List<Map<String, dynamic>> _messages = [];
  late AnimationController _typingAnimationController;
  bool _isTyping = false;

  final String _userContext = '''
User Financial Profile:
- Monthly Income: ₹65,000
- Current Balance: ₹19,150
- Monthly Spending: ₹45,850
- Goals: Emergency Fund (70% complete), Vacation Fund (40% complete)
''';

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _messages.add({
      'text': "Hello! I'm Fin AI, your personal financial assistant. 🏦💰\n\nI can help you with budgeting, investments, savings, and all your financial planning needs. How can I assist you today?",
      'isUser': false,
      'timestamp': DateTime.now(),
    });

    Future.delayed(Duration(milliseconds: 500), () {
      _addQuickSuggestions();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  void _addQuickSuggestions() {
    setState(() {
      _messages.add({
        'text': '',
        'isUser': false,
        'timestamp': DateTime.now(),
        'isQuickActions': true,
      });
    });
  }

  void _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add({'text': message, 'isUser': true, 'timestamp': DateTime.now()});
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    _typingAnimationController.repeat();

    try {
      final response = await _chatService.sendMessage(message, userContext: _userContext);

      setState(() {
        _isTyping = false;
        _messages.add({'text': response, 'isUser': false, 'timestamp': DateTime.now()});
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'text': "I'm sorry, something went wrong. Please try again with a financial question.",
          'isUser': false,
          'timestamp': DateTime.now(),
        });
      });
    }

    _typingAnimationController.stop();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildQuickAction(String title, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _sendMessage("Can you help me with ${title.toLowerCase()}?"),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    bool isUser = message['isUser'] ?? false;
    bool isQuickActions = message['isQuickActions'] ?? false;

    if (isQuickActions) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickAction('Saving Money', Icons.savings_outlined, successColor),
              _buildQuickAction('Budget Planning', Icons.pie_chart_outline, primaryColor),
              _buildQuickAction('Investment Tips', Icons.trending_up, Color(0xFFF59E0B)),
              _buildQuickAction('Goal Tracking', Icons.flag_outlined, Color(0xFFEF4444)),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              height: 36,
              width: 36,
              margin: EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? primaryColor : surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: isUser ? Radius.circular(20) : Radius.circular(4),
                  bottomRight: isUser ? Radius.circular(4) : Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message['text'], style: TextStyle(fontSize: 16, color: isUser ? Colors.white : textColor)),
                  SizedBox(height: 4),
                  Text(
                    "${message['timestamp'].hour.toString().padLeft(2, '0')}:${message['timestamp'].minute.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      fontSize: 12,
                      color: isUser ? Colors.white70 : hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser)
            Container(
              height: 36,
              width: 36,
              margin: EdgeInsets.only(left: 12),
              decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
              child: Icon(Icons.person, color: Colors.grey, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            margin: EdgeInsets.only(right: 12),
            decoration: BoxDecoration(gradient: primaryGradient, shape: BoxShape.circle),
            child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomRight: Radius.circular(20), bottomLeft: Radius.circular(4)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                    (index) => AnimatedBuilder(
                  animation: _typingAnimationController,
                  builder: (context, child) {
                    final double opacity = (_typingAnimationController.value + index * 0.3) % 1.0;
                    return Opacity(
                      opacity: 0.3 + 0.7 * opacity,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 3),
                        height: 8,
                        width: 8,
                        decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
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
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: surfaceColor,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(gradient: primaryGradient, shape: BoxShape.circle),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FIN AI',
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18)),
                Text('Financial Assistant',
                    style: TextStyle(color: hintColor, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessage(_messages[index]);
                },
              )),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Ask me anything about finances...',
                          hintStyle: TextStyle(color: hintColor),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        maxLines: null,
                        onSubmitted: _sendMessage,
                      ),
                    )),
                SizedBox(width: 12),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    gradient: primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(_messageController.text),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
