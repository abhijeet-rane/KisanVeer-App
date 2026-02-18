import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Haptic feedback utility for premium tactile interactions
/// Provides consistent haptic feedback patterns across the app
class HapticUtils {
  // Prevent instantiation
  HapticUtils._();
  
  /// Light haptic for subtle interactions (toggle, checkbox)
  static Future<void> light() async {
    if (kIsWeb) return;
    await HapticFeedback.lightImpact();
  }
  
  /// Medium haptic for standard interactions (button tap)
  static Future<void> medium() async {
    if (kIsWeb) return;
    await HapticFeedback.mediumImpact();
  }
  
  /// Heavy haptic for significant actions (delete, confirm)
  static Future<void> heavy() async {
    if (kIsWeb) return;
    await HapticFeedback.heavyImpact();
  }
  
  /// Selection change haptic (picker, slider)
  static Future<void> selection() async {
    if (kIsWeb) return;
    await HapticFeedback.selectionClick();
  }
  
  /// Success feedback pattern
  static Future<void> success() async {
    if (kIsWeb) return;
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }
  
  /// Error/warning feedback pattern
  static Future<void> error() async {
    if (kIsWeb) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }
  
  /// Notification received pattern
  static Future<void> notification() async {
    if (kIsWeb) return;
    await HapticFeedback.vibrate();
  }
  
  /// Tab change feedback
  static Future<void> tabChange() async {
    if (kIsWeb) return;
    await HapticFeedback.selectionClick();
  }
  
  /// Pull-to-refresh trigger feedback
  static Future<void> pullRefresh() async {
    if (kIsWeb) return;
    await HapticFeedback.mediumImpact();
  }
  
  /// Button press feedback (call before action)
  static Future<void> buttonPress() async {
    if (kIsWeb) return;
    await HapticFeedback.lightImpact();
  }
}

/// Extension to easily add haptic feedback to callbacks
extension HapticCallback on VoidCallback {
  /// Wrap callback with light haptic
  VoidCallback withLightHaptic() => () {
    HapticUtils.light();
    this();
  };
  
  /// Wrap callback with medium haptic
  VoidCallback withMediumHaptic() => () {
    HapticUtils.medium();
    this();
  };
  
  /// Wrap callback with selection haptic
  VoidCallback withSelectionHaptic() => () {
    HapticUtils.selection();
    this();
  };
}
