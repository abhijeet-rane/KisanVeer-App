import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KisanVeer App Privacy Policy',
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
              'Introduction',
              'KisanVeer ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application (the "App").\n\n'
              'We respect your privacy and are committed to protecting it through our compliance with this policy. Please read this policy carefully to understand our policies and practices regarding your information and how we will treat it.',
            ),
            
            _buildSection(
              '1. Information We Collect',
              'We collect several types of information from and about users of our App, including information:\n\n'
              '• Personal information such as name, email address, phone number, and profile picture\n'
              '• Location data to provide location-based services such as weather forecasts and nearby market information\n'
              '• Agricultural information such as crops grown, farm size, and farming practices\n'
              '• Device information including IP address, device type, operating system, and mobile network information\n'
              '• Usage data about how you interact with our App',
            ),
            
            _buildSection(
              '2. How We Use Your Information',
              'We use information that we collect about you or that you provide to us:\n\n'
              '• To provide you with the App and its contents, and any other information, products, or services that you request from us\n'
              '• To fulfill any other purpose for which you provide it\n'
              '• To provide you with notices about your account\n'
              '• To improve our App and deliver a better and more personalized service\n'
              '• To provide you with tailored agricultural advice based on your crops, location, and weather conditions\n'
              '• To connect you with potential buyers for your produce\n'
              '• To deliver targeted advertisements to you\n'
              '• To carry out our obligations and enforce our rights',
            ),
            
            _buildSection(
              '3. Disclosure of Your Information',
              'We may disclose aggregated information about our users, and information that does not identify any individual, without restriction. We may disclose personal information that we collect or you provide as described in this privacy policy:\n\n'
              '• To contractors, service providers, and other third parties we use to support our business\n'
              '• To fulfill the purpose for which you provide it\n'
              '• With your consent\n'
              '• To comply with any court order, law, or legal process\n'
              '• If we believe disclosure is necessary to protect the rights or safety of KisanVeer, our users, or others',
            ),
            
            _buildSection(
              '4. Data Security',
              'We have implemented measures designed to secure your personal information from accidental loss and from unauthorized access, use, alteration, and disclosure. All information you provide to us is stored on secure servers behind firewalls. Any sensitive information will be encrypted using Secure Socket Layer (SSL) technology.\n\n'
              'Unfortunately, the transmission of information via the internet is not completely secure. Although we do our best to protect your personal information, we cannot guarantee the security of your personal information transmitted to our App.',
            ),
            
            _buildSection(
              '5. Location Data',
              'The App collects and processes real-time location information with your consent. This location data is used to provide you with weather forecasts, nearby market prices, and agricultural recommendations specific to your region. You can enable or disable location services when you use our App through your device settings.',
            ),
            
            _buildSection(
              '6. Your Choices About Our Collection and Use',
              'You can set your browser or mobile device to refuse all or some cookies, or to alert you when cookies are being sent. If you disable or refuse cookies, please note that some parts of this App may then be inaccessible or not function properly.\n\n'
              'You can update your privacy preferences through the Privacy Settings section in your profile to control how your information is displayed and shared within the KisanVeer community.',
            ),
            
            _buildSection(
              '7. Children\'s Privacy',
              'Our App is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are under 13, do not use or provide any information on this App.',
            ),
            
            _buildSection(
              '8. Changes to Our Privacy Policy',
              'We may update our privacy policy from time to time. If we make material changes to how we treat our users\' personal information, we will post the new privacy policy on this page and notify you through the App or via email.',
            ),
            
            _buildSection(
              '9. Data Retention',
              'We will retain your personal information only for as long as reasonably necessary to fulfill the purposes we collected it for, including for the purposes of satisfying any legal, regulatory, tax, accounting, or reporting requirements. We may retain your personal information for a longer period in the event of a complaint or if we reasonably believe there is a prospect of litigation.',
            ),
            
            _buildSection(
              '10. Contact Information',
              'To ask questions or comment about this privacy policy and our privacy practices, contact us at: privacy@kisanveer.com',
            ),
            
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'Thank you for trusting KisanVeer with your information.',
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
