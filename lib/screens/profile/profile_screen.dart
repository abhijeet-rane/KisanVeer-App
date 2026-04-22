import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_motion.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/user_model.dart';
import 'package:kisan_veer/screens/auth/login_screen.dart';
import 'package:kisan_veer/screens/notifications/notifications_screen.dart';
import 'package:kisan_veer/screens/profile/change_password_screen.dart';
import 'package:kisan_veer/screens/profile/edit_profile_screen.dart';
import 'package:kisan_veer/screens/profile/help_center_screen.dart';
import 'package:kisan_veer/screens/profile/privacy_policy_screen.dart';
import 'package:kisan_veer/screens/profile/privacy_settings_screen.dart';
import 'package:kisan_veer/screens/profile/report_problem_screen.dart';
import 'package:kisan_veer/screens/profile/terms_of_service_screen.dart';
import 'package:kisan_veer/services/auth_service.dart';
import 'package:kisan_veer/services/cache_service.dart';
import 'package:kisan_veer/services/offline_storage_service.dart';
import 'package:kisan_veer/utils/app_logger.dart';
import 'package:kisan_veer/widgets/biometric_login_button.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';

/// V2 profile & settings screen.
///
/// Visual rhythm: brand-gradient hero with large avatar → sectioned
/// settings list in elevated cards → destructive sign-out. All
/// navigation uses [AppPageRoute] for consistent motion.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = true;
  String _selectedLanguage = 'English';
  bool _notificationsEnabled = true;

  static const List<String> _languages = ['English', 'Hindi', 'Marathi'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUserModel();
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('Error loading user data', tag: 'Profile', error: e);
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoute<void>(
          builder: (_) => const LoginScreen(),
          transition: AppPageTransition.fadeThrough,
        ),
        (route) => false,
      );
    } catch (e) {
      AppLogger.e('Error signing out', tag: 'Profile', error: e);
      if (!mounted) return;
      AppSnackBar.error(context, 'Could not sign out. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const AppLoadingState(message: 'Loading your profile…')
          : RefreshIndicator(
              onRefresh: _loadUserData,
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: _buildHero()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.space16,
                      AppSpacing.space24,
                      AppSpacing.space16,
                      AppSpacing.space24,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildAccountSection(),
                        const SizedBox(height: AppSpacing.space20),
                        _buildAppSection(),
                        const SizedBox(height: AppSpacing.space20),
                        _buildSupportSection(),
                        const SizedBox(height: AppSpacing.space24),
                        AppButton(
                          label: 'Sign out',
                          variant: AppButtonVariant.danger,
                          size: AppButtonSize.lg,
                          isFullWidth: true,
                          leadingIcon: Icons.logout_rounded,
                          onPressed: _confirmSignOut,
                        ).animate().fadeIn(
                          duration: AppMotion.base,
                          delay: const Duration(milliseconds: 400),
                        ),
                        const SizedBox(height: AppSpacing.space16),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ─── Hero ────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    final user = _currentUser;
    final name = user?.name ?? 'Welcome';
    final email = user?.email ?? '';
    final initials = (name.isNotEmpty ? name[0] : 'U').toUpperCase();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.space24,
        MediaQuery.of(context).padding.top + AppSpacing.space16,
        AppSpacing.space24,
        AppSpacing.space32,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.brandGradient,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.xxl),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile',
                style: AppTextStyles.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _buildHeroAction(
                icon: Icons.notifications_outlined,
                onTap: () => Navigator.of(
                  context,
                ).push(AppPageRoute.of(const NotificationsScreen())),
                tooltip: 'Notifications',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space24),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadii.brFull,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: user != null && user.photoUrl.isNotEmpty
                  ? Image.network(
                      user.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => _initialsAvatar(initials),
                    )
                  : _initialsAvatar(initials),
            ),
          ).animate().scale(
            duration: AppMotion.slow,
            curve: Curves.easeOutBack,
          ),
          const SizedBox(height: AppSpacing.space16),
          Text(
            name,
            style: AppTextStyles.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(
            duration: AppMotion.slow,
            delay: const Duration(milliseconds: 100),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space4),
            Text(
              email,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ).animate().fadeIn(
              duration: AppMotion.slow,
              delay: const Duration(milliseconds: 200),
            ),
          ],
          const SizedBox(height: AppSpacing.space20),
          _EditProfileButton(
            onPressed: () async {
              final result = await Navigator.of(
                context,
              ).push(AppPageRoute.of(const EditProfileScreen()));
              if (result != null) await _loadUserData();
            },
          ).animate().fadeIn(
            duration: AppMotion.slow,
            delay: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _initialsAvatar(String initials) {
    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white),
      child: Text(
        initials,
        style: AppTextStyles.displaySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildHeroAction({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: AppRadii.brFull,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.brFull,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space8),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  // ─── Settings sections ──────────────────────────────────────────────────
  Widget _buildAccountSection() {
    return _SettingsSection(
      title: 'Account',
      icon: Icons.person_outline_rounded,
      items: [
        _SettingRow(
          icon: Icons.edit_outlined,
          title: 'Edit profile',
          onTap: () async {
            final result = await Navigator.of(
              context,
            ).push(AppPageRoute.of(const EditProfileScreen()));
            if (result != null) await _loadUserData();
          },
        ),
        _SettingRow(
          icon: Icons.lock_outline_rounded,
          title: 'Change password',
          onTap: () => Navigator.of(
            context,
          ).push(AppPageRoute.of(const ChangePasswordScreen())),
        ),
        const _BiometricRow(),
        _SettingRow(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy',
          onTap: () => Navigator.of(
            context,
          ).push(AppPageRoute.of(const PrivacySettingsScreen())),
        ),
        _SettingRow(
          icon: Icons.notifications_outlined,
          title: 'Push notifications',
          trailing: Switch.adaptive(
            value: _notificationsEnabled,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _notificationsEnabled = v),
          ),
          onTap: () =>
              setState(() => _notificationsEnabled = !_notificationsEnabled),
        ),
      ],
    ).animate().fadeIn(duration: AppMotion.base);
  }

  Widget _buildAppSection() {
    return _SettingsSection(
      title: 'App',
      icon: Icons.tune_rounded,
      items: [
        _SettingRow(
          icon: Icons.language_outlined,
          title: 'Language',
          subtitle: _selectedLanguage,
          onTap: _showLanguageSheet,
        ),
        _SettingRow(
          icon: Icons.cleaning_services_outlined,
          title: 'Clear cache',
          subtitle: 'Remove cached market data and listings',
          onTap: _showClearCacheDialog,
        ),
      ],
    ).animate().fadeIn(
      duration: AppMotion.base,
      delay: const Duration(milliseconds: 100),
    );
  }

  Widget _buildSupportSection() {
    return _SettingsSection(
      title: 'Support',
      icon: Icons.help_outline_rounded,
      items: [
        _SettingRow(
          icon: Icons.live_help_outlined,
          title: 'Help center',
          onTap: () => Navigator.of(
            context,
          ).push(AppPageRoute.of(const HelpCenterScreen())),
        ),
        _SettingRow(
          icon: Icons.report_problem_outlined,
          title: 'Report a problem',
          onTap: () => Navigator.of(
            context,
          ).push(AppPageRoute.of(const ReportProblemScreen())),
        ),
        _SettingRow(
          icon: Icons.description_outlined,
          title: 'Terms of service',
          onTap: () => Navigator.of(
            context,
          ).push(AppPageRoute.of(const TermsOfServiceScreen())),
        ),
        _SettingRow(
          icon: Icons.policy_outlined,
          title: 'Privacy policy',
          onTap: () => Navigator.of(
            context,
          ).push(AppPageRoute.of(const PrivacyPolicyScreen())),
        ),
      ],
    ).animate().fadeIn(
      duration: AppMotion.base,
      delay: const Duration(milliseconds: 200),
    );
  }

  // ─── Dialogs ────────────────────────────────────────────────────────────
  void _showLanguageSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xxl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.space16,
            horizontal: AppSpacing.space8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: AppRadii.brFull,
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                ),
                child: Row(
                  children: [
                    Text(
                      'Language',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              ..._languages.map(
                (lang) => ListTile(
                  title: Text(lang, style: AppTextStyles.bodyLarge),
                  trailing: lang == _selectedLanguage
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () {
                    setState(() => _selectedLanguage = lang);
                    Navigator.pop(ctx);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Clear cache'),
        content: const Text(
          'This will remove cached market data, product listings, and '
          'other temporary files. Your account stays signed in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await _clearAppCache();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAppCache() async {
    try {
      await CacheService().clearCache();
      await OfflineStorageService().clearAll();
      if (!mounted) return;
      AppSnackBar.success(context, 'Cache cleared');
    } catch (e) {
      AppLogger.e('Failed to clear cache', tag: 'Profile', error: e);
      if (!mounted) return;
      AppSnackBar.error(context, 'Could not clear cache');
    }
  }

  void _confirmSignOut() {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          "You'll need to sign in again to use the app. Any cached data "
          "will remain on this device.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _signOut();
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space8,
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.space8),
              Text(
                title.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.outlineVariant,
                    indent: AppSpacing.space56,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space12,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: AppRadii.brMd,
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BiometricRow extends StatelessWidget {
  const _BiometricRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space8,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              borderRadius: AppRadii.brMd,
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Text(
              'Biometric login',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const BiometricSettingsToggle(),
        ],
      ),
    );
  }
}

class _EditProfileButton extends StatelessWidget {
  const _EditProfileButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: AppRadii.brFull,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadii.brFull,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_outlined, color: Colors.white, size: 16),
              const SizedBox(width: AppSpacing.space8),
              Text(
                'Edit profile',
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
