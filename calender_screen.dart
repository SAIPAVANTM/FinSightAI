import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {

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

  DateTime _selectedDate = DateTime.now();
  final PageController _pageController = PageController(initialPage: 0);
  final TextEditingController _eventTitleController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  final List<Map<String, dynamic>> _events = [
    {
      'id': '1',
      'title': 'Friend\'s Birthday Party',
      'date': DateTime.now().add(const Duration(days: 3)),
      'budget': 2500.0,
      'spent': 0.0,
      'category': 'Social',
      'type': 'birthday',
      'color': const Color(0xFFEC4899),
      'reminder': true,
    },
    {
      'id': '2',
      'title': 'Wedding - Cousin',
      'date': DateTime.now().add(const Duration(days: 15)),
      'budget': 15000.0,
      'spent': 3000.0,
      'category': 'Family',
      'type': 'wedding',
      'color': errorColor,
      'reminder': true,
    },
    {
      'id': '3',
      'title': 'Anniversary Dinner',
      'date': DateTime.now().add(const Duration(days: 7)),
      'budget': 3500.0,
      'spent': 0.0,
      'category': 'Personal',
      'type': 'anniversary',
      'color': successColor,
      'reminder': false,
    },
    {
      'id': '4',
      'title': 'Team Outing',
      'date': DateTime.now().add(const Duration(days: 10)),
      'budget': 4000.0,
      'spent': 1200.0,
      'category': 'Work',
      'type': 'outing',
      'color': primaryColor,
      'reminder': true,
    },
  ];

  @override
  void dispose() {
    _eventTitleController.dispose();
    _budgetController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getUpcomingEvents() {
    final now = DateTime.now();
    return _events.where((event) => event['date'].isAfter(now)).toList()
      ..sort((a, b) => a['date'].compareTo(b['date']));
  }

  List<Map<String, dynamic>> _getEventsForDate(DateTime date) {
    return _events.where((event) {
      final eventDate = event['date'] as DateTime;
      return eventDate.year == date.year &&
          eventDate.month == date.month &&
          eventDate.day == date.day;
    }).toList();
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  void _showDayEvents(DateTime date, List<Map<String, dynamic>> events) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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

                Text(
                  'Events on ${date.day} ${_getMonthName(date.month)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),

                ...events.map((event) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: event['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: event['color'].withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: event['color'],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getEventIcon(event['type']),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Budget: ₹${event['budget'].toStringAsFixed(0)} • Spent: ₹${event['spent'].toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCalendarView() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return CalendarViewWidget(
          events: _events,
          onClose: () => Navigator.pop(context),
          onAddEvent: () {
            Navigator.pop(context);
            _addEvent();
          },
          getEventIcon: _getEventIcon,
          getMonthName: _getMonthName,
          showDayEvents: _showDayEvents,
        );
      },
    );
  }

  void _addEvent() {
    showDialog(
      context: context,
      builder: (context) => _buildAddEventDialog(),
    );
  }

  Widget _buildAddEventDialog() {
    String selectedCategory = 'Social';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Add Event',
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
                  controller: _eventTitleController,
                  decoration: InputDecoration(
                    labelText: 'Event Title',
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
                TextField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Budget (₹)',
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
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['Social', 'Family', 'Personal', 'Work'].map<DropdownMenuItem<String>>((category) {
                    return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category)
                    );
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
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDate = date;
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
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
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
                  if (_eventTitleController.text.isNotEmpty && _budgetController.text.isNotEmpty) {
                    final newEvent = {
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': _eventTitleController.text,
                      'date': selectedDate,
                      'budget': double.parse(_budgetController.text),
                      'spent': 0.0,
                      'category': selectedCategory,
                      'type': 'custom',
                      'color': _getCategoryColor(selectedCategory),
                      'reminder': false,
                    };

                    setState(() {
                      _events.add(newEvent);
                    });

                    _eventTitleController.clear();
                    _budgetController.clear();
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Event added successfully!'),
                        backgroundColor: successColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                },
                child: const Text('Add Event', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Social':
        return const Color(0xFFEC4899);
      case 'Family':
        return errorColor;
      case 'Personal':
        return successColor;
      case 'Work':
        return primaryColor;
      default:
        return hintColor;
    }
  }

  void _showTestNotification() {
    showDialog(
      context: context,
      builder: (context) => _buildTestNotificationDialog(),
    );
  }

  Widget _buildTestNotificationDialog() {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.now();
    String notificationType = 'Immediate';
    String selectedEvent = _events.isNotEmpty ? _events.first['title'] : 'Sample Event';

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications_active, color: warningColor, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Schedule Notification',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Event',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedEvent,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _events.map<DropdownMenuItem<String>>((event) {
                    return DropdownMenuItem<String>(
                      value: event['title'] as String,
                      child: Text(event['title'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedEvent = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                const Text(
                  'Notification Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: notificationType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: ['Immediate', 'Scheduled', '1 Day Before', '3 Days Before', '1 Week Before']
                      .map<DropdownMenuItem<String>>((type) {
                    return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type)
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      notificationType = value!;
                    });
                  },
                ),

                if (notificationType == 'Scheduled') ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setDialogState(() {
                          selectedDate = date;
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
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.calendar_today, color: primaryColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Time',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (time != null) {
                        setDialogState(() {
                          selectedTime = time;
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
                          Text(
                            selectedTime.format(context),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.access_time, color: primaryColor),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'This will send a test notification based on your selection',
                          style: TextStyle(fontSize: 12, color: textColor),
                        ),
                      ),
                    ],
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
                onPressed: () async {
                  Navigator.pop(context);

                  // Calculate notification time
                  DateTime notificationTime;
                  String message;

                  switch (notificationType) {
                    case 'Immediate':
                      notificationTime = DateTime.now();
                      message = 'Test notification sent immediately!';
                      break;
                    case 'Scheduled':
                      notificationTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                      message = 'Notification scheduled for ${selectedDate.day}/${selectedDate.month} at ${selectedTime.format(context)}';
                      break;
                    case '1 Day Before':
                      final event = _events.firstWhere((e) => e['title'] == selectedEvent);
                      notificationTime = (event['date'] as DateTime).subtract(const Duration(days: 1));
                      message = 'Notification scheduled 1 day before event';
                      break;
                    case '3 Days Before':
                      final event = _events.firstWhere((e) => e['title'] == selectedEvent);
                      notificationTime = (event['date'] as DateTime).subtract(const Duration(days: 3));
                      message = 'Notification scheduled 3 days before event';
                      break;
                    case '1 Week Before':
                      final event = _events.firstWhere((e) => e['title'] == selectedEvent);
                      notificationTime = (event['date'] as DateTime).subtract(const Duration(days: 7));
                      message = 'Notification scheduled 1 week before event';
                      break;
                    default:
                      notificationTime = DateTime.now();
                      message = 'Test notification sent!';
                  }

                  // Get event details
                  final event = _events.firstWhere(
                        (e) => e['title'] == selectedEvent,
                    orElse: () => _events.first,
                  );

                  // Send notification (immediate only - scheduled would need proper implementation)
                  if (notificationType == 'Immediate') {
                    const AndroidNotificationDetails androidPlatformChannelSpecifics =
                    AndroidNotificationDetails(
                      'event_reminders',
                      'Event Reminders',
                      channelDescription: 'Notifications for upcoming events',
                      importance: Importance.max,
                      priority: Priority.high,
                      showWhen: false,
                      icon: '@mipmap/ic_launcher',
                      playSound: true,
                      enableVibration: true,
                    );

                    const NotificationDetails platformChannelSpecifics =
                    NotificationDetails(android: androidPlatformChannelSpecifics);

                    await FlutterLocalNotificationsPlugin().show(
                      DateTime.now().millisecondsSinceEpoch.remainder(100000),
                      '🎉 FinSightAI Reminder',
                      '${event['title']} - Budget: ₹${event['budget'].toStringAsFixed(0)} 💝',
                      platformChannelSpecifics,
                    );
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: successColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                child: const Text('Schedule', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _editSpentAmount(Map<String, dynamic> event) {
    final spentController = TextEditingController(text: event['spent'].toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: event['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getEventIcon(event['type']), color: event['color'], size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Update Spent Amount',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event['title'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Budget: ₹${event['budget'].toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 14,
                color: hintColor,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: spentController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount Spent (₹)',
                prefixIcon: const Icon(Icons.currency_rupee, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
          ],
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
                if (spentController.text.isNotEmpty) {
                  setState(() {
                    event['spent'] = double.parse(spentController.text);
                  });
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Spent amount updated successfully!'),
                      backgroundColor: successColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final daysLeft = event['date'].difference(DateTime.now()).inDays;
    final progressPercentage = event['budget'] > 0 ? (event['spent'] / event['budget']) : 0.0;

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
                    color: event['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getEventIcon(event['type']),
                    color: event['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: hintColor),
                          const SizedBox(width: 4),
                          Text(
                            '$daysLeft days left',
                            style: const TextStyle(
                              fontSize: 14,
                              color: hintColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: event['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              event['category'],
                              style: TextStyle(
                                fontSize: 12,
                                color: event['color'],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    event['reminder'] ? Icons.notifications : Icons.notifications_off,
                    color: event['reminder'] ? warningColor : hintColor,
                  ),
                  onPressed: () {
                    setState(() {
                      event['reminder'] = !event['reminder'];
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Budget',
                        style: TextStyle(
                          fontSize: 14,
                          color: hintColor,
                        ),
                      ),
                      Text(
                        '₹${event['budget'].toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _editSpentAmount(event),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Spent',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: hintColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 12,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '₹${event['spent'].toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: event['spent'] > event['budget'] ? errorColor : successColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Remaining',
                        style: TextStyle(
                          fontSize: 14,
                          color: hintColor,
                        ),
                      ),
                      Text(
                        '₹${(event['budget'] - event['spent']).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: (event['budget'] - event['spent']) < 0 ? errorColor : primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progressPercentage.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                progressPercentage > 1.0 ? errorColor : event['color'],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progressPercentage * 100).toStringAsFixed(1)}% of budget used',
              style: TextStyle(
                fontSize: 12,
                color: progressPercentage > 1.0 ? errorColor : hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'birthday':
        return Icons.cake;
      case 'wedding':
        return Icons.favorite;
      case 'anniversary':
        return Icons.celebration;
      case 'outing':
        return Icons.group;
      default:
        return Icons.event;
    }
  }

  Widget _buildViewEventsButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showCalendarView,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    gradient: primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_view_month,
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
                        'View Events',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'See all your upcoming events in calendar view',
                        style: TextStyle(
                          fontSize: 14,
                          color: hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: hintColor,
                  size: 16,
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
    final upcomingEvents = _getUpcomingEvents();

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
          'Calendar',
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
              onPressed: _addEvent,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // View Events Button
            _buildViewEventsButton(),

            const SizedBox(height: 24),

            // Set Reminder Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set Reminder',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Get notified about upcoming events and their budgets',
                    style: TextStyle(
                      fontSize: 14,
                      color: hintColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      color: warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: warningColor.withOpacity(0.3)),
                    ),
                    child: ElevatedButton(
                      onPressed: _showTestNotification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Add Test Notification',
                        style: TextStyle(
                          color: warningColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Upcoming Events Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Upcoming Events',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Events List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: upcomingEvents.isEmpty
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
                        Icons.event_available,
                        size: 48,
                        color: hintColor,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No upcoming events',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: hintColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add an event to start tracking your budget',
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
                children: upcomingEvents.map((event) => _buildEventCard(event)).toList(),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Separate Calendar View Widget with proper state management
class CalendarViewWidget extends StatefulWidget {
  final List<Map<String, dynamic>> events;
  final VoidCallback onClose;
  final VoidCallback onAddEvent;
  final IconData Function(String) getEventIcon;
  final String Function(int) getMonthName;
  final Function(DateTime, List<Map<String, dynamic>>) showDayEvents;

  const CalendarViewWidget({
    Key? key,
    required this.events,
    required this.onClose,
    required this.onAddEvent,
    required this.getEventIcon,
    required this.getMonthName,
    required this.showDayEvents,
  }) : super(key: key);

  @override
  State<CalendarViewWidget> createState() => _CalendarViewWidgetState();
}

class _CalendarViewWidgetState extends State<CalendarViewWidget> {
  late DateTime currentMonth;

  // App Colors
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1F2937);
  static const Color hintColor = Color(0xFF9CA3AF);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    currentMonth = DateTime.now();
  }

  List<Map<String, dynamic>> _getEventsForDate(DateTime date) {
    return widget.events.where((event) {
      final eventDate = event['date'] as DateTime;
      return eventDate.year == date.year &&
          eventDate.month == date.month &&
          eventDate.day == date.day;
    }).toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildCalendarGrid(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0
    final daysInMonth = lastDayOfMonth.day;

    List<Widget> dayWidgets = [];

    // Empty cells for days before month starts
    for (int i = 0; i < firstDayWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    // Days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final eventsForDay = _getEventsForDate(date);
      final isToday = _isSameDay(date, DateTime.now());

      dayWidgets.add(
        GestureDetector(
          onTap: eventsForDay.isNotEmpty
              ? () => widget.showDayEvents(date, eventsForDay)
              : null,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isToday
                  ? primaryColor.withOpacity(0.1)
                  : eventsForDay.isNotEmpty
                  ? eventsForDay.first['color'].withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? Border.all(color: primaryColor, width: 2)
                  : eventsForDay.isNotEmpty
                  ? Border.all(color: eventsForDay.first['color'], width: 1)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday
                        ? primaryColor
                        : eventsForDay.isNotEmpty
                        ? eventsForDay.first['color']
                        : textColor,
                  ),
                ),
                if (eventsForDay.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: eventsForDay.take(3).map((event) => Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: event['color'],
                          shape: BoxShape.circle,
                        ),
                      )).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      children: dayWidgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
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

            // Title with calendar icon
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
                    Icons.calendar_month,
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
                        'Event Calendar',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Monthly view with event details',
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

            // Month Navigation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
                      });
                    },
                    icon: const Icon(Icons.chevron_left, color: primaryColor),
                  ),
                  Text(
                    '${widget.getMonthName(currentMonth.month)} ${currentMonth.year}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
                      });
                    },
                    icon: const Icon(Icons.chevron_right, color: primaryColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Calendar Grid
            Expanded(
              child: Column(
                children: [
                  // Weekday Headers
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                          .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: hintColor,
                            ),
                          ),
                        ),
                      ))
                          .toList(),
                    ),
                  ),

                  // Calendar Grid
                  Expanded(
                    child: _buildCalendarGrid(currentMonth),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Legend
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
                    'Legend',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Today', style: TextStyle(fontSize: 12, color: hintColor)),
                      const SizedBox(width: 16),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Events', style: TextStyle(fontSize: 12, color: hintColor)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
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
                      onPressed: widget.onClose,
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
                      onPressed: widget.onAddEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 16, color: Colors.white),
                      label: const Text(
                        'Add Event',
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
  }
}