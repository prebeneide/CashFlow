import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/company_service.dart';
import '../auth/widgets/validated_text_field.dart';
import 'widgets/help_tooltip.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Grunnleggende informasjon
  final _companyNameController = TextEditingController();
  final _organizationNumberController = TextEditingController();
  String? _legalForm;

  // Step 2: Regnskapsinformasjon
  DateTime? _fiscalYearStart;
  String? _accountingStandard;

  // Step 3: MVA
  bool _vatRegistered = false;
  String? _vatNumber;

  // Step 4: Bransje
  String? _industry;
  String? _naceCode;

  final List<String> _legalForms = [
    'AS',
    'DA',
    'ENK',
    'ANS',
    'BA',
    'SF',
    'STI',
    'SA',
    'SP',
    'FK',
    'IKS',
    'KF',
    'HF',
    'UF',
  ];

  final List<String> _accountingStandards = [
    'NRS',
    'IFRS',
    'K3',
  ];

  final List<String> _industries = [
    'Landbruk, skogbruk og fiske',
    'Industri',
    'Bygge og anlegg',
    'Varehandel',
    'Transport og lagring',
    'Overnatting og servering',
    'Informasjon og kommunikasjon',
    'Finansiering og forsikring',
    'Eiendomsdrift',
    'Faglige, vitenskapelige og tekniske tjenester',
    'Administrative tjenester',
    'Offentlig forvaltning',
    'Undervisning',
    'Helse- og omsorgstjenester',
    'Kunst, underholdning og fritid',
    'Andre tjenester',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _companyNameController.dispose();
    _organizationNumberController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      if (_validateCurrentStep()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep++);
      }
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_companyNameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bedriftsnavn er påkrevd')),
          );
          return false;
        }
        if (_legalForm == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Juridisk form er påkrevd')),
          );
          return false;
        }
        return true;
      case 1:
        if (_fiscalYearStart == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Regnskapsår start er påkrevd')),
          );
          return false;
        }
        if (_accountingStandard == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Regnskapsstandard er påkrevd')),
          );
          return false;
        }
        return true;
      case 2:
        return true; // MVA er valgfritt
      case 3:
        if (_industry == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bransje er påkrevd')),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _completeOnboarding() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isLoading = true);

    try {
      await CompanyService.createCompany(
        name: _companyNameController.text.trim(),
        organizationNumber: _organizationNumberController.text.trim().isEmpty
            ? null
            : _organizationNumberController.text.trim(),
        industry: _industry,
        vatRegistered: _vatRegistered,
        defaultSettings: {
          'legal_form': _legalForm,
          'fiscal_year_start': _fiscalYearStart?.toIso8601String(),
          'accounting_standard': _accountingStandard,
          'vat_number': _vatNumber,
          'nace_code': _naceCode,
        },
      );

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Feil ved opprettelse av bedriftsprofil: $e'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Opprett bedriftsprofil'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    children: List.generate(4, (index) {
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(
                            right: index < 3 ? 8 : 0,
                          ),
                          decoration: BoxDecoration(
                            color: index <= _currentStep
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Steg ${_currentStep + 1} av 4',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _previousStep,
                        child: const Text('Tilbake'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _nextStep,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_currentStep == 3 ? 'Fullfør' : 'Neste'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Grunnleggende informasjon',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Vi trenger noen grunnleggende opplysninger om bedriften din. Dette hjelper oss med å sette opp regnskapet riktig.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ValidatedTextField(
                    label: 'Bedriftsnavn *',
                    controller: _companyNameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Bedriftsnavn er påkrevd';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                HelpTooltip(
                  question: 'Hva er bedriftsnavn?',
                  context: 'Bedriftsnavn er det offisielle navnet på bedriften din, slik det er registrert i Foretaksregisteret.',
                  staticHelp: 'Bedriftsnavnet er det navnet bedriften din er registrert med i Foretaksregisteret. Dette er ofte det samme navnet som står på fakturaer og offisielle dokumenter. Hvis du ikke er sikker, kan du sjekke på brreg.no.',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ValidatedTextField(
                    label: 'Organisasjonsnummer',
                    controller: _organizationNumberController,
                    keyboardType: TextInputType.number,
                    helperText: '9 sifre (valgfritt)',
                  ),
                ),
                const SizedBox(width: 8),
                HelpTooltip(
                  question: 'Hva er organisasjonsnummer?',
                  context: 'Organisasjonsnummer er et unikt 9-sifret nummer som alle norske bedrifter får når de registreres i Foretaksregisteret.',
                  staticHelp: 'Organisasjonsnummeret er et 9-sifret nummer som alle norske bedrifter har. Du finner det på brreg.no, på fakturaer, eller i dokumenter fra Skatteetaten. Det er valgfritt å fylle inn, men anbefales for bedre regnskapsføring.',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Juridisk form *',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                HelpTooltip(
                  question: 'Hva er juridisk form?',
                  context: 'Juridisk form er den juridiske strukturen til bedriften din, for eksempel AS, ENK, DA, etc.',
                  staticHelp: 'Juridisk form er den juridiske strukturen til bedriften din. Dette påvirker hvordan regnskapet føres og hvilke regler som gjelder. Du finner juridisk form på brreg.no eller i opprettelsesdokumentene til bedriften. Vanlige former er AS (Aksjeselskap), ENK (Enkeltpersonforetak), og DA (Ansvarlig selskap).',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _legalForms.map((form) {
                final isSelected = _legalForm == form;
                return FilterChip(
                  label: Text(form),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _legalForm = selected ? form : null);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Regnskapsinformasjon',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vi trenger å vite hvordan regnskapet ditt skal føres. Dette påvirker hvilke regler og standarder vi bruker.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Regnskapsår start *',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              HelpTooltip(
                question: 'Hva er regnskapsår?',
                context: 'Regnskapsår er den perioden regnskapet dekker, vanligvis 1. januar til 31. desember.',
                staticHelp: 'Regnskapsåret er den perioden regnskapet ditt dekker. For de fleste bedrifter er dette 1. januar til 31. desember (kalenderår). Noen bedrifter har et annet regnskapsår, for eksempel 1. april til 31. mars. Du finner dette i opprettelsesdokumentene eller på brreg.no. Hvis du ikke er sikker, velg 1. januar.',
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _fiscalYearStart ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                helpText: 'Velg regnskapsår start',
                locale: const Locale('nb', 'NO'),
              );
              if (picked != null) {
                setState(() => _fiscalYearStart = picked);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Regnskapsår start *',
                suffixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _fiscalYearStart != null
                    ? '${_fiscalYearStart!.day}.${_fiscalYearStart!.month}.${_fiscalYearStart!.year}'
                    : 'Velg dato',
                style: TextStyle(
                  color: _fiscalYearStart != null
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Regnskapsstandard *',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              HelpTooltip(
                question: 'Hva er regnskapsstandard?',
                context: 'Regnskapsstandard er settet med regler som bestemmer hvordan regnskapet skal føres.',
                staticHelp: 'Regnskapsstandarden bestemmer hvilke regler som gjelder for regnskapsføringen. NRS (Norsk Regnskapsstandard) er for små og mellomstore bedrifter. IFRS er for store bedrifter. K3 er en forenklet standard for små foretak. Hvis du ikke er sikker, velg NRS - det er den vanligste for de fleste bedrifter. Du kan alltid endre dette senere.',
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._accountingStandards.map((standard) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: RadioListTile<String>(
                title: Text(standard),
                value: standard,
                groupValue: _accountingStandard,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _accountingStandard = value);
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MVA (Merverdiavgift)',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'MVA er en avgift som legges til prisen på varer og tjenester. De fleste bedrifter må være MVA-registrert hvis omsetningen er over 50 000 kroner per år.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: const Text('MVA-registrert'),
                  value: _vatRegistered,
                  onChanged: (value) {
                    setState(() => _vatRegistered = value);
                  },
                ),
              ),
              HelpTooltip(
                question: 'Hva betyr MVA-registrert?',
                context: 'MVA-registrert betyr at bedriften din er registrert for å kreve inn og betale MVA.',
                staticHelp: 'Hvis bedriften din er MVA-registrert, må du legge til MVA på fakturaer og kan trekke fra MVA på kjøp. De fleste bedrifter med omsetning over 50 000 kroner per år må være MVA-registrert. Du finner ut om du er MVA-registrert på altinn.no eller i dokumenter fra Skatteetaten. Hvis du ikke er sikker, kan du velge "Nei" og endre det senere.',
              ),
            ],
          ),
          if (_vatRegistered) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ValidatedTextField(
                    label: 'MVA-nummer',
                    onChanged: (value) {
                      setState(() => _vatNumber = value);
                    },
                    helperText: 'Hvis du har MVA-nummer',
                  ),
                ),
                const SizedBox(width: 8),
                HelpTooltip(
                  question: 'Hva er MVA-nummer?',
                  context: 'MVA-nummer er et unikt nummer som MVA-registrerte bedrifter får.',
                  staticHelp: 'MVA-nummeret er et unikt nummer som MVA-registrerte bedrifter får. Du finner det på altinn.no, i dokumenter fra Skatteetaten, eller på fakturaer fra leverandører. Dette er valgfritt å fylle inn nå, men anbefales for bedre regnskapsføring.',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bransje og aktivitet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hvilken bransje er bedriften i? Dette hjelper oss med å forstå hva bedriften driver med og hvilke regler som gjelder.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Velg bransje *',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              HelpTooltip(
                question: 'Hvorfor trenger vi bransje?',
                context: 'Bransjen påvirker hvilke regler og regnskapsregler som gjelder for bedriften din.',
                staticHelp: 'Bransjen din påvirker hvilke regler som gjelder for regnskapsføringen. For eksempel har restauranter og transport spesielle MVA-regler. Velg den bransjen som best beskriver hovedaktiviteten til bedriften din. Hvis du ikke er sikker, velg "Andre tjenester" - du kan alltid endre dette senere.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._industries.map((industry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: RadioListTile<String>(
                title: Text(industry),
                value: industry,
                groupValue: _industry,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _industry = value);
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

