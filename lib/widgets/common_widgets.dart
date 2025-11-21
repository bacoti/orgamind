import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../constants/strings.dart';

/// Custom Text Field dengan validation dan UX yang baik
class CustomTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? minLines;
  final bool readOnly;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;

  const CustomTextField({
    Key? key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
    this.readOnly = false,
    this.onChanged,
    this.focusNode,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _internalFocusNode;
  late bool _isFocused;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _isFocused = false;
    _internalFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _internalFocusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _internalFocusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: _isFocused ? AppColors.primary : AppColors.gray700,
              ),
        ),
        const SizedBox(height: 8),
        // Text Field
        TextFormField(
          controller: widget.controller,
          focusNode: _internalFocusNode,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          readOnly: widget.readOnly,
          onChanged: widget.onChanged,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.black,
              ),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
            isDense: true,
            contentPadding: (widget.maxLines != null && widget.maxLines! > 1)
                ? const EdgeInsets.symmetric(vertical: 12, horizontal: 12)
                : null,
          ),
        ),
      ],
    );
  }
}

/// Elevated Button dengan ripple effect
class CustomElevatedButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CustomElevatedButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: foregroundColor ?? AppColors.white,
          disabledBackgroundColor: AppColors.gray300,
          disabledForegroundColor: AppColors.gray500,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 1,
          shadowColor: AppColors.primary.withOpacity(0.3),
          surfaceTintColor: Colors.transparent,
        ).copyWith(
          elevation: MaterialStateProperty.resolveWith<double>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return 0;
              }
              return 4; // Default elevation
            },
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : icon != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(label),
                      const SizedBox(width: 8),
                      icon!,
                    ],
                  )
                : Text(label),
      ),
    );
  }
}

/// Outlined Button dengan border
class CustomOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Widget? icon;
  final Color? borderColor;
  final Color? textColor;

  const CustomOutlinedButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.borderColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: borderColor ?? AppColors.primary,
            width: 1.5,
          ),
          foregroundColor: textColor ?? AppColors.primary,
        ),
        child: icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon!,
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label),
      ),
    );
  }
}

/// Loading Dialog dengan professional design
class LoadingDialog extends StatelessWidget {
  final String? message;

  const LoadingDialog({
    Key? key,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 3,
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static void show(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(message: message),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}

/// Alert Dialog dengan proper styling
class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? cancelLabel;
  final VoidCallback? onCancel;
  final Color? actionColor;
  final bool isDanger;

  const CustomAlertDialog({
    Key? key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.cancelLabel,
    this.onCancel,
    this.actionColor,
    this.isDanger = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      actions: [
        if (cancelLabel != null || onCancel != null)
          TextButton(
            onPressed: onCancel ?? () => Navigator.pop(context),
            child: Text(
              cancelLabel ?? AppStrings.cancel,
              style: const TextStyle(color: AppColors.gray600),
            ),
          ),
        if (actionLabel != null || onAction != null)
          TextButton(
            onPressed: onAction ?? () => Navigator.pop(context),
            child: Text(
              actionLabel ?? AppStrings.ok,
              style: TextStyle(
                color: isDanger ? AppColors.error : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    String? cancelLabel,
    VoidCallback? onCancel,
    Color? actionColor,
    bool isDanger = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => CustomAlertDialog(
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
        cancelLabel: cancelLabel,
        onCancel: onCancel,
        actionColor: actionColor,
        isDanger: isDanger,
      ),
    );
  }
}

/// Enhanced Custom Text Field dengan real-time validation dan status icons
class EnhancedTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? Function(String?)? realTimeValidator;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? minLines;
  final bool readOnly;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final String? helperText;
  final bool showStatusIcon;

  const EnhancedTextField({
    Key? key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.realTimeValidator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
    this.readOnly = false,
    this.onChanged,
    this.focusNode,
    this.helperText,
    this.showStatusIcon = true,
  }) : super(key: key);

  @override
  State<EnhancedTextField> createState() => _EnhancedTextFieldState();
}

class _EnhancedTextFieldState extends State<EnhancedTextField> {
  late FocusNode _internalFocusNode;
  String? _errorText;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _internalFocusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    // Focus change handling if needed
  }

  void _validateRealTime(String value) {
    if (widget.realTimeValidator != null) {
      final error = widget.realTimeValidator!(value);
      setState(() {
        _errorText = error;
        _isValid = error == null && value.isNotEmpty;
      });
    }
  }

  Widget? _getStatusIcon() {
    if (!widget.showStatusIcon || _errorText == null && !_isValid) return null;

    if (_errorText != null) {
      return Icon(
        Icons.error_outline,
        color: AppColors.error,
        size: 20,
      );
    } else if (_isValid) {
      return Icon(
        Icons.check_circle_outline,
        color: AppColors.success,
        size: 20,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.gray600,
          ),
        ),
        const SizedBox(height: 8),
        // Text Field
        TextFormField(
          controller: widget.controller,
          focusNode: _internalFocusNode,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          readOnly: widget.readOnly,
          onChanged: (value) {
            _validateRealTime(value);
            widget.onChanged?.call(value);
          },
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              color: AppColors.gray400,
              fontSize: 16,
            ),
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon ?? _getStatusIcon(),
            isDense: true,
            contentPadding: (widget.maxLines != null && widget.maxLines! > 1)
                ? const EdgeInsets.symmetric(vertical: 12, horizontal: 12)
                : null,
            errorStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.error,
              height: 1.2,
            ),
          ),
        ),
        // Error/Success Message
        if (_errorText != null || (_isValid && widget.showStatusIcon))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _errorText ?? 'Valid',
              style: TextStyle(
                fontSize: 13,
                color: _errorText != null ? AppColors.error : AppColors.success,
                height: 1.2,
              ),
            ),
          ),
        // Helper Text
        if (widget.helperText != null && _errorText == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.helperText!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.gray400,
                height: 1.2,
              ),
            ),
          ),
      ],
    );
  }
}
