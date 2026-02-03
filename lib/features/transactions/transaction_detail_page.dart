import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
                                          ],
                                        ),
                                      ),
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

