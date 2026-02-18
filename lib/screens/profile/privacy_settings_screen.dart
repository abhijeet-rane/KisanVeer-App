import 'package:flutter/material.dart';
import 'package:kisan_veer/models/privacy_settings_model.dart';
import 'package:kisan_veer/services/profile_service.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/widgets/custom_button.dart';
import 'package:kisan_veer/widgets/custom_card.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final ProfileService _profileService = ProfileService();

  bool _isLoading = true;
  bool _isSaving = false;

  // Privacy settings
  late PrivacySettingsModel _settings;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await _profileService.getPrivacySettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _settings = PrivacySettingsModel();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading settings: $e')));
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final success = await _profileService.updatePrivacySettings(_settings);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Privacy settings saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save privacy settings'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Non-async wrapper for _saveSettings
  void _handleSaveSettings() {
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Information
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Your Privacy Matters',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Control how your information is shared with other users and the KisanVeer community.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Location Privacy
                    _buildSectionTitle('Location Privacy'),
                    CustomCard(
                      child: SwitchListTile(
                        title: const Text('Share Location'),
                        subtitle: const Text(
                          'Allow others to see your general location on maps',
                        ),
                        value: _settings.shareLocation,
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          setState(() {
                            _settings = _settings.copyWith(
                              shareLocation: value,
                            );
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Online Status
                    _buildSectionTitle('Online Status'),
                    CustomCard(
                      child: SwitchListTile(
                        title: const Text('Show Online Status'),
                        subtitle: const Text(
                          'Let others know when you are active on KisanVeer',
                        ),
                        value: _settings.showOnlineStatus,
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          setState(() {
                            _settings = _settings.copyWith(
                              showOnlineStatus: value,
                            );
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Profile Visibility
                    _buildSectionTitle('Profile Visibility'),
                    CustomCard(
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text('Everyone'),
                            subtitle: const Text(
                              'All KisanVeer users can view your profile',
                            ),
                            value: 'all',
                            groupValue: _settings.profileVisibility,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings.copyWith(
                                  profileVisibility: value,
                                );
                              });
                            },
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            title: const Text('Connections Only'),
                            subtitle: const Text(
                              'Only users you connect with can view your profile',
                            ),
                            value: 'connections',
                            groupValue: _settings.profileVisibility,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings.copyWith(
                                  profileVisibility: value,
                                );
                              });
                            },
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            title: const Text('Nobody'),
                            subtitle: const Text(
                              'Your profile will not be visible to other users',
                            ),
                            value: 'none',
                            groupValue: _settings.profileVisibility,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings.copyWith(
                                  profileVisibility: value,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Messaging Privacy
                    _buildSectionTitle('Messaging Privacy'),
                    CustomCard(
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text('Everyone'),
                            subtitle: const Text(
                              'All KisanVeer users can message you',
                            ),
                            value: 'all',
                            groupValue: _settings.allowMessagesFrom,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings.copyWith(
                                  allowMessagesFrom: value,
                                );
                              });
                            },
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            title: const Text('Connections Only'),
                            subtitle: const Text(
                              'Only users you connect with can message you',
                            ),
                            value: 'connections',
                            groupValue: _settings.allowMessagesFrom,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings.copyWith(
                                  allowMessagesFrom: value,
                                );
                              });
                            },
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            title: const Text('Nobody'),
                            subtitle: const Text('Nobody can message you'),
                            value: 'none',
                            groupValue: _settings.allowMessagesFrom,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings.copyWith(
                                  allowMessagesFrom: value,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Crop Data Sharing
                    _buildSectionTitle('Crop Data Sharing'),
                    CustomCard(
                      child: SwitchListTile(
                        title: const Text('Share Crop Data'),
                        subtitle: const Text(
                          'Share information about your crops with the community',
                        ),
                        value: _settings.shareCropData,
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          setState(() {
                            _settings = _settings.copyWith(
                              shareCropData: value,
                            );
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    CustomButton(
                      onPressed: _isSaving ? () {} : _handleSaveSettings,
                      text: _isSaving ? 'Saving...' : 'Save Settings',
                      isLoading: _isSaving,
                      width: double.infinity,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
