import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/privacy_settings_model.dart';
import 'package:kisan_veer/services/profile_service.dart';
import 'package:kisan_veer/utils/app_logger.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';

/// V2 privacy settings screen.
///
/// Grouped cards for each privacy area, with switches and segmented
/// radios rendered inline on a consistent surface.
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final ProfileService _profileService = ProfileService();

  bool _isLoading = true;
  bool _isSaving = false;
  late PrivacySettingsModel _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _profileService.getPrivacySettings();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('Load privacy settings failed', tag: 'Privacy', error: e);
      if (!mounted) return;
      setState(() {
        _settings = PrivacySettingsModel();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final ok = await _profileService.updatePrivacySettings(_settings);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Privacy settings saved' : 'Could not save — try again',
          ),
          backgroundColor: ok ? AppColors.success : AppColors.danger,
        ),
      );
    } catch (e) {
      AppLogger.e('Save privacy settings failed', tag: 'Privacy', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving — please try again'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Privacy', showBack: true),
      body: _isLoading
          ? const AppLoadingState(message: 'Loading preferences…')
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.space16),
                children: [
                  _Hero(),
                  const SizedBox(height: AppSpacing.space24),
                  _buildSwitchCard(
                    icon: Icons.location_on_outlined,
                    title: 'Share my location',
                    subtitle: 'Let others see your general location on maps.',
                    value: _settings.shareLocation,
                    onChanged: (v) => setState(
                      () => _settings = _settings.copyWith(shareLocation: v),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  _buildSwitchCard(
                    icon: Icons.circle_rounded,
                    title: 'Show online status',
                    subtitle: 'Let others see when you are active.',
                    value: _settings.showOnlineStatus,
                    onChanged: (v) => setState(
                      () => _settings = _settings.copyWith(showOnlineStatus: v),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space20),
                  _buildRadioCard(
                    title: 'Profile visibility',
                    subtitle: 'Who can view your profile?',
                    icon: Icons.visibility_outlined,
                    groupValue: _settings.profileVisibility,
                    options: const [
                      _RadioOption(
                        value: 'all',
                        title: 'Everyone',
                        subtitle: 'All users on KisanVeer',
                      ),
                      _RadioOption(
                        value: 'connections',
                        title: 'Connections only',
                        subtitle: 'Only users you connect with',
                      ),
                      _RadioOption(
                        value: 'none',
                        title: 'Nobody',
                        subtitle: 'Your profile is private',
                      ),
                    ],
                    onChanged: (v) => setState(
                      () =>
                          _settings = _settings.copyWith(profileVisibility: v),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  _buildRadioCard(
                    title: 'Messaging',
                    subtitle: 'Who can message you?',
                    icon: Icons.chat_outlined,
                    groupValue: _settings.allowMessagesFrom,
                    options: const [
                      _RadioOption(
                        value: 'all',
                        title: 'Everyone',
                        subtitle: 'Any user can start a chat',
                      ),
                      _RadioOption(
                        value: 'connections',
                        title: 'Connections only',
                        subtitle: 'Only connections can message',
                      ),
                      _RadioOption(
                        value: 'none',
                        title: 'Nobody',
                        subtitle: 'Block all new messages',
                      ),
                    ],
                    onChanged: (v) => setState(
                      () =>
                          _settings = _settings.copyWith(allowMessagesFrom: v),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space20),
                  _buildSwitchCard(
                    icon: Icons.eco_outlined,
                    title: 'Share crop data',
                    subtitle: 'Include your crop info in community insights.',
                    value: _settings.shareCropData,
                    onChanged: (v) => setState(
                      () => _settings = _settings.copyWith(shareCropData: v),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space32),
                  AppButton(
                    label: 'Save settings',
                    size: AppButtonSize.lg,
                    isFullWidth: true,
                    isLoading: _isSaving,
                    leadingIcon: Icons.check_rounded,
                    onPressed: _saveSettings,
                  ),
                  const SizedBox(height: AppSpacing.space16),
                ],
              ),
            ),
    );
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return AppCard(
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
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
          Switch.adaptive(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildRadioCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String groupValue,
    required List<_RadioOption> options,
    required ValueChanged<String?> onChanged,
  }) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space16,
              AppSpacing.space16,
              AppSpacing.space16,
              AppSpacing.space8,
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.space8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          for (int i = 0; i < options.length; i++) ...[
            _RadioRow(
              option: options[i],
              selected: groupValue == options[i].value,
              onTap: () => onChanged(options[i].value),
            ),
            if (i < options.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                indent: AppSpacing.space16,
                endIndent: AppSpacing.space16,
                color: AppColors.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }
}

class _RadioOption {
  const _RadioOption({
    required this.value,
    required this.title,
    required this.subtitle,
  });
  final String value;
  final String title;
  final String subtitle;
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _RadioOption option;
  final bool selected;
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
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space20),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.5),
        borderRadius: AppRadii.brLg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.primary, size: 28),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your privacy matters',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Control how your information is shared with the '
                  'KisanVeer community. Changes save after you tap Save.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onPrimaryContainer,
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
