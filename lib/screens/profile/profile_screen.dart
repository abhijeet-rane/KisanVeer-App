import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/user_model.dart';
import 'package:kisan_veer/screens/auth/login_screen.dart';
import 'package:kisan_veer/screens/profile/edit_profile_screen.dart';
import 'package:kisan_veer/screens/profile/change_password_screen.dart';
import 'package:kisan_veer/screens/profile/privacy_settings_screen.dart';
import 'package:kisan_veer/screens/profile/help_center_screen.dart';
import 'package:kisan_veer/screens/profile/report_problem_screen.dart';
import 'package:kisan_veer/screens/profile/terms_of_service_screen.dart';
import 'package:kisan_veer/screens/profile/privacy_policy_screen.dart';
import 'package:kisan_veer/services/auth_service.dart';
import 'package:kisan_veer/widgets/custom_button.dart';
import 'package:kisan_veer/widgets/custom_card.dart';
import 'package:kisan_veer/widgets/biometric_login_button.dart';
import 'package:google_fonts/google_fonts.dart';

import '../notifications/notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isDarkMode = false;
  String _selectedLanguage = 'English';
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _settingsKey = GlobalKey();
  
  final List<String> _languages = [
    'English',
    'Hindi',
    'Marathi',
  ];

  final List<Map<String, dynamic>> _settingsSections = [
    {
      'title': 'Account Settings',
      'icon': Icons.person_outline,
      'items': [
        {'title': 'Edit Profile', 'icon': Icons.edit_outlined},
        {'title': 'Change Password', 'icon': Icons.lock_outlined},
        {'title': 'Biometric Login', 'icon': Icons.fingerprint},
        {'title': 'Privacy', 'icon': Icons.privacy_tip_outlined},
        {'title': 'Notifications', 'icon': Icons.notifications_outlined},
      ],
    },
    {
      'title': 'App Settings',
      'icon': Icons.settings_outlined,
      'items': [
        {'title': 'Language', 'icon': Icons.language_outlined},
        {'title': 'Dark Mode', 'icon': Icons.dark_mode_outlined},
        {'title': 'Clear Cache', 'icon': Icons.delete_outline},
      ],
    },
    {
      'title': 'Support',
      'icon': Icons.help_outline,
      'items': [
        {'title': 'Help Center', 'icon': Icons.live_help_outlined},
        {'title': 'Report a Problem', 'icon': Icons.report_problem_outlined},
        {'title': 'Terms of Service', 'icon': Icons.description_outlined},
        {'title': 'Privacy Policy', 'icon': Icons.policy_outlined},
      ],
    },
  ];

  void _scrollToSettings() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderObject? renderObject = _settingsKey.currentContext
          ?.findRenderObject();
      if (renderObject is RenderBox) {
        _scrollController.animateTo(
          renderObject
              .localToGlobal(Offset.zero, ancestor: context.findRenderObject())
              .dy + _scrollController.offset,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController.dispose();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = await _authService.getCurrentUserModel();
      if (user == null) {
        print("❌ No user data retrieved. User might not be logged in.");
      } else {
        print("✅ User data retrieved: ${user.name}, ${user.email}");
      }

      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Scrollable.ensureVisible(
                _settingsKey.currentContext!,
                duration: Duration(milliseconds: 800), // Smooth scroll effect
                curve: Curves.easeInOut,
              );
            },
          ),

        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationsScreen()),
                );
              }

          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _buildProfileHeader(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 5.0),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Settings",
                                key: _settingsKey,
                                style: GoogleFonts.poppins(
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.9,
                                ),
                              ),
                              SizedBox(height: 4), // Space before underline
                              Container(
                                width: 112, // Small underline effect
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.blue, // Highlight color
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        _buildSettingsList().animate().fadeIn(
                          duration: const Duration(milliseconds: 500),
                          delay: const Duration(milliseconds: 600),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        CustomButton(
                          text: 'Sign Out',
                          onPressed: _signOut,
                          width: double.infinity,
                          buttonType: ButtonType.outlined,
                          leadingIcon: Icons.logout,
                        ).animate().fadeIn(
                          duration: const Duration(milliseconds: 500),
                          delay: const Duration(milliseconds: 700),
                        ),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          const SizedBox(height: 16),
          
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage: _currentUser?.photoUrl.isNotEmpty == true
                ? NetworkImage(_currentUser!.photoUrl) as ImageProvider<Object>
                : null,
            child: (_currentUser?.photoUrl.isEmpty ?? true)
                ? Text(
                    _currentUser?.name != null
                        ? _currentUser!.name.substring(0, 1).toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ).animate().fadeIn(
            duration: const Duration(milliseconds: 500),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            _currentUser?.name ?? 'User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(
            duration: const Duration(milliseconds: 500),
            delay: const Duration(milliseconds: 100),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            _currentUser?.email ?? 'user@example.com',
            style: TextStyle(
              color: Colors.white.withAlpha((0.9 * 255).round()),
              fontSize: 16,
            ),
          ).animate().fadeIn(
            duration: const Duration(milliseconds: 500),
            delay: const Duration(milliseconds: 200),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSettingsList() {
    return Column(
      children: List.generate(
        _settingsSections.length,
        (sectionIndex) {
          final section = _settingsSections[sectionIndex];
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      section['icon'],
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      section['title'],
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              CustomCard(
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: section['items'].length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = section['items'][index];
                    
                    // Use BiometricSettingsToggle for biometric setting
                    if (item['title'] == 'Biometric Login') {
                      return const BiometricSettingsToggle();
                    }
                    
                    return ListTile(
                      leading: Icon(
                        item['icon'],
                        color: AppColors.textSecondary,
                      ),
                      title: Text(
                        item['title'],
                        style: AppTextStyles.bodyMedium,
                      ),
                      trailing: _buildSettingControl(item['title']),
                      onTap: () {
                        // Handle setting tap
                        _handleSettingTap(item['title']);
                      },
                    );
                  },
                ),
              ),
              if (sectionIndex < _settingsSections.length - 1)
                const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
  
  Widget? _buildSettingControl(String settingTitle) {
    switch (settingTitle) {
      case 'Dark Mode':
        return Switch(
          value: _isDarkMode,
          activeColor: AppColors.primary,
          onChanged: (value) {
            setState(() {
              _isDarkMode = value;
            });
          },
        );
      case 'Biometric Login':
        return null; // Will be handled specially
      case 'Notifications':
        return Switch(
          value: _notificationsEnabled,
          activeColor: AppColors.primary,
          onChanged: (value) {
            setState(() {
              _notificationsEnabled = value;
            });
          },
        );
      case 'Language':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedLanguage,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        );
      default:
        return const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textSecondary,
        );
    }
  }
  
  void _handleSettingTap(String settingTitle) {
    // Handle different settings
    switch (settingTitle) {
      case 'Language':
        _showLanguageDialog();
        break;
      case 'Edit Profile':
        // Navigate to profile edit screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EditProfileScreen(),
          ),
        ).then((value) {
          if (value == true) {
            // Reload user data after profile edit
            _loadUserData();
          }
        });
        break;
      case 'Change Password':
        // Navigate to change password screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChangePasswordScreen(),
          ),
        );
        break;
      case 'Privacy':
        // Navigate to privacy settings
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PrivacySettingsScreen(),
          ),
        );
        break;
      case 'Help Center':
        // Navigate to help center
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HelpCenterScreen(),
          ),
        );
        break;
      case 'Report a Problem':
        // Navigate to problem reporting
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ReportProblemScreen(),
          ),
        );
        break;
      case 'Terms of Service':
        // Show terms of service
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TermsOfServiceScreen(),
          ),
        );
        break;
      case 'Privacy Policy':
        // Show privacy policy
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PrivacyPolicyScreen(),
          ),
        );
        break;
      case 'Clear Cache':
        _showClearCacheDialog();
        break;
      default:
        // Handle other settings
        break;
    }
  }
  
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _languages.length,
            itemBuilder: (context, index) {
              final language = _languages[index];
              return ListTile(
                title: Text(language),
                trailing: language == _selectedLanguage
                    ? const Icon(
                        Icons.check,
                        color: AppColors.primary,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    _selectedLanguage = language;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all cached data and may sign you out. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Clear cache logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
