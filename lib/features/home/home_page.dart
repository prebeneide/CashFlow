import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/services/supabase_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Lytte på auth-endringer
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final isAuthenticated = SupabaseService.isAuthenticated;
    final user = SupabaseService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('common.app_name'.tr()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              
              // Velkommen tekst
              Text(
                isAuthenticated 
                    ? 'Velkommen, ${user?.email ?? 'tilbake'}!'
                    : 'home.welcome'.tr(),
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isAuthenticated
                    ? 'Du er logget inn'
                    : 'home.subtitle'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Tema-knapp
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'home.theme'.tr(),
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isDark ? 'home.dark_mode_active'.tr() : 'home.light_mode_active'.tr(),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          Switch(
                            value: isDark,
                            onChanged: (value) {
                              themeProvider.setDarkMode(value);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    themeProvider.setDarkMode(!isDark);
                  },
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                  label: Text(isDark ? 'home.switch_to_light'.tr() : 'home.switch_to_dark'.tr()),
                ),
              ),
              const SizedBox(height: 16),
              
              // Språkvelger
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      context.setLocale(const Locale('nb'));
                    },
                    child: Text(
                      'Norsk',
                      style: TextStyle(
                        color: context.locale.languageCode == 'nb'
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        fontWeight: context.locale.languageCode == 'nb'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  const Text('|'),
                  TextButton(
                    onPressed: () {
                      context.setLocale(const Locale('en'));
                    },
                    child: Text(
                      'English',
                      style: TextStyle(
                        color: context.locale.languageCode == 'en'
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        fontWeight: context.locale.languageCode == 'en'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Login/Logout button
              if (isAuthenticated)
                ElevatedButton.icon(
                  onPressed: () async {
                    await SupabaseService.client.auth.signOut();
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: Text('auth.logout'.tr()),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => context.push('/login'),
                  icon: const Icon(Icons.login),
                  label: Text('auth.login'.tr()),
                ),
              const SizedBox(height: 16),
              
              // API test button
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final response = await ApiService.get('/health');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('API: ${response.data['message']}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('API feil: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.api),
                label: const Text('Test Backend API'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

