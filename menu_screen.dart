import 'package:finsightai/settings_screen.dart';
import 'package:finsightai/login_screen.dart'; // Add this import
import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({Key? key}) : super(key: key);

  // App Colors
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1F2937);
  static const Color hintColor = Color(0xFF9CA3AF);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: (iconColor ?? primaryColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive ? errorColor : (iconColor ?? primaryColor),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? errorColor : textColor,
                    ),
                  ),
                ),
                Icon(
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout? You will be redirected to the login screen.',
            style: TextStyle(color: hintColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: hintColor),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: errorColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () {
                  // Close the dialog first
                  Navigator.pop(context);

                  // Navigate to login screen and clear all previous routes
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (Route<dynamic> route) => false,
                  );

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Successfully logged out'),
                      backgroundColor: successColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Data Collection & Usage',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• We collect financial data to provide personalized insights\n• Your mood and spending patterns are analyzed locally\n• No data is shared with third parties without consent',
                style: TextStyle(color: hintColor, height: 1.4),
              ),
              SizedBox(height: 16),
              Text(
                'Data Security',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• All financial data is encrypted using bank-level security\n• Biometric authentication protects your sensitive information\n• Data is stored securely on your device and our secure servers',
                style: TextStyle(color: hintColor, height: 1.4),
              ),
              SizedBox(height: 16),
              Text(
                'Your Rights',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• You can request data deletion at any time\n• Export your data in standard formats\n• Control what information is collected through app settings',
                style: TextStyle(color: hintColor, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'I Understand',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need help with FinSightAI?',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, color: primaryColor, size: 20),
                SizedBox(width: 8),
                Text('support@finsightai.com', style: TextStyle(color: hintColor)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, color: primaryColor, size: 20),
                SizedBox(width: 8),
                Text('+91 98765 43210', style: TextStyle(color: hintColor)),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Or visit our website for detailed FAQs and tutorials.',
              style: TextStyle(color: hintColor),
            ),
          ],
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _rateApp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Rate FinSightAI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Love using FinSightAI? Rate us on the app store!',
              style: TextStyle(color: hintColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Color(0xFFF59E0B), size: 24),
                Icon(Icons.star, color: Color(0xFFF59E0B), size: 24),
                Icon(Icons.star, color: Color(0xFFF59E0B), size: 24),
                Icon(Icons.star, color: Color(0xFFF59E0B), size: 24),
                Icon(Icons.star, color: Color(0xFFF59E0B), size: 24),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later', style: TextStyle(color: hintColor)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Show Thank You dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: surfaceColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Row(
                      children: [
                        Icon(Icons.favorite, color: Color(0xFFEF4444), size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Thank You!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Thank you for rating FinSightAI! Your feedback helps us improve and serve you better.',
                          style: TextStyle(color: hintColor),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '🎉 Keep managing your finances smartly! 🎉',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    actions: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'You\'re Welcome!',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: const Text(
                'Rate Now',
                style: TextStyle(color: Colors.white),
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
          'Menu',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Profile Section


              const SizedBox(height: 30),

              // Menu Items
              _buildMenuItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),

              _buildMenuItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () => _showPrivacyPolicy(context),
                iconColor: const Color(0xFF10B981),
              ),

              _buildMenuItem(
                icon: Icons.info_outline,
                title: 'About',
                onTap: () {
                  // Show about dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: surfaceColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text(
                        'About FinSightAI',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      content: const Text(
                        'FinSightAI v1.0\nAI-powered financial tracking and mood-based expense management.\n\nDeveloped with ❤️ for better financial insights.',
                        style: TextStyle(color: hintColor),
                      ),
                      actions: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'OK',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                iconColor: const Color(0xFFF59E0B),
              ),

              _buildMenuItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () => _showHelpDialog(context),
                iconColor: const Color(0xFF06B6D4),
              ),

              _buildMenuItem(
                icon: Icons.star_outline,
                title: 'Rate App',
                onTap: () => _rateApp(context),
                iconColor: const Color(0xFFF59E0B),
              ),

              const SizedBox(height: 20),

              _buildMenuItem(
                icon: Icons.logout,
                title: 'Log Out',
                onTap: () => _showLogoutDialog(context),
                isDestructive: true,
              ),

              const SizedBox(height: 40),

              // App Version
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: hintColor,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: hintColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
