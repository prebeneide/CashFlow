import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/transaction_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/glass_card.dart';

class TransactionDetailPage extends StatefulWidget {
  final String transactionId;

  const TransactionDetailPage({
    super.key,
    required this.transactionId,
  });

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  Transaction? _transaction;
  bool _isLoading = true;
  String? _imageUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  Future<void> _loadTransaction() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Hent alle transaksjoner og finn den med riktig ID
      final transactions = await TransactionService.getTransactions();
      final transaction = transactions.firstWhere(
        (t) => t.id == widget.transactionId,
        orElse: () => throw Exception('Transaksjon ikke funnet'),
      );

      // Hent signed URL for bilde hvis det er et bilde
      String? imageUrl;
      if (transaction.documentFilePath != null &&
          transaction.documentFileType == 'image') {
        try {
          imageUrl = await SupabaseService.client.storage
              .from('documents')
              .createSignedUrl(transaction.documentFilePath!, 3600);
        } catch (e) {
          // Ignorer feil ved henting av bilde
        }
      }

      if (mounted) {
        setState(() {
          _transaction = transaction;
          _imageUrl = imageUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'NEW':
        return AppColors.primary;
      case 'NEEDS_INFO':
      case 'NEEDS_USER_CHOICE':
        return Colors.orange;
      case 'READY_TO_BOOK':
        return Colors.green;
      case 'BOOKED':
        return AppColors.secondary;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'NEW':
        return Icons.receipt_long;
      case 'NEEDS_INFO':
        return Icons.info_outline;
      case 'NEEDS_USER_CHOICE':
        return Icons.help_outline;
      case 'READY_TO_BOOK':
        return Icons.check_circle_outline;
      case 'BOOKED':
        return Icons.account_balance;
      default:
        return Icons.receipt;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openDocument() async {
    if (_transaction?.documentFilePath == null) return;

    try {
      // Hent signed URL for dokumentet
      final signedUrl = await SupabaseService.client.storage
          .from('documents')
          .createSignedUrl(_transaction!.documentFilePath!, 3600);

      // Åpne URL i nettleser/app
      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kunne ikke åpne dokumentet'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Feil ved åpning av dokument: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '-';
    if (value is num) {
      return '${value.toStringAsFixed(2)} kr';
    }
    return value.toString();
  }

  List<Widget> _buildAnalysisFields(BuildContext context, Map<String, dynamic> analysis) {
    final fields = <Widget>[];
    final fieldLabels = {
      'amount': 'Beløp',
      'description': 'Beskrivelse',
      'vendor': 'Leverandør',
      'date': 'Dato',
      'category': 'Kategori',
      'account': 'Konto',
      'vat_amount': 'MVA-beløp',
      'total_amount': 'Totalt beløp',
    };

    // Vis viktige felter først
    final priorityFields = ['amount', 'description', 'vendor', 'date', 'total_amount'];
    for (final key in priorityFields) {
      if (analysis.containsKey(key) && analysis[key] != null) {
        final value = analysis[key];
        if (value.toString().isNotEmpty) {
          fields.add(_InfoRow(
            label: fieldLabels[key] ?? key,
            value: key.contains('amount') ? _formatCurrency(value) : value.toString(),
          ));
          fields.add(const SizedBox(height: 12));
        }
      }
    }

    // Vis resten av feltene
    for (final entry in analysis.entries) {
      if (!priorityFields.contains(entry.key) && 
          entry.value != null && 
          entry.value.toString().isNotEmpty) {
        fields.add(_InfoRow(
          label: fieldLabels[entry.key] ?? entry.key,
          value: entry.key.contains('amount') 
              ? _formatCurrency(entry.value) 
              : entry.value.toString(),
        ));
        fields.add(const SizedBox(height: 12));
      }
    }

    // Fjern siste SizedBox hvis det finnes
    if (fields.isNotEmpty && fields.last is SizedBox) {
      fields.removeLast();
    }

    return fields.isEmpty 
        ? [
            Text(
              'Ingen detaljer tilgjengelig',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
          ]
        : fields;
  }

  List<Widget> _buildUserChoicesFields(BuildContext context, Map<String, dynamic> userChoices) {
    final fields = <Widget>[];
    final fieldLabels = {
      'category': 'Kategori',
      'account': 'Konto',
      'vendor': 'Leverandør',
      'description': 'Beskrivelse',
      'amount': 'Beløp',
      'vat_amount': 'MVA-beløp',
      'date': 'Dato',
      'notes': 'Notater',
      'tags': 'Tagger',
    };

    // Vis alle felter fra userChoices
    for (final entry in userChoices.entries) {
      if (entry.value != null && entry.value.toString().isNotEmpty) {
        final value = entry.value;
        String displayValue;
        
        // Håndter spesielle typer
        if (value is List) {
          displayValue = value.join(', ');
        } else if (value is Map) {
          displayValue = value.entries
              .map((e) => '${e.key}: ${e.value}')
              .join(', ');
        } else if (entry.key.contains('amount')) {
          displayValue = _formatCurrency(value);
        } else {
          displayValue = value.toString();
        }

        fields.add(_InfoRow(
          label: fieldLabels[entry.key] ?? entry.key,
          value: displayValue,
        ));
        fields.add(const SizedBox(height: 12));
      }
    }

    // Fjern siste SizedBox hvis det finnes
    if (fields.isNotEmpty && fields.last is SizedBox) {
      fields.removeLast();
    }

    return fields.isEmpty 
        ? [
            Text(
              'Ingen brukervalg registrert',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
          ]
        : fields;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Transaksjonsdetaljer'),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.backgroundGradientDark
              : AppColors.backgroundGradientLight,
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Feil ved lasting av transaksjon',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadTransaction,
                            child: const Text('Prøv igjen'),
                          ),
                        ],
                      ),
                    )
                  : _transaction == null
                      ? const Center(child: Text('Transaksjon ikke funnet'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Statuskort
                              GlassCard(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(_transaction!.status)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _getStatusIcon(_transaction!.status),
                                        color: _getStatusColor(_transaction!.status),
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _transaction!.statusLabel,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Opprettet ${_formatDate(_transaction!.createdAt)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.6),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Dokumentforhåndsvisning
                              if (_transaction!.documentFilePath != null) ...[
                                GlassCard(
                                  padding: EdgeInsets.zero,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (_imageUrl != null)
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            topRight: Radius.circular(16),
                                          ),
                                          child: Image.network(
                                            _imageUrl!,
                                            fit: BoxFit.contain,
                                            loadingBuilder:
                                                (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Container(
                                                height: 400,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey
                                                      .withValues(alpha: 0.1),
                                                ),
                                                child: const Center(
                                                  child: CircularProgressIndicator(),
                                                ),
                                              );
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                height: 200,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey
                                                      .withValues(alpha: 0.1),
                                                ),
                                                child: Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.error_outline,
                                                        size: 48,
                                                        color: Colors.grey
                                                            .withValues(alpha: 0.5),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Kunne ikke laste bilde',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      else if (_transaction!.documentFileType ==
                                          'pdf')
                                        Container(
                                          height: 200,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.1),
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(16),
                                              topRight: Radius.circular(16),
                                            ),
                                          ),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.picture_as_pdf,
                                                  size: 64,
                                                  color: AppColors.primary,
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'PDF-dokument',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        color: AppColors.primary,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _transaction!.documentFileType ==
                                                      'image'
                                                  ? Icons.image
                                                  : Icons.picture_as_pdf,
                                              color: AppColors.primary,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _transaction!.documentFilePath!
                                                    .split('/')
                                                    .last,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.open_in_new),
                                              color: AppColors.primary,
                                              iconSize: 20,
                                              onPressed: () => _openDocument(),
                                              tooltip: 'Åpne dokument',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Transaksjonsdetaljer fra analyse
                              if (_transaction!.aiAnalysis.isNotEmpty) ...[
                                GlassCard(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Transaksjonsdetaljer',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      ..._buildAnalysisFields(context, _transaction!.aiAnalysis),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Brukervalg
                              if (_transaction!.userChoices.isNotEmpty) ...[
                                GlassCard(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Brukervalg',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      ..._buildUserChoicesFields(context, _transaction!.userChoices),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Informasjon
                              GlassCard(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Informasjon',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    _InfoRow(
                                      label: 'Status',
                                      value: _transaction!.statusLabel,
                                    ),
                                    const SizedBox(height: 12),
                                    _InfoRow(
                                      label: 'Opprettet',
                                      value: _formatDate(_transaction!.createdAt),
                                    ),
                                    if (_transaction!.updatedAt !=
                                        _transaction!.createdAt) ...[
                                      const SizedBox(height: 12),
                                      _InfoRow(
                                        label: 'Sist oppdatert',
                                        value: _formatDate(_transaction!.updatedAt),
                                      ),
                                    ],
                                    if (_transaction!.bookedAt != null) ...[
                                      const SizedBox(height: 12),
                                      _InfoRow(
                                        label: 'Bokført',
                                        value: _formatDate(_transaction!.bookedAt!),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}

