import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KisanVeer App Terms of Service',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: ${DateTime.now().day} ${_getMonth(DateTime.now().month)} ${DateTime.now().year}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              '1. Acceptance of Terms',
              'By accessing or using the KisanVeer application ("App"), you agree to be bound by these Terms of Service and all applicable laws and regulations. If you do not agree with any of these terms, you are prohibited from using the App.',
            ),
            
            _buildSection(
              '2. Description of Service',
              'KisanVeer is a platform that provides agricultural information, market access, financial services, weather forecasts, and community features to farmers in Maharashtra. The App aims to improve farming outcomes through technology and information.',
            ),
            
            _buildSection(
              '3. User Accounts',
              'To use certain features of the App, you must register for an account. You agree to provide accurate, current, and complete information during the registration process and to update such information to keep it accurate, current, and complete. You are responsible for safeguarding your password and for all activities that occur under your account.',
            ),
            
            _buildSection(
              '4. User Conduct',
              'You agree not to use the App to:\n\n'
              '• Upload or share content that is illegal, harmful, threatening, abusive, harassing, defamatory, or otherwise objectionable\n'
              '• Impersonate any person or entity\n'
              '• Upload or share content that infringes on intellectual property rights\n'
              '• Engage in any activity that interferes with or disrupts the App\n'
              '• Attempt to gain unauthorized access to the App or its related systems',
            ),
            
            _buildSection(
              '5. Content and Data',
              'The App may allow you to upload, submit, store, send, or receive content. You retain ownership of any intellectual property rights that you hold in that content. By uploading content to the App, you grant KisanVeer a worldwide license to use, host, store, reproduce, modify, create derivative works, communicate, publish, publicly perform, publicly display, and distribute such content.',
            ),
            
            _buildSection(
              '6. Privacy',
              'Your privacy is important to us. Please refer to our Privacy Policy for information about how we collect, use, and disclose information about you.',
            ),
            
            _buildSection(
              '7. Modification of Terms',
              'KisanVeer reserves the right to modify these Terms at any time. We will provide notice of any material changes through the App or by other means. Your continued use of the App after such modifications indicates your acceptance of the modified Terms.',
            ),
            
            _buildSection(
              '8. Termination',
              'KisanVeer may terminate or suspend your access to the App immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms. Upon termination, your right to use the App will immediately cease.',
            ),
            
            _buildSection(
              '9. Disclaimer of Warranties',
              'The App is provided on an "AS IS" and "AS AVAILABLE" basis. KisanVeer expressly disclaims all warranties of any kind, whether express or implied, including but not limited to the implied warranties of merchantability, fitness for a particular purpose, and non-infringement.',
            ),
            
            _buildSection(
              '10. Limitation of Liability',
              'In no event shall KisanVeer be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from your access to or use of or inability to access or use the App.',
            ),
            
            _buildSection(
              '11. Governing Law',
              'These Terms shall be governed and construed in accordance with the laws of India, without regard to its conflict of law provisions.',
            ),
            
            _buildSection(
              '12. Contact Information',
              'If you have any questions about these Terms, please contact us at support@kisanveer.com.',
            ),
            
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'Thank you for using KisanVeer!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getMonth(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
