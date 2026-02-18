import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kisan_veer/models/user_model.dart';
import 'package:kisan_veer/services/profile_service.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;

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

  Future<void> _fetchProfile() async {
    final user = await _profileService.getUserProfile();
    if (user != null) {
      setState(() {
        _nameController = TextEditingController(text: user.name);
        _phoneController = TextEditingController(text: user.phoneNumber);
        _addressController = TextEditingController(text: user.address);
        _cityController = TextEditingController(text: user.city);
        _stateController = TextEditingController(text: user.state);
        _pincodeController = TextEditingController(text: user.pincode);
        _selectedCrops = List.from(user.crops);
        _availableCrops = _profileService.getMaharashtraCrops();
        _isLoading = false;
        _userModel = user;
      });
    }
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

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    setState(() {
      _isUploading = true;
    });

    try {
      final imageUrl = await _profileService.uploadProfileImage(_imageFile!);
      if (imageUrl != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        return imageUrl;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
    return null;
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    String photoUrl = _userModel?.photoUrl ?? '';
    try {
      // If there's a new image, upload it first
      if (_imageFile != null) {
        final uploadedUrl = await _uploadImage();
        if (uploadedUrl != null) {
          photoUrl = uploadedUrl;
        }
      }

      // Create updated user model
      final updatedUser = UserModel(
        uid: _userModel?.uid ?? '',
        email: _userModel?.email ?? '',
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        photoUrl: photoUrl,
        userType: _userModel?.userType ?? 'farmer',
        createdAt: _userModel?.createdAt ?? DateTime.now(),
        lastActive: DateTime.now(),
        address: _addressController.text,
        city: _cityController.text,
        state: _stateController.text,
        pincode: _pincodeController.text,
        crops: _selectedCrops,
      );

      // Save to database
      final success = await _profileService.updateUserProfile(updatedUser);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, updatedUser); // Return success to previous screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating profile. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image Section
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!) as ImageProvider<Object>
                        : (_userModel?.photoUrl.isNotEmpty == true
                            ? NetworkImage(_userModel!.photoUrl) as ImageProvider<Object>
                            : null),
                    child: _imageFile == null && (_userModel?.photoUrl.isEmpty ?? true)
                        ? Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text.substring(0, 1).toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _isUploading ? null : _pickImage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Personal Information
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _nameController,
              label: 'Full Name',
              prefixIcon: Icons.person,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _phoneController,
              label: 'Phone Number',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 30),

            // Address Information
            const Text(
              'Address Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _addressController,
              label: 'Address',
              prefixIcon: Icons.home,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _cityController,
              label: 'City',
              prefixIcon: Icons.location_city,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _stateController,
              label: 'State',
              prefixIcon: Icons.map,
              initialValue: 'Maharashtra',
              readOnly: true,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              controller: _pincodeController,
              label: 'Pincode',
              prefixIcon: Icons.pin_drop,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 30),

            // Save Button
            CustomButton(
              onPressed: _isSaving
                  ? () {}
                  : () {
                      _saveProfile();
                    },
              text: _isSaving ? 'Saving...' : 'Save Changes',
              isLoading: _isSaving,
              width: double.infinity,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    String? initialValue,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: maxLines > 1 ? 16 : 0,
          horizontal: 16,
        ),
      ),
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }
}
