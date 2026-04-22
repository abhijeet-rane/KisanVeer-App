import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const List<_Section> _sections = [
    _Section(
      'Introduction',
      'KisanVeer ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.\n\n'
          'We respect your privacy and are committed to protecting it through our compliance with this policy. Please read carefully to understand our practices regarding your information and how we treat it.',
    ),
    _Section(
      '1. Information we collect',
      'We collect several types of information from and about users of our App, including:\n\n'
          '• Personal information — name, email, phone number, profile picture\n'
          '• Location data for weather and nearby-market features\n'
          '• Agricultural information — crops grown, farm size, farming practices\n'
          '• Device information — IP address, device type, operating system, mobile network\n'
          '• Usage data about how you interact with our App',
    ),
    _Section(
      '2. How we use your information',
      'We use information that we collect about you or that you provide to us:\n\n'
          '• To provide you with the App, its contents, and services that you request\n'
          '• To fulfill any other purpose for which you provide it\n'
          '• To send you notices about your account\n'
          '• To improve our App and personalize your experience\n'
          '• To deliver agricultural advice tailored to your crops, location, and weather\n'
          '• To connect you with potential buyers for your produce\n'
          '• To deliver targeted advertisements\n'
          '• To carry out our obligations and enforce our rights',
    ),
    _Section(
      '3. Disclosure of your information',
      'We may disclose aggregated information that does not identify any individual without restriction. We may also disclose personal information:\n\n'
          '• To contractors, service providers, and other third parties that support our business\n'
          '• To fulfill the purpose for which you provide it\n'
          '• With your consent\n'
          '• To comply with any court order, law, or legal process\n'
          '• If we believe disclosure is necessary to protect the rights or safety of KisanVeer, our users, or others',
    ),
    _Section(
      '4. Data security',
      'We use measures designed to secure your personal information from accidental loss and from unauthorized access, use, alteration, and disclosure. Sensitive information is encrypted in transit using TLS.\n\n'
          'Unfortunately, transmission over the internet is not completely secure. While we do our best, we cannot guarantee the security of information transmitted to our App.',
    ),
    _Section(
      '5. Location data',
      'The App collects and processes real-time location with your consent, so we can provide weather forecasts, nearby market prices, and advice specific to your region. You can enable or disable location services through your device settings.',
    ),
    _Section(
      '6. Your choices',
      'You can update your privacy preferences from the Privacy section in your profile to control how your information is displayed and shared within the KisanVeer community.',
    ),
    _Section(
      "7. Children's privacy",
      'Our App is not intended for children under 13. We do not knowingly collect personal information from children under 13. If you are under 13, please do not use the App or provide any information.',
    ),
    _Section(
      '8. Changes to this policy',
      'We may update this policy from time to time. If we make material changes we will post the new policy in the App and notify you through the App or via email.',
    ),
    _Section(
      '9. Data retention',
      'We retain personal information only for as long as reasonably necessary to fulfill the purposes we collected it for, including legal, regulatory, tax, accounting, or reporting requirements. We may retain your data for longer in case of a complaint or likely litigation.',
    ),
    _Section(
      '10. Contact',
      'To ask questions or comment about this policy, email privacy@kisanveer.com.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Privacy policy', showBack: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.space16),
          children: [
            Text(
              'KisanVeer privacy policy',
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
                'Thank you for trusting us with your information.',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
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
