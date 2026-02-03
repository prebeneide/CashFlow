import 'package:flutter/material.dart';

class EnhancedValidatedField extends StatefulWidget {
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final String? helperText;
  final int? requiredLength;
  final String? lengthHelperText;

  const EnhancedValidatedField({
    super.key,
    required this.label,
    this.hint,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.controller,
    this.helperText,
    this.requiredLength,
    this.lengthHelperText,
  });

  @override
  State<EnhancedValidatedField> createState() => _EnhancedValidatedFieldState();
}

class _EnhancedValidatedFieldState extends State<EnhancedValidatedField> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _isValid = false;
  bool _hasInteracted = false;
  int _currentLength = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _currentLength = _getDigitLength(_controller.text);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  int _getDigitLength(String value) {
    return value.replaceAll(RegExp(r'[^\d]'), '').length;
  }

  void _validate(String value) {
    final digitLength = _getDigitLength(value);
    setState(() => _currentLength = digitLength);

    if (widget.validator != null) {
      final error = widget.validator!(value);
      setState(() {
        _errorText = error;
        _isValid = error == null && value.isNotEmpty;
      });
    }

    widget.onChanged?.call(value);
  }

  Color _getBorderColor() {
    if (!_hasInteracted) {
      return Theme.of(context).colorScheme.outline;
    }
    if (_errorText != null) {
      return Theme.of(context).colorScheme.error;
    }
    if (_isValid) {
      return Colors.green;
    }
    return Theme.of(context).colorScheme.outline;
  }

  Widget? _getSuffixIcon() {
    if (!_hasInteracted) return null;
    
    if (_isValid) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    
    if (_errorText != null) {
      return Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error);
    }
    
    return null;
  }

  String? _getHelperText() {
    if (widget.requiredLength != null && _hasInteracted && !_isValid && _currentLength > 0) {
      final missing = widget.requiredLength! - _currentLength;
      if (missing > 0) {
        if (widget.lengthHelperText != null) {
          return widget.lengthHelperText!.replaceAll('{missing}', missing.toString());
        }
        return 'Mangler $missing siffer';
      }
    }
    
    if (_isValid && widget.requiredLength != null) {
      return 'Gyldig';
    }
    
    return widget.helperText;
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
                : _isValid
                    ? Colors.green
                    : null,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixIcon: _getSuffixIcon(),
            errorText: _hasInteracted ? _errorText : null,
            helperText: _getHelperText(),
            helperStyle: TextStyle(
              color: _isValid 
                  ? Colors.green
                  : _errorText != null
                      ? Theme.of(context).colorScheme.error
                      : null,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _getBorderColor()),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _getBorderColor()),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _getBorderColor(),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
            ),
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

