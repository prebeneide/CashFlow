import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneNumberField extends StatefulWidget {
  final String? Function(String?, String)? validator;
  final void Function(String, String)? onChanged;

  const PhoneNumberField({
    super.key,
    this.validator,
    this.onChanged,
  });

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountryCode = '+47';
  String? _errorText;
  bool _isValid = false;
  bool _hasInteracted = false;

  final Map<String, String> _countryCodes = {
    '+47': '🇳🇴 Norge',
    '+46': '🇸🇪 Sverige',
    '+45': '🇩🇰 Danmark',
    '+358': '🇫🇮 Finland',
    '+1': '🇺🇸 USA',
    '+44': '🇬🇧 Storbritannia',
  };

  int get _maxDigits {
    switch (_selectedCountryCode) {
      case '+47':
        return 8; // Norge
      case '+46':
      case '+45':
        return 8; // Sverige/Danmark
      default:
        return 10;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _validate(String value) {
    if (widget.validator != null) {
      final error = widget.validator!(value, _selectedCountryCode);
      setState(() {
        _errorText = error;
        _isValid = error == null && value.isNotEmpty;
      });
    }
    
    widget.onChanged?.call(value, _selectedCountryCode);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Telefonnummer',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: _errorText != null
                ? Theme.of(context).colorScheme.error
                : _isValid
                    ? Colors.green
                    : null,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Landskode-velger
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: _selectedCountryCode,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down),
                items: _countryCodes.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(entry.value.split(' ')[0]), // Flag emoji
                        const SizedBox(width: 4),
                        Text(entry.key),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCountryCode = value;
                      _phoneController.clear();
                      _errorText = null;
                      _isValid = false;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            // Telefonnummer input
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_maxDigits),
                ],
                decoration: InputDecoration(
                  hintText: 'Telefonnummer',
                  suffixIcon: _isValid && _hasInteracted
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  errorText: _hasInteracted ? _errorText : null,
                  counterText: '${_phoneController.text.length}/$_maxDigits',
                ),
                maxLength: _maxDigits,
                onChanged: (value) {
                  setState(() {
                    _hasInteracted = true;
                  });
                  _validate(value);
                },
              ),
            ),
          ],
        ),
        if (_hasInteracted && _isValid)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Telefonnummer er tilgjengelig ✓',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.green,
              ),
            ),
          ),
      ],
    );
  }
}

