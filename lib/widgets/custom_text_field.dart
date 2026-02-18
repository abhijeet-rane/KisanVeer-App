import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kisan_veer/constants/app_colors.dart';

/// A customizable text field with various styling options
class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool readOnly;
  final bool isMultiline;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final bool enableSuggestions;
  final bool showCounter;
  final String? initialValue;
  final AutovalidateMode autovalidateMode;
  final BoxBorder? border;
  final Color? fillColor;
  final EdgeInsets? contentPadding;
  final TextStyle? style;
  final int? minLines;
  final int? maxLines;

  const CustomTextField({
    Key? key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.readOnly = false,
    this.isMultiline = false,
    this.prefixIcon,
    this.suffix,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.enableSuggestions = true,
    this.showCounter = false,
    this.initialValue,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.border,
    this.fillColor,
    this.contentPadding,
    this.style,
    this.minLines,
    this.maxLines,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          validator: widget.validator,
          keyboardType: widget.isMultiline
              ? TextInputType.multiline
              : widget.keyboardType,
          obscureText: widget.obscureText && !_passwordVisible,
          readOnly: widget.readOnly,
          minLines: widget.minLines ?? (widget.isMultiline ? 1 : 1),
          maxLines: widget.maxLines ?? (widget.isMultiline ? 5 : 1),
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          focusNode: widget.focusNode,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          textCapitalization: widget.textCapitalization,
          autofocus: widget.autofocus,
          enableSuggestions: widget.enableSuggestions,
          autovalidateMode: widget.autovalidateMode,
          cursorColor: AppColors.primary,
          style: widget.style ??
              const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
              ),
          decoration: InputDecoration(
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: AppColors.textSecondary,
                    size: 22,
                  )
                : null,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  )
                : widget.suffix,
            hintText: widget.hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
              fontFamily: 'Poppins',
            ),
            filled: true,
            fillColor: widget.fillColor ?? Colors.white,
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            counter: widget.showCounter ? null : const SizedBox.shrink(),
            errorStyle: const TextStyle(
              fontSize: 12,
              color: AppColors.error,
              fontFamily: 'Poppins',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.textLight, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.textLight, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
