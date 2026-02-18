import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/services/biometric_service.dart';
import 'package:kisan_veer/utils/haptic_utils.dart';

/// Biometric login button widget with animation
/// Shows fingerprint/face icon based on available biometrics
class BiometricLoginButton extends StatefulWidget {
  final Future<void> Function() onSuccess;
  final VoidCallback? onFailed;
  final String? customMessage;
  
  const BiometricLoginButton({
    Key? key,
    required this.onSuccess,
    this.onFailed,
    this.customMessage,
  }) : super(key: key);

  @override
  State<BiometricLoginButton> createState() => _BiometricLoginButtonState();
}

class _BiometricLoginButtonState extends State<BiometricLoginButton>
    with SingleTickerProviderStateMixin {
  final BiometricService _biometricService = BiometricService();
  
  bool _isAuthenticating = false;
  bool _isAvailable = false;
  String _biometricTypeName = 'Biometric';
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _initAnimation();
    _checkAvailability();
  }
  
  void _initAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }
  
  Future<void> _checkAvailability() async {
    // Check if device supports biometrics AND user has enabled biometric login
    final isSupported = await _biometricService.isDeviceSupported();
    final canCheck = await _biometricService.canCheckBiometrics();
    final isEnabled = await _biometricService.isBiometricEnabled();
    final typeName = await _biometricService.getBiometricTypeName();
    
    if (mounted) {
      setState(() {
        // Show button only if device supports AND user has enabled biometric
        _isAvailable = isSupported && canCheck && isEnabled;
        _biometricTypeName = typeName;
      });
    }
  }
  
  Future<void> _authenticate() async {
    if (_isAuthenticating || !_isAvailable) return;
    
    setState(() => _isAuthenticating = true);
    HapticUtils.buttonPress();
    
    try {
      final result = await _biometricService.authenticate(
        reason: widget.customMessage ?? 'Authenticate to login to Kisan Veer',
      );
      
      if (result.isSuccess) {
        HapticUtils.success();
        await widget.onSuccess();
      } else {
        HapticUtils.error();
        widget.onFailed?.call();
        _showErrorSnackBar(result.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }
  
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAvailable) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        // Divider with "or" text
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.3))),
          ],
        ),
        const SizedBox(height: 20),
        
        // Biometric button
        GestureDetector(
          onTap: _authenticate,
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: _isAuthenticating
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(
                        _biometricTypeName == 'Face ID'
                            ? Icons.face
                            : Icons.fingerprint,
                        size: 36,
                        color: AppColors.primary,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Label
        Text(
          'Login with $_biometricTypeName',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

/// Settings toggle for biometric login
class BiometricSettingsToggle extends StatefulWidget {
  const BiometricSettingsToggle({Key? key}) : super(key: key);

  @override
  State<BiometricSettingsToggle> createState() => _BiometricSettingsToggleState();
}

class _BiometricSettingsToggleState extends State<BiometricSettingsToggle> {
  final BiometricService _biometricService = BiometricService();
  
  bool _isEnabled = false;
  bool _isAvailable = false;
  String _biometricTypeName = 'Biometric';
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final canCheck = await _biometricService.canCheckBiometrics();
    final isEnabled = await _biometricService.isBiometricEnabled();
    final typeName = await _biometricService.getBiometricTypeName();
    
    if (mounted) {
      setState(() {
        _isAvailable = canCheck;
        _isEnabled = isEnabled;
        _biometricTypeName = typeName;
        _isLoading = false;
      });
    }
  }
  
  Future<void> _toggleBiometric(bool value) async {
    if (!_isAvailable) return;
    
    HapticUtils.selection();
    
    if (value) {
      // Enable - requires authentication
      final success = await _biometricService.enableBiometric();
      if (success && mounted) {
        setState(() => _isEnabled = true);
        _showSnackBar('$_biometricTypeName login enabled');
      }
    } else {
      // Disable
      await _biometricService.disableBiometric();
      if (mounted) {
        setState(() => _isEnabled = false);
        _showSnackBar('$_biometricTypeName login disabled');
      }
    }
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ListTile(
        leading: Icon(Icons.fingerprint),
        title: Text('Biometric Login'),
        trailing: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    
    if (!_isAvailable) {
      return ListTile(
        leading: Icon(
          Icons.fingerprint,
          color: Colors.grey,
        ),
        title: Text(
          'Biometric Login',
          style: TextStyle(color: Colors.grey),
        ),
        subtitle: Text(
          'Not available on this device',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    
    return SwitchListTile(
      secondary: Icon(
        _biometricTypeName == 'Face ID' ? Icons.face : Icons.fingerprint,
        color: _isEnabled ? AppColors.primary : null,
      ),
      title: Text('$_biometricTypeName Login'),
      subtitle: Text(_isEnabled ? 'Enabled' : 'Disabled'),
      value: _isEnabled,
      onChanged: _toggleBiometric,
      activeColor: AppColors.primary,
    );
  }
}
