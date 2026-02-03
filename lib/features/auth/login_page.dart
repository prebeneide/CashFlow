import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/company_service.dart';
import 'widgets/validated_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final client = SupabaseService.client;
      final identifier = _identifierController.text.trim();
      final password = _passwordController.text;

      // Prøv å logge inn med email først
      AuthResponse response;
      
      if (identifier.contains('@')) {
        // Email login
        response = await client.auth.signInWithPassword(
          email: identifier,
          password: password,
        );
      } else if (RegExp(r'^\+?\d+$').hasMatch(identifier)) {
        // Telefonnummer login - forenklet versjon (krever OTP)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Telefonnummer login krever OTP. Bruk email i stedet.'),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      } else {
        // Brukernavn login - må hente email fra database
        final result = await client
            .from('users')
            .select('email')
            .eq('email', identifier) // Midlertidig - må ha username-felt
            .maybeSingle();
        
        if (result == null) {
          throw Exception('Brukernavn ikke funnet');
        }
        
        final userData = result;
        response = await client.auth.signInWithPassword(
          email: userData['email'] as String,
          password: password,
        );
      }

      if (response.user != null && mounted) {
        // Etter vellykket innlogging: sjekk om brukeren har bedriftsprofil
        final hasCompany = await CompanyService.hasCompany();
        if (!mounted) return;
        if (hasCompany) {
          context.go('/dashboard');
        } else {
          context.go('/onboarding');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Innlogging feilet: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('auth.login'.tr()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                
                Text(
                  'auth.welcome_back'.tr(),
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'auth.login_with'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                ValidatedTextField(
                  label: 'auth.login_with'.tr(),
                  controller: _identifierController,
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'common.error'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                ValidatedTextField(
                  label: 'auth.password'.tr(),
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '${'auth.password'.tr()} er påkrevd';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('auth.login'.tr()),
                ),
                const SizedBox(height: 16),
                
                TextButton(
                  onPressed: () => context.push('/signup'),
                  child: Text('auth.no_account'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

