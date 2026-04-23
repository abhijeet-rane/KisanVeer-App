import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_motion.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';

/// A consistent text input built on top of [TextFormField] and the
/// v2 theme, with animated focus ring, prefix / suffix affordances,
/// helper text, and error styling.
///
/// This widget plays nicely inside a [Form]:
///
/// ```dart
/// AppTextField(
///   label: 'Email',
///   hint: 'you@example.com',
///   controller: _emailCtrl,
///   keyboardType: TextInputType.emailAddress,
///   validator: Validators.validateEmail,
///   prefixIcon: Icons.mail_outline,
/// )
/// ```
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.autovalidateMode,
  }) : assert(
         controller == null || initialValue == null,
         'Provide either a controller or an initialValue, not both.',
       );

  final TextEditingController? controller;
  final String? initialValue;

  /// Label rendered above the field when provided.
  final String? label;

  /// Placeholder shown when the field is empty.
  final String? hint;

  /// Optional helper text rendered below the field.
  final String? helperText;

  /// When non-null, overrides [validator] output and puts the field
  /// into error state with this text.
  final String? errorText;

  /// Leading icon rendered inside the field.
  final IconData? prefixIcon;

  /// Arbitrary widget rendered at the trailing edge (e.g. a clear
  /// button, obscure-toggle, or unit label).
  final Widget? suffix;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final AutovalidateMode? autovalidateMode;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode;
  bool _ownsFocusNode = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!mounted) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    final Color borderColor = hasError
        ? AppColors.danger
        : _focused
        ? AppColors.primary
        : AppColors.outlineVariant;

    final double borderWidth = (_focused || hasError) ? 1.5 : 1;

    // Screen-reader note: we render the label as its own Text above the
    // field so the focus ring sits cleanly on just the input, but we
    // don't want the label announced twice. Exclude the visible Text
    // from semantics and pass the label into the TextFormField so
    // TalkBack / VoiceOver reads "<label>, edit box" once.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          ExcludeSemantics(
            child: Text(
              widget.label!,
              style: AppTextStyles.labelLarge.copyWith(
                color: hasError ? AppColors.danger : AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
        ],
        Semantics(
          // Gives the field a stable accessible name regardless of
          // its current content. TextFormField already announces the
          // textField role on its own; we just attach the label here.
          label: widget.label,
          textField: true,
          enabled: widget.enabled,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            decoration: BoxDecoration(
              color: widget.enabled
                  ? AppColors.surfaceContainerLow
                  : AppColors.surfaceContainer,
              borderRadius: AppRadii.brMd,
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: TextFormField(
              controller: widget.controller,
              initialValue: widget.initialValue,
              focusNode: _focusNode,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              autofocus: widget.autofocus,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              textCapitalization: widget.textCapitalization,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              maxLength: widget.maxLength,
              inputFormatters: widget.inputFormatters,
              onChanged: widget.onChanged,
              onFieldSubmitted: widget.onSubmitted,
              onTap: widget.onTap,
              validator: widget.validator,
              autovalidateMode: widget.autovalidateMode,
              cursorColor: AppColors.primary,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                // label is echoed into the decoration purely for a11y —
                // the visible label is rendered above and excluded from
                // semantics. `labelText` would fight the custom layout,
                // so we use `hintText` as the a11y fallback and rely on
                // the Semantics label below for the canonical name.
                hintText: widget.hint,
                hintStyle: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textLight,
                ),
                prefixIcon: widget.prefixIcon == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.space12,
                          right: AppSpacing.space8,
                        ),
                        child: Icon(
                          widget.prefixIcon,
                          size: 20,
                          color: hasError
                              ? AppColors.danger
                              : _focused
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                prefixIconConstraints: const BoxConstraints(
                  minHeight: 20,
                  minWidth: 40,
                ),
                suffixIcon: widget.suffix == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(
                          right: AppSpacing.space12,
                        ),
                        child: widget.suffix,
                      ),
                suffixIconConstraints: const BoxConstraints(
                  minHeight: 20,
                  minWidth: 40,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: widget.prefixIcon == null
                      ? AppSpacing.space16
                      : 0,
                  vertical: AppSpacing.space16,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                // We render the error text ourselves below so the field
                // doesn't jump on focus.
                errorStyle: const TextStyle(
                  height: 0,
                  fontSize: 0,
                  color: Colors.transparent,
                ),
                counterText: '',
                isDense: true,
              ),
            ),
          ),
        ),
        if (hasError || widget.helperText != null) ...[
          const SizedBox(height: AppSpacing.space6),
          // Error text is announced as a live region so TalkBack/
          // VoiceOver picks up new validation messages automatically.
          Semantics(
            liveRegion: hasError,
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              child: Text(
                hasError ? widget.errorText! : widget.helperText!,
                key: ValueKey<String>(
                  hasError
                      ? 'err:${widget.errorText}'
                      : 'help:${widget.helperText}',
                ),
                style: AppTextStyles.labelMedium.copyWith(
                  color: hasError
                      ? AppColors.danger
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
