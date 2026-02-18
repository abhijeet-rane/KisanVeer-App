import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';

/// A customizable button with different styles and states
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonType buttonType;
  final double? width;
  final double height;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? color;
  final double iconSize;
  final double borderRadius;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.buttonType = ButtonType.filled,
    this.width,
    this.height = 54,
    this.leadingIcon,
    this.trailingIcon,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.color,
    this.iconSize = 20,
    this.borderRadius = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine colors based on button type
    final Color bgColor = backgroundColor ??
        (buttonType == ButtonType.filled
            ? AppColors.primary
            : (buttonType == ButtonType.outlined
                ? Colors.transparent
                : Colors.transparent));

    final Color txtColor = textColor ??
        (buttonType == ButtonType.filled ? Colors.white : AppColors.primary);

    // Build button content with optional icons and loading state
    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null && !isLoading)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(leadingIcon, color: txtColor, size: iconSize),
          ),
        if (isLoading)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(txtColor),
              ),
            ),
          ),
        if (icon != null)
          Row(
            children: [
              Icon(icon, color: txtColor),
              const SizedBox(width: 8),
            ],
          ),
        Text(
          text,
          style: TextStyle(
            color: txtColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        if (trailingIcon != null && !isLoading)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(trailingIcon, color: txtColor, size: iconSize),
          ),
      ],
    );

    // Apply appropriate styling based on button type
    Widget buttonWidget;

    switch (buttonType) {
      case ButtonType.filled:
        buttonWidget = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? bgColor,
            foregroundColor: txtColor,
            disabledBackgroundColor: bgColor.withAlpha((0.6 * 255).round()),
            disabledForegroundColor: txtColor.withAlpha((0.8 * 255).round()),
            elevation: 2,
            minimumSize:
                Size(width ?? MediaQuery.of(context).size.width * 0.9, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
          ),
          child: buttonContent,
        );
        break;

      case ButtonType.outlined:
        buttonWidget = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: txtColor,
            side: BorderSide(color: txtColor, width: 1.5),
            minimumSize:
                Size(width ?? MediaQuery.of(context).size.width * 0.9, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          ),
          child: buttonContent,
        );
        break;

      case ButtonType.text:
        buttonWidget = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: txtColor,
            minimumSize:
                Size(width ?? MediaQuery.of(context).size.width * 0.9, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          ),
          child: buttonContent,
        );
        break;
    }

    return SizedBox(
      width: width ?? MediaQuery.of(context).size.width * 0.9,
      child: buttonWidget,
    );
  }
}

/// Button types for CustomButton
enum ButtonType {
  filled, // Solid background with text
  outlined, // Border with transparent background
  text, // No border, no background, just text
}
