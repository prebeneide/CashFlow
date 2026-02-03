import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/company_service.dart';
import 'widgets/validated_text_field.dart';
import 'widgets/phone_number_field.dart';
import 'widgets/date_picker_field.dart';
import '../../core/validators/auth_validators.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  
  String _email = '';
  String _phoneNumber = '';
  String _countryCode = '+47';
  String _username = '';
  DateTime? _dateOfBirth;
  String _password = '';
  
  bool _isEmailAvailable = false;
  bool _isPhoneAvailable = false;
  bool _isUsernameAvailable = false;
  bool _isCheckingEmail = false;
  bool _isCheckingUsername = false;
  bool _isLoading = false;

  Future<void> _checkEmailAvailability(String email) async {
    if (email.isEmpty || AuthValidators.email(email) != null) {
      setState(() {
        _isEmailAvailable = false;
        _isCheckingEmail = false;
      });
      return;
    }

    setState(() => _isCheckingEmail = true);

    try {
      final client = SupabaseService.client;
      // Sjekk om email eksisterer i users-tabellen
      final result = await client
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      
      setState(() {
        _isEmailAvailable = result == null;
        _isCheckingEmail = false;
      });
    } catch (e) {
      // Hvis vi får feil, anta at email er tilgjengelig
      setState(() {
        _isEmailAvailable = true;
        _isCheckingEmail = false;
      });
    }
  }

  Future<void> _checkPhoneAvailability(String phone, String countryCode) async {
    if (phone.isEmpty || AuthValidators.phoneNumber(phone, countryCode) != null) {
      setState(() {
        _isPhoneAvailable = false;
      });
      return;
    }

    try {
      // Forenklet sjekk - i produksjon må dette gjøres via backend
      setState(() {
        _isPhoneAvailable = true; // Midlertidig - må implementeres via backend
      });
    } catch (e) {
      setState(() {
        _isPhoneAvailable = false;
      });
    }
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.isEmpty || AuthValidators.username(username) != null) {
      setState(() {
        _isUsernameAvailable = false;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() => _isCheckingUsername = true);

    try {
      final client = SupabaseService.client;
      final result = await client
          .from('users')
          .select('id')
          .eq('email', username) // Midlertidig - må ha username-felt i database
          .maybeSingle();
      
      setState(() {
        _isUsernameAvailable = result == null;
        _isCheckingUsername = false;
      });
    } catch (e) {
      setState(() {
        _isUsernameAvailable = false;
        _isCheckingUsername = false;
      });
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isEmailAvailable || !_isPhoneAvailable || !_isUsernameAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vennligst sjekk at alle felter er gyldige og tilgjengelige'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vennligst velg fødselsdato'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final client = SupabaseService.client;
      
      // Opprett bruker med email og passord
      final response = await client.auth.signUp(
        email: _email,
        password: _password,
        data: {
          'username': _username,
          'phone': '$_countryCode$_phoneNumber',
          'date_of_birth': _dateOfBirth!.toIso8601String(),
        },
      );

      if (response.user != null) {
        // Opprett bruker-profil i users-tabellen
        try {
          await client.from('users').insert({
            'id': response.user!.id,
            'email': _email,
          });
        } catch (dbError) {
          // Hvis users-tabellen ikke finnes eller feil, fortsett likevel
          // Brukeren er opprettet i Supabase Auth
        }

        // Sjekk om brukeren er logget inn (har session)
        final session = client.auth.currentSession;
        
        if (mounted) {
          if (session != null) {
            // Brukeren er automatisk logget inn
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Konto opprettet og du er logget inn!'),
                backgroundColor: Colors.green,
              ),
            );

            // Sjekk om brukeren allerede har bedriftsprofil (uvanlig rett etter signup, men for sikkerhet)
            final hasCompany = await CompanyService.hasCompany();
            if (!mounted) return;
            if (hasCompany) {
              context.go('/dashboard');
            } else {
              context.go('/onboarding');
            }
          } else {
            // Email-verifisering er påkrevd
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Konto opprettet! Sjekk email for verifisering.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );
            // Prøv å logge inn automatisk
            try {
              final loginResponse = await client.auth.signInWithPassword(
                email: _email,
                password: _password,
              );
              if (!mounted) return;
              if (loginResponse.session != null) {
                // Etter vellykket innlogging: sjekk om brukeren har bedriftsprofil
                final hasCompany = await CompanyService.hasCompany();
                if (!mounted) return;
                if (hasCompany) {
                  context.go('/dashboard');
                } else {
                  context.go('/onboarding');
                }
              } else {
                context.go('/login');
              }
            } catch (loginError) {
              // Hvis auto-login feiler, gå til login-side
              if (!mounted) return;
              context.go('/login');
            }
          }
        }
      } else {
        throw Exception('Kunne ikke opprette bruker');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Feil ved opprettelse av konto: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('auth.signup'.tr()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ValidatedTextField(
                  label: 'auth.email'.tr(),
                  keyboardType: TextInputType.emailAddress,
                  showSuccessIcon: true,
                  validator: (value) {
                    final error = AuthValidators.email(value);
                    if (error == null && value != null && value.isNotEmpty) {
                      _checkEmailAvailability(value);
                    }
                    return error;
                  },
                  onChanged: (value) {
                    setState(() => _email = value);
                  },
                  helperText: _isCheckingEmail
                      ? 'Sjekker...'
                      : _isEmailAvailable && _email.isNotEmpty
                          ? 'Email er tilgjengelig ✓'
                          : null,
                ),
                const SizedBox(height: 24),
                
                PhoneNumberField(
                  validator: (value, countryCode) {
                    final error = AuthValidators.phoneNumber(value, countryCode);
                    if (error == null && value != null && value.isNotEmpty) {
                      _checkPhoneAvailability(value, countryCode);
                    }
                    return error;
                  },
                  onChanged: (phone, countryCode) {
                    setState(() {
                      _phoneNumber = phone;
                      _countryCode = countryCode;
                    });
                  },
                ),
                const SizedBox(height: 24),
                
                ValidatedTextField(
                  label: 'auth.username'.tr(),
                  showSuccessIcon: true,
                  validator: (value) {
                    final error = AuthValidators.username(value);
                    if (error == null && value != null && value.isNotEmpty) {
                      _checkUsernameAvailability(value);
                    }
                    return error;
                  },
                  onChanged: (value) {
                    setState(() => _username = value);
                  },
                  helperText: 'Velg et unikt brukernavn (3-20 tegn)',
                ),
                if (_isCheckingUsername)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Sjekker...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  )
                else if (_isUsernameAvailable && _username.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Brukernavn er tilgjengelig ✓',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                
                DatePickerField(
                  validator: (date) {
                    if (date == null) {
                      return 'Fødselsdato er påkrevd';
                    }
                    return null;
                  },
                  onChanged: (date) {
                    setState(() => _dateOfBirth = date);
                  },
                ),
                const SizedBox(height: 24),
                
                ValidatedTextField(
                  label: 'auth.password'.tr(),
                  obscureText: true,
                  validator: AuthValidators.password,
                  onChanged: (value) {
                    setState(() => _password = value);
                  },
                ),
                const SizedBox(height: 24),
                
                ValidatedTextField(
                  label: 'auth.confirm_password'.tr(),
                  obscureText: true,
                  validator: (value) => AuthValidators.confirmPassword(value, _password),
                ),
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('auth.create_account'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

