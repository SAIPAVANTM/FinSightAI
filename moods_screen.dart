import 'package:finsightai/url.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MoodsScreen extends StatefulWidget {
  final String userEmail; // current user's email passed

  const MoodsScreen({Key? key, required this.userEmail}) : super(key: key);

  @override
  State<MoodsScreen> createState() => _MoodsScreenState();
}

class _MoodsScreenState extends State<MoodsScreen> with TickerProviderStateMixin {
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1F2937);
  static const Color hintColor = Color(0xFF9CAABF);

  static const Color happyColor = Color(0xFF10B981);
  static const Color sadColor = Color(0xFF6366F1);
  static const Color angryColor = Color(0xFFEF4444);
  static const Color neutralColor = Color(0xFF6B7280);
  static const Color joyfulColor = Color(0xFFF59E0B);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B3CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  late AnimationController _animationController;
  late Animation<double> _animation;

  Map<String, dynamic> _moodData = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
    _fetchMoodData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchMoodData() async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await http.get(Uri.parse(
          '${Url.Urls}/moods_transactions/${widget.userEmail}?days=7'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _moodData = Map<String, dynamic>.from(data['data']);
            _loading = false;
          });
        } else {
          _showError(data['message'] ?? 'Failed to load data');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Network error: $e');
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ));
    }
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return happyColor;
      case 'sad':
        return sadColor;
      case 'angry':
        return angryColor;
      case 'neutral':
        return neutralColor;
      case 'joyful':
        return joyfulColor;
      default:
        return hintColor;
    }
  }

  IconData _getMoodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'angry':
        return Icons.sentiment_very_dissatisfied;
      case 'neutral':
        return Icons.sentiment_neutral;
      case 'joyful':
        return Icons.sentiment_satisfied;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildBarChart() {
    const moodOrder = ['Happy', 'Sad', 'Angry', 'Neutral', 'Joyful'];

    List<double> moodValues = moodOrder.map((mood) {
      final val = _moodData[mood] != null ? _moodData[mood]['total'] : 0;
      return (val is num) ? val.toDouble() : 0.0;
    }).toList();

    double maxY = moodValues.isEmpty ? 10 : moodValues.reduce((a, b) => a > b ? a : b) * 1.2;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: moodValues.asMap().entries.map((entry) {
            int idx = entry.key;
            double val = entry.value;
            return BarChartGroupData(
              x: idx,
              barRods: [
                BarChartRodData(
                  toY: val,
                  width: 20,
                  color: _getMoodColor(moodOrder[idx]),
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < moodOrder.length) {
                    return Text(
                      moodOrder[value.toInt()],
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildTransactionList(String mood) {
    List<dynamic> txns = _moodData[mood]?['transactions'] ?? [];

    if (txns.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No transactions recorded',
          style: TextStyle(color: hintColor),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: txns.length,
      itemBuilder: (_, index) {
        var txn = txns[index];
        DateTime dt = DateTime.parse(txn['date']);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _getMoodColor(mood).withOpacity(0.2),
            child: Icon(
              _getMoodIcon(mood),
              color: _getMoodColor(mood),
            ),
          ),
          title: Text(txn['description'] ?? ''),
          subtitle: Text(_formatDate(dt)),
          trailing: Text(
            '₹${txn['amount'].toString()}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Moods')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Moods'),
        backgroundColor: backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBarChart(),
            const SizedBox(height: 24),
            ..._moodData.keys.map((mood) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mood,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getMoodColor(mood),
                    ),
                  ),
                  _buildTransactionList(mood),
                  const SizedBox(height: 24),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
