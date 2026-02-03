import 'package:flutter/material.dart';

class ValidatedTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? helperText;
  final bool showSuccessIcon;
  final TextEditingController? controller;

  const ValidatedTextField({
    super.key,
    required this.label,
    this.hint,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.helperText,
    this.showSuccessIcon = false,
    this.controller,
  });

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _isValid = false;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _validate(String value) {
    if (widget.validator != null) {
      final error = widget.validator!(value);
      setState(() {
        _errorText = error;
        _isValid = error == null && value.isNotEmpty;
      });
    }
    
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: _errorText != null
                ? Theme.of(context).colorScheme.error
                : _isValid && widget.showSuccessIcon
                    ? Colors.green
                    : null,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixIcon: _isValid && widget.showSuccessIcon && _hasInteracted
                ? const Icon(Icons.check_circle, color: Colors.green)
                : widget.suffixIcon,
            errorText: _hasInteracted ? _errorText : null,
            helperText: widget.helperText,
          ),
          onChanged: (value) {
            setState(() {
              _hasInteracted = true;
            });
            _validate(value);
          },
        ),
      ],
    );
  }
}

