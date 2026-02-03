import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';

class HelpTooltip extends StatefulWidget {
  final String question;
  final String context;
  final String? staticHelp;

  const HelpTooltip({
    super.key,
    required this.question,
    required this.context,
    this.staticHelp,
  });

  @override
  State<HelpTooltip> createState() => _HelpTooltipState();
}

class _HelpTooltipState extends State<HelpTooltip> {
  bool _isLoading = false;
  String? _aiExplanation;

  Future<void> _getAiExplanation() async {
    if (_aiExplanation != null) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post('/ai/explain', data: {
        'question': widget.question,
        'context': widget.context,
        'language': 'nb',
      });

      if (mounted) {
        setState(() {
          _aiExplanation = response.data['explanation'] as String?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiExplanation = 'Kunne ikke laste forklaring. Prøv igjen senere.';
          _isLoading = false;
        });
      }
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.help_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Hva betyr dette?'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.staticHelp != null) ...[
                Text(
                  widget.staticHelp!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],
              if (_aiExplanation == null && !_isLoading)
                ElevatedButton.icon(
                  onPressed: _getAiExplanation,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Få AI-forklaring'),
                ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_aiExplanation != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI-forklaring',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _aiExplanation!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Lukk'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.help_outline,
        size: 20,
        color: Theme.of(context).colorScheme.primary,
      ),
      onPressed: _showHelpDialog,
      tooltip: 'Få hjelp',
    );
  }
}

