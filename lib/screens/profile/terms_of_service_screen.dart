import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const List<_Section> _sections = [
    _Section(
      '1. Acceptance of terms',
      'By accessing or using the KisanVeer application ("App"), you agree to be bound by these Terms of Service and all applicable laws and regulations. If you do not agree with any of these terms, you are prohibited from using the App.',
    ),
    _Section(
      '2. Description of service',
      'KisanVeer is a platform that provides agricultural information, market access, financial services, weather forecasts, and community features to farmers in Maharashtra. The App aims to improve farming outcomes through technology and information.',
    ),
    _Section(
      '3. User accounts',
      'To use certain features of the App you must register for an account. You agree to provide accurate, current, and complete information during registration, and to keep that information up to date. You are responsible for safeguarding your password and for all activity that occurs under your account.',
    ),
    _Section(
      '4. User conduct',
      'You agree not to use the App to:\n\n'
          '• Upload or share content that is illegal, harmful, threatening, abusive, harassing, defamatory, or otherwise objectionable\n'
          '• Impersonate any person or entity\n'
          '• Upload or share content that infringes on intellectual property rights\n'
          '• Engage in activity that interferes with or disrupts the App\n'
          '• Attempt to gain unauthorized access to the App or its related systems',
    ),
    _Section(
      '5. Content and data',
      'The App may allow you to upload, submit, store, send, or receive content. You retain ownership of any intellectual property rights that you hold in that content. By uploading content to the App, you grant KisanVeer a worldwide license to use, host, store, reproduce, modify, create derivative works, communicate, publish, publicly perform, publicly display, and distribute such content.',
    ),
    _Section(
      '6. Privacy',
      'Your privacy is important to us. Please refer to our Privacy Policy for information about how we collect, use, and disclose information about you.',
    ),
    _Section(
      '7. Modification of terms',
      'KisanVeer reserves the right to modify these Terms at any time. We will provide notice of any material changes through the App or by other means. Your continued use of the App after such modifications indicates your acceptance of the modified Terms.',
    ),
    _Section(
      '8. Termination',
      'KisanVeer may terminate or suspend your access to the App immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms. Upon termination, your right to use the App will immediately cease.',
    ),
    _Section(
      '9. Disclaimer of warranties',
      'The App is provided on an "AS IS" and "AS AVAILABLE" basis. KisanVeer expressly disclaims all warranties of any kind, whether express or implied, including but not limited to the implied warranties of merchantability, fitness for a particular purpose, and non-infringement.',
    ),
    _Section(
      '10. Limitation of liability',
      'In no event shall KisanVeer be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from your access to or use of or inability to access or use the App.',
    ),
    _Section(
      '11. Governing law',
      'These Terms shall be governed and construed in accordance with the laws of India, without regard to its conflict of law provisions.',
    ),
    _Section(
      '12. Contact information',
      'If you have any questions about these Terms, please contact us at support@kisanveer.com.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Terms of service', showBack: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.space16),
          children: [
            Text(
              'KisanVeer terms of service',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              'Last updated ${now.day} ${_monthName(now.month)} ${now.year}',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
            for (final section in _sections) _SectionTile(section: section),
            const SizedBox(height: AppSpacing.space16),
            Center(
              child: Text(
                'Thank you for using KisanVeer.',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space32),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
  }
}

class _Section {
  const _Section(this.title, this.body);
  final String title;
  final String body;
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.section});

  final _Section section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            section.body,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurface,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
