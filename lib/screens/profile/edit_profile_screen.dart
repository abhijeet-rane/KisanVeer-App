import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_motion.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/user_model.dart';
import 'package:kisan_veer/services/profile_service.dart';
import 'package:kisan_veer/utils/app_logger.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

/// V2 edit profile screen.
///
/// Sectioned layout (Personal → Address → Crops) inside lightly
/// elevated cards, avatar stays pinned in a brand-gradient header
/// with camera affordance.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController(text: 'Maharashtra');
  final _pincodeController = TextEditingController();

  final ProfileService _profileService = ProfileService();

  List<String> _availableCrops = [];
  List<String> _selectedCrops = [];

  File? _imageFile;
  bool _isUploading = false;
  bool _isSaving = false;
  bool _isLoading = true;

  UserModel? _userModel;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    final user = await _profileService.getUserProfile();
    if (!mounted) return;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phoneNumber;
      _addressController.text = user.address;
      _cityController.text = user.city;
      _stateController.text = user.state.isEmpty ? 'Maharashtra' : user.state;
      _pincodeController.text = user.pincode;
      setState(() {
        _selectedCrops = List.from(user.crops);
        _availableCrops = _profileService.getMaharashtraCrops();
        _isLoading = false;
        _userModel = user;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;
    setState(() => _isUploading = true);
    try {
      final imageUrl = await _profileService.uploadProfileImage(_imageFile!);
      if (!mounted) return imageUrl;
      if (imageUrl != null) {
        _toast('Profile photo uploaded', color: AppColors.success);
      }
      return imageUrl;
    } catch (e) {
      AppLogger.e(
        'Error uploading profile image',
        tag: 'EditProfile',
        error: e,
      );
      if (!mounted) return null;
      _toast('Failed to upload photo', color: AppColors.danger);
      return null;
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    String photoUrl = _userModel?.photoUrl ?? '';
    try {
      if (_imageFile != null) {
        final uploadedUrl = await _uploadImage();
        if (uploadedUrl != null) photoUrl = uploadedUrl;
      }

      final updatedUser = UserModel(
        uid: _userModel?.uid ?? '',
        email: _userModel?.email ?? '',
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        photoUrl: photoUrl,
        userType: _userModel?.userType ?? 'farmer',
        createdAt: _userModel?.createdAt ?? DateTime.now(),
        lastActive: DateTime.now(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        crops: _selectedCrops,
      );

      final success = await _profileService.updateUserProfile(updatedUser);
      if (!mounted) return;

      if (success) {
        _toast('Profile updated', color: AppColors.success);
        Navigator.pop(context, updatedUser);
      } else {
        _toast('Could not update profile. Try again.', color: AppColors.danger);
      }
    } catch (e) {
      AppLogger.e('Error saving profile', tag: 'EditProfile', error: e);
      if (!mounted) return;
      _toast('Error saving profile', color: AppColors.danger);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (image != null) {
        setState(() => _imageFile = File(image.path));
      }
    } catch (e) {
      AppLogger.e('Error picking image', tag: 'EditProfile', error: e);
      if (!mounted) return;
      _toast('Failed to pick image', color: AppColors.danger);
    }
  }

  void _toast(String message, {required Color color}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const AppAppBar(title: 'Edit profile', showBack: true),
        body: const AppLoadingState(message: 'Loading your profile…'),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Edit profile', showBack: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space32,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAvatarPicker(),
                const SizedBox(height: AppSpacing.space24),
                _SectionCard(
                  title: 'Personal',
                  icon: Icons.person_outline_rounded,
                  children: [
                    AppTextField(
                      controller: _nameController,
                      label: 'Full name',
                      prefixIcon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? 'Enter your name'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    AppTextField(
                      controller: _phoneController,
                      label: 'Phone number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().length < 10)
                          ? 'Enter a valid phone number'
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space20),
                _SectionCard(
                  title: 'Address',
                  icon: Icons.home_outlined,
                  children: [
                    AppTextField(
                      controller: _addressController,
                      label: 'Address',
                      prefixIcon: Icons.place_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    AppTextField(
                      controller: _cityController,
                      label: 'City',
                      prefixIcon: Icons.location_city_outlined,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    AppTextField(
                      controller: _stateController,
                      label: 'State',
                      prefixIcon: Icons.map_outlined,
                      readOnly: true,
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    AppTextField(
                      controller: _pincodeController,
                      label: 'Pincode',
                      prefixIcon: Icons.pin_drop_outlined,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space20),
                _SectionCard(
                  title: 'My crops',
                  icon: Icons.eco_outlined,
                  subtitle:
                      'Select the crops you grow so the app can tailor '
                      'market prices and weather advice.',
                  children: [
                    MultiSelectBottomSheetField<String>(
                      initialValue: _selectedCrops,
                      items: _availableCrops
                          .map(
                            (crop) => MultiSelectItem<String>(
                              crop,
                              crop[0].toUpperCase() + crop.substring(1),
                            ),
                          )
                          .toList(),
                      title: const Text('Select crops'),
                      buttonText: const Text('Tap to pick crops'),
                      buttonIcon: const Icon(
                        Icons.eco_rounded,
                        color: AppColors.primary,
                      ),
                      searchable: true,
                      listType: MultiSelectListType.CHIP,
                      onConfirm: (values) {
                        setState(() {
                          _selectedCrops = values.cast<String>();
                        });
                      },
                      chipDisplay: MultiSelectChipDisplay<String>(
                        onTap: (value) {
                          setState(() {
                            _selectedCrops.remove(value);
                          });
                        },
                        chipColor: AppColors.primaryContainer,
                        textStyle: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: AppRadii.brMd,
                        border: Border.all(
                          color: AppColors.outlineVariant,
                          width: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space32),
                AppButton(
                  label: 'Save changes',
                  size: AppButtonSize.lg,
                  isFullWidth: true,
                  isLoading: _isSaving,
                  leadingIcon: Icons.check_rounded,
                  onPressed: _saveProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.brandGradient,
              ),
              borderRadius: AppRadii.brFull,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: ClipOval(
              child: _imageFile != null
                  ? Image.file(_imageFile!, fit: BoxFit.cover)
                  : (_userModel?.photoUrl.isNotEmpty == true
                        ? Image.network(
                            _userModel!.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => _initials(),
                          )
                        : _initials()),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              color: AppColors.primary,
              borderRadius: AppRadii.brFull,
              child: InkWell(
                onTap: _isUploading ? null : _pickImage,
                borderRadius: AppRadii.brFull,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.space8),
                  child: _isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initials() {
    final name = _nameController.text;
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.displayMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.space8),
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.space4),
            Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space16),
          ...children,
        ],
      ),
    ).animate().fadeIn(duration: AppMotion.base);
  }
}
