import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';

class MoreInfoButton extends StatefulWidget {
  final String topic;
  final String context;
  final String? detailedInfo;

  const MoreInfoButton({
    super.key,
    required this.topic,
    required this.context,
    this.detailedInfo,
  });

  @override
  State<MoreInfoButton> createState() => _MoreInfoButtonState();
}

class _MoreInfoButtonState extends State<MoreInfoButton> {
  bool _isLoading = false;
  String? _aiExplanation;

  Future<void> _getDetailedExplanation() async {
    if (_aiExplanation != null) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post('/ai/explain', data: {
        'question': widget.topic,
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
          _aiExplanation = 'Kunne ikke laste detaljert forklaring. Prøv igjen senere.';
          _isLoading = false;
        });
      }
    }
  }

  void _showMoreInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Detaljert informasjon',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.detailedInfo != null) ...[
                Text(
                  widget.detailedInfo!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
              ],
              if (_aiExplanation == null && !_isLoading)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _getDetailedExplanation,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Få AI-forklaring'),
                  ),
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
                const SizedBox(height: 16),
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
    return TextButton.icon(
      onPressed: _showMoreInfoDialog,
      icon: Icon(
        Icons.info_outline,
        size: 18,
        color: Theme.of(context).colorScheme.primary,
      ),
      label: const Text('Mer informasjon'),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

