import 'package:flutter/material.dart';
import 'package:kisan_veer/screens/profile/report_problem_screen.dart';
import 'package:kisan_veer/widgets/custom_card.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final List<Map<String, dynamic>> _faqItems = [
    {
      'question': 'How do I add or change the crops I grow?',
      'answer': 'You can add or change your crops by going to your Profile, tapping on "Edit Profile", and then selecting the crops you grow from the list provided.'
    },
    {
      'question': 'How does the weather forecast help me with farming?',
      'answer': 'The weather forecast provides detailed information about expected weather conditions that affect your crops. Based on the current weather and forecast, the app provides specific recommendations for your crops to help you maximize yield and prevent damage.'
    },
    {
      'question': 'Can I sell my produce directly through this app?',
      'answer': 'Yes! The Market tab allows you to list your produce for sale. You can also connect with buyers in your area who are looking for fresh produce directly from farmers.'
    },
    {
      'question': 'How do I get financial assistance for farming?',
      'answer': 'Visit the Finance tab to view available financial products including loans, insurance, and subsidies specifically for farmers. You can apply directly through the app.'
    },
    {
      'question': 'How do I connect with other farmers?',
      'answer': 'The Community tab allows you to connect with other farmers, join groups based on crops or location, and participate in discussions to share best practices.'
    },
  ];
  
  final List<Map<String, dynamic>> _contactOptions = [
    {
      'title': 'Email Support',
      'icon': Icons.email,
      'action': 'support@kisanveer.com',
      'type': 'email'
    },
    {
      'title': 'Call Helpline',
      'icon': Icons.phone,
      'action': '+91 8000FARMER',
      'type': 'phone'
    },
    {
      'title': 'WhatsApp Support',
      'icon': Icons.message,
      'action': '+91 9000FARMER',
      'type': 'whatsapp'
    },
    {
      'title': 'Report a Problem',
      'icon': Icons.bug_report,
      'action': 'report',
      'type': 'screen'
    },
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Help image
            Center(
              child: Image.asset(
                'assets/images/help_center.png',
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      size: 60,
                      color: Colors.green,
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Contact Options
            const Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            CustomCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _contactOptions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final option = _contactOptions[index];
                  return ListTile(
                    leading: Icon(
                      option['icon'],
                      color: Colors.green,
                    ),
                    title: Text(option['title']),
                    subtitle: option['type'] != 'screen' 
                        ? Text(option['action'])
                        : null,
                    onTap: () {
                      _handleContactAction(option['type'], option['action']);
                    },
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // FAQs
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _faqItems.length,
              itemBuilder: (context, index) {
                final faq = _faqItems[index];
                return CustomCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(
                      faq['question'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    iconColor: Colors.green,
                    collapsedIconColor: Colors.grey,
                    tilePadding: EdgeInsets.zero,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          faq['answer'],
                          style: const TextStyle(
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Additional Resources
            const Text(
              'Additional Resources',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.video_library,
                      color: Colors.green,
                    ),
                    title: const Text('Video Tutorials'),
                    subtitle: const Text('Visual guides to using the app'),
                    onTap: () {
                      // Open video tutorials
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.article,
                      color: Colors.green,
                    ),
                    title: const Text('User Guide'),
                    subtitle: const Text('Detailed app documentation'),
                    onTap: () {
                      // Open user guide
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.forum,
                      color: Colors.green,
                    ),
                    title: const Text('Community Forum'),
                    subtitle: const Text('Get help from other farmers'),
                    onTap: () {
                      // Open community forum
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  void _handleContactAction(String type, String action) async {
    switch (type) {
      case 'email':
        final Uri emailUri = Uri(
          scheme: 'mailto',
          path: action,
          queryParameters: {
            'subject': 'Support Request - KisanVeer App',
          },
        );
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri);
        } else {
          _showErrorSnackbar('Could not open email app');
        }
        break;
        
      case 'phone':
        final Uri phoneUri = Uri(
          scheme: 'tel',
          path: action.replaceAll(RegExp(r'\s+'), ''),
        );
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri);
        } else {
          _showErrorSnackbar('Could not open phone app');
        }
        break;
        
      case 'whatsapp':
        final Uri whatsappUri = Uri.parse(
          'https://wa.me/${action.replaceAll(RegExp(r'\s+'), '')}',
        );
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri);
        } else {
          _showErrorSnackbar('Could not open WhatsApp');
        }
        break;
        
      case 'screen':
        if (action == 'report') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReportProblemScreen(),
            ),
          );
        }
        break;
    }
  }
  
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
