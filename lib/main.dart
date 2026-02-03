import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/supabase_service.dart';
import 'core/services/api_service.dart';
import 'core/constants/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  
  // Initialiser Supabase
  await SupabaseService.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  
  // Initialiser API-service
  ApiService.initialize();
  
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('nb'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'CashFlow',
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            theme: themeProvider.getTheme(context),
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
