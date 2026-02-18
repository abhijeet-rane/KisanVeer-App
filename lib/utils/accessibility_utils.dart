import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility utilities for screen reader and accessibility support
class AccessibilityUtils {
  // Prevent instantiation
  AccessibilityUtils._();
  
  /// Announce message to screen reader
  static void announce(String message, {TextDirection textDirection = TextDirection.ltr}) {
    SemanticsService.announce(message, textDirection);
  }
  
  /// Announce success message
  static void announceSuccess(String message) {
    announce('Success: $message');
  }
  
  /// Announce error message
  static void announceError(String message) {
    announce('Error: $message');
  }
}

/// Semantic wrapper for better accessibility
class SemanticWrapper extends StatelessWidget {
  final Widget child;
  final String? label;
  final String? hint;
  final String? value;
  final bool isButton;
  final bool isHeader;
  final bool isImage;
  final bool excludeSemantics;
  final VoidCallback? onTap;
  
  const SemanticWrapper({
    Key? key,
    required this.child,
    this.label,
    this.hint,
    this.value,
    this.isButton = false,
    this.isHeader = false,
    this.isImage = false,
    this.excludeSemantics = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      button: isButton,
      header: isHeader,
      image: isImage,
      excludeSemantics: excludeSemantics,
      onTap: onTap,
      child: child,
    );
  }
}

/// Accessible icon button with proper semantics
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;
  final Color? color;
  final double size;
  
  const AccessibleIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.color,
    this.size = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: IconButton(
        icon: Icon(icon, size: size, color: color),
        onPressed: onPressed,
        tooltip: semanticLabel,
      ),
    );
  }
}

/// Focus highlight for keyboard navigation
class FocusHighlight extends StatelessWidget {
  final Widget child;
  final Color highlightColor;
  final double borderRadius;
  
  const FocusHighlight({
    Key? key,
    required this.child,
    this.highlightColor = const Color(0x1F000000),
    this.borderRadius = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Focus(
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: isFocused
                  ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                  : null,
            ),
            child: child,
          );
        },
      ),
    );
  }
}

/// Extension for easy semantic labeling
extension AccessibleWidget on Widget {
  Widget withSemanticLabel(String label) => Semantics(
    label: label,
    child: this,
  );
  
  Widget asButton(String label) => Semantics(
    button: true,
    label: label,
    child: this,
  );
  
  Widget asHeader(String label) => Semantics(
    header: true,
    label: label,
    child: this,
  );
}
