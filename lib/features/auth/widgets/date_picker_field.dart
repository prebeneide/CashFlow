import 'package:flutter/material.dart';

class DatePickerField extends StatefulWidget {
  final String? Function(DateTime?)? validator;
  final void Function(DateTime?)? onChanged;

  const DatePickerField({
    super.key,
    this.validator,
    this.onChanged,
  });

  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  DateTime? _selectedDate;
  String? _errorText;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year - 100); // 100 år tilbake
    final DateTime lastDate = DateTime(now.year - 13); // Minst 13 år gammel

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? lastDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Velg fødselsdato',
      cancelText: 'Avbryt',
      confirmText: 'Velg',
      locale: const Locale('nb', 'NO'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        if (widget.validator != null) {
          _errorText = widget.validator!(picked);
        }
      });
      widget.onChanged?.call(picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}. ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'januar',
      'februar',
      'mars',
      'april',
      'mai',
      'juni',
      'juli',
      'august',
      'september',
      'oktober',
      'november',
      'desember',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fødselsdato',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: 'Velg fødselsdato',
              suffixIcon: const Icon(Icons.calendar_today),
              errorText: _errorText,
            ),
            child: Text(
              _selectedDate != null
                  ? _formatDate(_selectedDate!)
                  : 'Velg fødselsdato',
              style: TextStyle(
                color: _selectedDate != null
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).hintColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

