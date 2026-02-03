import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/company_service.dart';
import '../../core/services/transaction_service.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/glass_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isCheckingCompany = true;
  bool _hasCompany = false;
  Map<String, int> _transactionCounts = {
    'total': 0,
    'needs_attention': 0,
    'ready_to_book': 0,
    'booked': 0,
  };

  @override
  void initState() {
    super.initState();
    _checkCompany();
  }

  Future<void> _checkCompany() async {
    final hasCompany = await CompanyService.hasCompany();
    if (mounted) {
      setState(() {
        _hasCompany = hasCompany;
        _isCheckingCompany = false;
      });
      if (!hasCompany) {
        context.go('/onboarding');
      } else {
        _loadTransactionCounts();
      }
    }
  }

  Future<void> _loadTransactionCounts() async {
    final counts = await TransactionService.getTransactionCounts();
    if (mounted) {
      setState(() {
        _transactionCounts = counts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isCheckingCompany) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('common.app_name'.tr()),
          backgroundColor: Colors.transparent,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: isDark 
                ? AppColors.backgroundGradientDark 
                : AppColors.backgroundGradientLight,
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (!_hasCompany) {
      // Vis loading mens redirect skjer
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('common.app_name'.tr()),
          backgroundColor: Colors.transparent,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: isDark 
                ? AppColors.backgroundGradientDark 
                : AppColors.backgroundGradientLight,
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final user = SupabaseService.currentUser;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('common.app_name'.tr()),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final router = GoRouter.of(context);
              await SupabaseService.client.auth.signOut();
              if (mounted) {
                router.go('/login');
              }
            },
            tooltip: 'auth.logout'.tr(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark 
              ? AppColors.backgroundGradientDark 
              : AppColors.backgroundGradientLight,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Velkommen-seksjon
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Velkommen tilbake!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user?.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Statistik-kort
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.receipt_long,
                        label: 'Transaksjoner',
                        value: '${_transactionCounts['total'] ?? 0}',
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.pending_actions,
                        label: 'Trenger oppmerksomhet',
                        value: '${_transactionCounts['needs_attention'] ?? 0}',
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle,
                        label: 'Klar til bokføring',
                        value: '${_transactionCounts['ready_to_book'] ?? 0}',
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.account_balance,
                        label: 'Bokført',
                        value: '${_transactionCounts['booked'] ?? 0}',
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Handlingsknapper
                Text(
                  'Hurtighandlinger',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                _ActionCard(
                  icon: Icons.camera_alt,
                  title: 'Last opp kvittering',
                  subtitle: 'Ta bilde eller last opp kvittering',
                  onTap: () {
                    context.push('/upload-receipt');
                  },
                ),
                const SizedBox(height: 8),
                
                _ActionCard(
                  icon: Icons.list_alt,
                  title: 'Se transaksjoner',
                  subtitle: 'Se alle transaksjoner som trenger oppmerksomhet',
                  onTap: () {
                    context.push('/transactions');
                  },
                ),
                const SizedBox(height: 8),
                
                _ActionCard(
                  icon: Icons.business,
                  title: 'Bedriftsprofil',
                  subtitle: 'Administrer bedriftsinformasjon',
                  onTap: () {
                    // TODO: Implementer bedriftsprofil
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

