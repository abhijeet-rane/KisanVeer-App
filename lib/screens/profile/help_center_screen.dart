import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/screens/profile/report_problem_screen.dart';
import 'package:kisan_veer/utils/app_logger.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// V2 help-center screen.
///
/// Three-section layout: quick contact tiles, FAQs in expandable cards,
/// and additional resources. Uses the shared v2 design system for a
/// consistent look-and-feel.
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  static const List<_Faq> _faqs = [
    _Faq(
      question: 'How do I add or change the crops I grow?',
      answer:
          'Open your Profile, tap Edit profile, and choose the crops you grow from the list.',
    ),
    _Faq(
      question: 'How does the weather forecast help me with farming?',
      answer:
          'The forecast turns weather data into crop-specific advice so you know when to irrigate, spray, or harvest to protect your yield.',
    ),
    _Faq(
      question: 'Can I sell my produce directly through this app?',
      answer:
          'Yes. Use the Market tab to list your produce and connect with nearby buyers.',
    ),
    _Faq(
      question: 'How do I get financial assistance for farming?',
      answer:
          'Visit the Finance tab to view loans, insurance, and subsidies targeted at farmers, and apply right from the app.',
    ),
    _Faq(
      question: 'How do I connect with other farmers?',
      answer:
          'The Community tab lets you join crop- and location-based groups and share best practices.',
    ),
  ];

  static const List<_Contact> _contacts = [
    _Contact(
      icon: Icons.mail_outline_rounded,
      label: 'Email support',
      value: 'support@kisanveer.com',
      kind: _ContactKind.email,
    ),
    _Contact(
      icon: Icons.call_outlined,
      label: 'Call helpline',
      value: '+91 8000 FARMER',
      kind: _ContactKind.phone,
    ),
    _Contact(
      icon: Icons.message_outlined,
      label: 'WhatsApp support',
      value: '+91 9000 FARMER',
      kind: _ContactKind.whatsapp,
    ),
    _Contact(
      icon: Icons.bug_report_outlined,
      label: 'Report a problem',
      value: 'Send us a detailed report',
      kind: _ContactKind.screen,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Help center', showBack: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.space16),
          children: [
            _Hero(),
            const SizedBox(height: AppSpacing.space24),
            Text(
              'Contact support',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (int i = 0; i < _contacts.length; i++) ...[
                    _ContactRow(
                      contact: _contacts[i],
                      onTap: () => _handleContact(_contacts[i]),
                    ),
                    if (i < _contacts.length - 1)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        indent: AppSpacing.space56,
                        color: AppColors.outlineVariant,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space32),
            Text(
              'Frequently asked',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            for (final faq in _faqs) ...[
              AppCard(
                padding: EdgeInsets.zero,
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space16,
                      vertical: AppSpacing.space4,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(
                      AppSpacing.space16,
                      0,
                      AppSpacing.space16,
                      AppSpacing.space16,
                    ),
                    iconColor: AppColors.primary,
                    collapsedIconColor: AppColors.onSurfaceVariant,
                    title: Text(
                      faq.question,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          faq.answer,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space12),
            ],
            const SizedBox(height: AppSpacing.space24),
          ],
        ),
      ),
    );
  }

  Future<void> _handleContact(_Contact contact) async {
    try {
      switch (contact.kind) {
        case _ContactKind.email:
          await launchUrl(
            Uri(
              scheme: 'mailto',
              path: contact.value,
              queryParameters: {'subject': 'Support request — KisanVeer'},
            ),
          );
          break;
        case _ContactKind.phone:
          await launchUrl(
            Uri(
              scheme: 'tel',
              path: contact.value.replaceAll(RegExp(r'\s+'), ''),
            ),
          );
          break;
        case _ContactKind.whatsapp:
          await launchUrl(
            Uri.parse(
              'https://wa.me/${contact.value.replaceAll(RegExp(r'\s+'), '')}',
            ),
          );
          break;
        case _ContactKind.screen:
          if (!mounted) return;
          Navigator.of(
            context,
          ).push(AppPageRoute.of(const ReportProblemScreen()));
          break;
      }
    } catch (e) {
      AppLogger.e('Help contact failed', tag: 'HelpCenter', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that action')),
      );
    }
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.brandGradient,
        ),
        borderRadius: AppRadii.brLg,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: AppRadii.brFull,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help?',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Browse FAQs or reach out — we reply within a day.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.contact, required this.onTap});

  final _Contact contact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space12,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.6),
                borderRadius: AppRadii.brMd,
              ),
              child: Icon(contact.icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.label,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.value,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _Faq {
  const _Faq({required this.question, required this.answer});
  final String question;
  final String answer;
}

enum _ContactKind { email, phone, whatsapp, screen }

class _Contact {
  const _Contact({
    required this.icon,
    required this.label,
    required this.value,
    required this.kind,
  });

  final IconData icon;
  final String label;
  final String value;
  final _ContactKind kind;
}
