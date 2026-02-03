import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/transaction_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/glass_card.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final transactions = await TransactionService.getTransactions(
      status: _selectedStatus,
    );
    if (mounted) {
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
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
        title: const Text('Transaksjoner'),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark 
              ? AppColors.backgroundGradientDark 
              : AppColors.backgroundGradientLight,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Filter chips
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Alle',
                        selected: _selectedStatus == null,
                        onTap: () {
                          setState(() => _selectedStatus = null);
                          _loadTransactions();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Trenger oppmerksomhet',
                        selected: _selectedStatus == 'NEEDS_INFO',
                        onTap: () {
                          setState(() => _selectedStatus = 'NEEDS_INFO');
                          _loadTransactions();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Klar til bokføring',
                        selected: _selectedStatus == 'READY_TO_BOOK',
                        onTap: () {
                          setState(() => _selectedStatus = 'READY_TO_BOOK');
                          _loadTransactions();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Bokført',
                        selected: _selectedStatus == 'BOOKED',
                        onTap: () {
                          setState(() => _selectedStatus = 'BOOKED');
                          _loadTransactions();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Transactions list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _transactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 64,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Ingen transaksjoner',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Transaksjoner vil vises her når du laster opp kvitteringer',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.4),
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = _transactions[index];
                              return _TransactionCard(
                                transaction: transaction,
                                statusColor: _getStatusColor(transaction.status),
                                statusIcon: _getStatusIcon(transaction.status),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final Color statusColor;
  final IconData statusIcon;

  const _TransactionCard({
    required this.transaction,
    required this.statusColor,
    required this.statusIcon,
  });

  bool _isImageFile(String? fileType) {
    return fileType == 'image';
  }

  Future<String?> _getImageUrl() async {
    if (transaction.documentFilePath == null) return null;
    try {
      final response = await SupabaseService.client.storage
          .from('documents')
          .createSignedUrl(transaction.documentFilePath!, 3600); // 1 time expiry
      return response;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDocument = transaction.documentFilePath != null;
    final isImage = _isImageFile(transaction.documentFileType);

    return InkWell(
      onTap: () {
        context.push('/transaction/${transaction.id}');
      },
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
        children: [
          // Dokumentforhåndsvisning eller statusikon
          if (hasDocument && isImage)
            // Bildeforhåndsvisning med FutureBuilder for signed URL
            FutureBuilder<String?>(
              future: _getImageUrl(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                
                final imageUrl = snapshot.data;
                if (imageUrl != null) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback til statusikon hvis bilde ikke kan lastes
                        return _buildStatusIcon();
                      },
                    ),
                  );
                }
                
                // Fallback hvis URL ikke kunne hentes
                return _buildStatusIcon();
              },
            )
          else if (hasDocument && !isImage)
            // PDF-ikon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.picture_as_pdf,
                color: AppColors.primary,
                size: 28,
              ),
            )
          else
            // Statusikon (fallback)
            _buildStatusIcon(),
          
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.statusLabel,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Opprettet ${_formatDate(transaction.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.4),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        statusIcon,
        color: statusColor,
        size: 20,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'i dag';
    } else if (difference.inDays == 1) {
      return 'i går';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dager siden';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}

