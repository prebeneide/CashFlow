import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/company_service.dart';
import '../../core/services/api_service.dart';
import '../../core/validators/company_validators.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/glass_card.dart';
import '../auth/widgets/validated_text_field.dart';
import 'widgets/enhanced_validated_field.dart';
import 'widgets/help_tooltip.dart';
import 'widgets/more_info_button.dart';

class HybridOnboardingPage extends StatefulWidget {
  const HybridOnboardingPage({super.key});

  @override
  State<HybridOnboardingPage> createState() => _HybridOnboardingPageState();
}

class _HybridOnboardingPageState extends State<HybridOnboardingPage> {
  final PageController _pageController = PageController();
  final ScrollController _chatScrollController = ScrollController();
  final TextEditingController _chatMessageController = TextEditingController();
  final List<ChatMessage> _chatMessages = [];

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isChatLoading = false;

  // Form data
  final _companyNameController = TextEditingController();
  final _organizationNumberController = TextEditingController();
  final _vatNumberController = TextEditingController();
  String? _legalForm;
  DateTime? _fiscalYearStart;
  String? _accountingStandard;
  bool _vatRegistered = false;
  String? _industry;

  final List<String> _legalForms = ['AS', 'DA', 'ENK', 'ANS', 'BA', 'SF', 'STI', 'SA', 'SP', 'FK', 'IKS', 'KF', 'HF', 'UF'];
  final List<String> _accountingStandards = ['NRS', 'IFRS', 'K3'];
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
  void initState() {
    super.initState();
    _startChat();
    // Lytte på endringer i bedriftsnavn med debounce
    _companyNameController.addListener(_onCompanyNameControllerChanged);
  }

  void _onCompanyNameControllerChanged() {
    final value = _companyNameController.text;
    _onCompanyNameChanged(value);
  }

  void _startChat() {
    _addChatMessage('assistant', 
        'Hei! 👋 Jeg er din regnskapsassistent. Jeg skal hjelpe deg sette opp regnskapet ditt steg for steg.\n\n'
        'La oss starte med grunnleggende informasjon om bedriften din. Fyll ut skjemaet til høyre, og jeg kommenterer hvert steg!');
  }

  void _addChatMessage(String role, String content) {
    setState(() {
      _chatMessages.add(ChatMessage(
        role: role,
        content: content,
        timestamp: DateTime.now(),
      ));
    });
    _scrollChatToBottom();
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendChatMessage(String message) async {
    if (message.trim().isEmpty) return;

    _addChatMessage('user', message);
    _chatMessageController.clear();
    setState(() => _isChatLoading = true);

    try {
      // Send hele chat-historikken + kontekst til backend
      final chatHistory = _chatMessages.map((msg) => ({
        'role': msg.role,
        'content': msg.content,
      })).toList();

      final response = await ApiService.post('/ai/chat', data: {
        'message': message,
        'chatHistory': chatHistory,
        'context': {
          'currentStep': _currentStep,
          'totalSteps': 4,
          'filledData': _getFilledData(),
          'stepNames': [
            'Grunnleggende informasjon',
            'Regnskapsinformasjon',
            'MVA (Merverdiavgift)',
            'Bransje og aktivitet',
          ],
        },
      });

      final aiResponse = response.data['response'] as String? ?? 
          'Takk for spørsmålet! La meg hjelpe deg videre.';
      
      setState(() => _isChatLoading = false);
      _addChatMessage('assistant', aiResponse);
    } catch (e) {
      setState(() => _isChatLoading = false);
      _addChatMessage('assistant', 
          'Beklager, jeg kunne ikke svare akkurat nå. Prøv å fylle ut skjemaet, eller prøv igjen senere.');
    }
  }

  Map<String, dynamic> _getFilledData() {
    return {
      'companyName': _companyNameController.text.trim(),
      'organizationNumber': _organizationNumberController.text.trim(),
      'legalForm': _legalForm,
      'fiscalYearStart': _fiscalYearStart?.toIso8601String(),
      'accountingStandard': _accountingStandard,
      'vatRegistered': _vatRegistered,
      'vatNumber': _vatNumberController.text.trim(),
      'industry': _industry,
    };
  }

  String? _lastCommentedCompanyName;
  Timer? _debounceTimer;
  
  void _onCompanyNameChanged(String value) {
    // Debounce - vent til brukeren har stoppet å skrive i 2 sekunder
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      final companyName = value.trim();
      // Sjekk at teksten ikke har endret seg siden timeren startet
      if (companyName.isNotEmpty && 
          companyName == _companyNameController.text.trim() &&
          companyName != _lastCommentedCompanyName &&
          companyName.length >= 3 &&
          _currentStep == 0) {
        _lastCommentedCompanyName = companyName;
        _addChatMessage('assistant', 
            'Flott! Jeg ser at bedriften din heter "$companyName". '
            'Fortsett med å fylle ut resten av informasjonen.');
      }
    });
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _companyNameController.removeListener(_onCompanyNameControllerChanged);
    _pageController.dispose();
    _chatScrollController.dispose();
    _chatMessageController.dispose();
    _companyNameController.dispose();
    _organizationNumberController.dispose();
    _vatNumberController.dispose();
    super.dispose();
  }
  
  void _onStepChanged(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = step);
    
    // AI kommenterer steg-endringer
    _commentOnStepChange(step);
  }

  void _commentOnStepChange(int step) {
    String comment = '';
    switch (step) {
      case 0:
        comment = 'La oss starte med grunnleggende informasjon om bedriften din. Fyll ut navn, organisasjonsnummer og juridisk form.';
        break;
      case 1:
        comment = 'Nå skal vi sette opp regnskapsinformasjonen. Dette påvirker hvordan regnskapet føres.';
        break;
      case 2:
        comment = 'MVA (Merverdiavgift) er viktig for de fleste bedrifter. La meg hjelpe deg finne ut om du er MVA-registrert.';
        break;
      case 3:
        comment = 'Til slutt trenger vi å vite hvilken bransje bedriften din er i. Dette hjelper oss med å tilpasse regnskapet.';
        break;
    }
    
    if (comment.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _addChatMessage('assistant', comment);
      });
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 3) {
        _onStepChanged(_currentStep + 1);
      } else {
        _completeOnboarding();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _onStepChanged(_currentStep - 1);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_companyNameController.text.trim().isEmpty) {
          _showError('Bedriftsnavn er påkrevd');
          return false;
        }
        if (_legalForm == null) {
          _showError('Juridisk form er påkrevd');
          return false;
        }
        return true;
      case 1:
        if (_fiscalYearStart == null) {
          _showError('Regnskapsår start er påkrevd');
          return false;
        }
        if (_accountingStandard == null) {
          _showError('Regnskapsstandard er påkrevd');
          return false;
        }
        return true;
      case 2:
        return true; // MVA er valgfritt
      case 3:
        if (_industry == null) {
          _showError('Bransje er påkrevd');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);
    _addChatMessage('assistant', 'Perfekt! Jeg setter opp bedriftsprofilen din nå...');

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
          'vat_number': _vatNumberController.text.trim().isNotEmpty ? _vatNumberController.text.trim() : null,
        },
      );

      _addChatMessage('assistant', '🎉 Flott! Bedriftsprofilen din er nå opprettet. La meg ta deg videre til dashboardet!');
      
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _addChatMessage('assistant', 'Beklager, det oppstod en feil ved opprettelse av bedriftsprofilen. Prøv igjen!');
      // Vis teknisk feilmelding i en snackbar slik at vi kan feilsøke videre
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Feil ved opprettelse av bedriftsprofil: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Opprett bedriftsprofil'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark 
              ? AppColors.backgroundGradientDark 
              : AppColors.backgroundGradientLight,
        ),
        child: Row(
          children: [
            // Chat panel (venstre side)
            Container(
              width: 400,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.white.withValues(alpha: 0.5),
                border: Border(
                  right: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.zero,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    children: [
                      // Chat header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.3),
                          border: Border(
                            bottom: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.05),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.smart_toy,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Regnskapsassistent',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Chat messages
                      Expanded(
                        child: ListView.builder(
                          controller: _chatScrollController,
                          padding: const EdgeInsets.all(20),
                          itemCount: _chatMessages.length + (_isChatLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _chatMessages.length && _isChatLoading) {
                              return _buildTypingIndicator();
                            }
                            return _buildChatMessage(_chatMessages[index]);
                          },
                        ),
                      ),
                      
                      // Chat input
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.3),
                          border: Border(
                            top: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.05),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.08),
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  controller: _chatMessageController,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  decoration: InputDecoration(
                                    hintText: 'Stil et spørsmål...',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                  ),
                                  maxLines: null,
                                  textCapitalization: TextCapitalization.sentences,
                                  onSubmitted: _isChatLoading ? null : (text) => _sendChatMessage(text),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: _isChatLoading
                                    ? null
                                    : () => _sendChatMessage(_chatMessageController.text),
                                icon: const Icon(Icons.send, color: Colors.white),
                                padding: const EdgeInsets.all(14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Form panel (høyre side)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // Progress indicator
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        children: [
                          Row(
                            children: List.generate(4, (index) {
                              return Expanded(
                                child: Container(
                                  height: 6,
                                  margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                                  decoration: BoxDecoration(
                                    gradient: index <= _currentStep
                                        ? AppColors.primaryGradient
                                        : LinearGradient(
                                            colors: [
                                              isDark
                                                  ? Colors.white.withValues(alpha: 0.1)
                                                  : Colors.black.withValues(alpha: 0.1),
                                              isDark
                                                  ? Colors.white.withValues(alpha: 0.05)
                                                  : Colors.black.withValues(alpha: 0.05),
                                            ],
                                          ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Steg ${_currentStep + 1} av 4',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Form content
                    SizedBox(
                      height: 600,
                      child: GlassCard(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    final isUser = message.role == 'user';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomRight: isUser ? const Radius.circular(4) : null,
                bottomLeft: !isUser ? const Radius.circular(4) : null,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? AppColors.primaryGradient
                        : LinearGradient(
                            colors: isDark
                                ? [
                                    Colors.white.withValues(alpha: 0.1),
                                    Colors.white.withValues(alpha: 0.05),
                                  ]
                                : [
                                    Colors.white.withValues(alpha: 0.8),
                                    Colors.white.withValues(alpha: 0.6),
                                  ],
                          ),
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomRight: isUser ? const Radius.circular(4) : null,
                      bottomLeft: !isUser ? const Radius.circular(4) : null,
                    ),
                    border: Border.all(
                      color: isUser
                          ? Colors.transparent
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05)),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.shade400,
                    Colors.grey.shade600,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            Colors.white.withValues(alpha: 0.1),
                            Colors.white.withValues(alpha: 0.05),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.8),
                            Colors.white.withValues(alpha: 0.6),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
                child: const SizedBox(
                  width: 40,
                  height: 20,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grunnleggende informasjon',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
              const HelpTooltip(
                question: 'Hva er bedriftsnavn?',
                context: 'Bedriftsnavn er det offisielle navnet på bedriften din, slik det er registrert i Foretaksregisteret.',
                staticHelp:
                    'Bedriftsnavnet er det navnet bedriften din er registrert med i Foretaksregisteret. Dette er ofte det samme navnet som står på fakturaer og offisielle dokumenter. Hvis du ikke er sikker, kan du sjekke på brreg.no.',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: EnhancedValidatedField(
                  label: 'Organisasjonsnummer',
                  controller: _organizationNumberController,
                  keyboardType: TextInputType.number,
                  helperText: '9 sifre (valgfritt)',
                  requiredLength: 9,
                  validator: CompanyValidators.organizationNumber,
                ),
              ),
              const SizedBox(width: 8),
              const HelpTooltip(
                question: 'Hva er organisasjonsnummer?',
                context:
                    'Organisasjonsnummer er et unikt 9-sifret nummer som alle norske bedrifter får når de registreres i Foretaksregisteret.',
                staticHelp:
                    'Organisasjonsnummeret er et 9-sifret nummer som alle norske bedrifter har. Du finner det på brreg.no, på fakturaer, eller i dokumenter fra Skatteetaten. Det er valgfritt å fylle inn, men anbefales for bedre regnskapsføring. Nummeret valideres automatisk med Modulo 11-algoritmen.',
              ),
            ],
          ),
          const SizedBox(height: 8),
          MoreInfoButton(
            topic: 'Organisasjonsnummer - alt du trenger å vite',
            context: 'Brukeren lurer på organisasjonsnummer. Forklar hva det er, hvor man finner det, hvorfor det er viktig, og hva som skjer hvis man ikke fyller det inn.',
            detailedInfo: 'Organisasjonsnummeret er et unikt identifikasjonsnummer som alle norske bedrifter får ved registrering i Foretaksregisteret. Det består av 9 sifre og brukes til å identifisere bedriften i alle offisielle dokumenter, fakturaer, og kommunikasjon med myndigheter.\n\nHvor finner du det?\n- På brreg.no (søk etter bedriftsnavnet)\n- På fakturaer fra leverandører\n- I dokumenter fra Skatteetaten\n- I opprettelsesdokumentene til bedriften\n\nHvorfor er det viktig?\n- Gjør regnskapsføringen mer nøyaktig\n- Hjelper med automatisk matching av transaksjoner\n- Kreves for offisielle rapporter og eksport\n\nHva skjer hvis du ikke fyller det inn?\n- Du kan fortsatt opprette bedriftsprofilen\n- Men noen funksjoner kan være begrenset\n- Du kan alltid legge det til senere',
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
              const HelpTooltip(
                question: 'Hva er juridisk form?',
                context: 'Juridisk form er den juridiske strukturen til bedriften din, for eksempel AS, ENK, DA, etc.',
                staticHelp:
                    'Juridisk form er den juridiske strukturen til bedriften din. Dette påvirker hvordan regnskapet føres og hvilke regler som gjelder. Du finner juridisk form på brreg.no eller i opprettelsesdokumentene til bedriften. Vanlige former er AS (Aksjeselskap), ENK (Enkeltpersonforetak), og DA (Ansvarlig selskap).',
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
                  setState(() {
                    _legalForm = selected ? form : null;
                  });
                  if (selected) {
                    _addChatMessage('assistant', 
                        'Bra valg! Du har valgt $form. Fortsett med å fylle ut resten.');
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
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
              const HelpTooltip(
                question: 'Hva er regnskapsår?',
                context: 'Regnskapsår er den perioden regnskapet dekker, vanligvis 1. januar til 31. desember.',
                staticHelp:
                    'Regnskapsåret er den perioden regnskapet ditt dekker. For de fleste bedrifter er dette 1. januar til 31. desember (kalenderår). Noen bedrifter har et annet regnskapsår, for eksempel 1. april til 31. mars. Du finner dette i opprettelsesdokumentene eller på brreg.no. Hvis du ikke er sikker, velg 1. januar.',
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
              const HelpTooltip(
                question: 'Hva er regnskapsstandard?',
                context: 'Regnskapsstandard er settet med regler som bestemmer hvordan regnskapet skal føres.',
                staticHelp:
                    'Regnskapsstandarden bestemmer hvilke regler som gjelder for regnskapsføringen. NRS (Norsk Regnskapsstandard) er for små og mellomstore bedrifter. IFRS er for store bedrifter. K3 er en forenklet standard for små foretak. Hvis du ikke er sikker, velg NRS - det er den vanligste for de fleste bedrifter. Du kan alltid endre dette senere.',
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
                    _addChatMessage('assistant', 
                        'Bra! Du har valgt $standard. Dette er en god standard for de fleste bedrifter.');
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
              const HelpTooltip(
                question: 'Hva betyr MVA-registrert?',
                context: 'MVA-registrert betyr at bedriften din er registrert for å kreve inn og betale MVA.',
                staticHelp:
                    'Hvis bedriften din er MVA-registrert, må du legge til MVA på fakturaer og kan trekke fra MVA på kjøp. De fleste bedrifter med omsetning over 50 000 kroner per år må være MVA-registrert. Du finner ut om du er MVA-registrert på altinn.no eller i dokumenter fra Skatteetaten. Hvis du ikke er sikker, kan du velge \"Nei\" og endre det senere.',
              ),
            ],
          ),
          if (_vatRegistered) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: EnhancedValidatedField(
                    label: 'MVA-nummer',
                    controller: _vatNumberController,
                    helperText: '8-9 sifre (valgfritt)',
                    requiredLength: 8,
                    validator: CompanyValidators.vatNumber,
                    onChanged: (value) {
                      // Value is automatically stored in controller
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const HelpTooltip(
                  question: 'Hva er MVA-nummer?',
                  context: 'MVA-nummer er et unikt nummer som MVA-registrerte bedrifter får.',
                  staticHelp:
                      'MVA-nummeret er et unikt nummer som MVA-registrerte bedrifter får. Du finner det på altinn.no, i dokumenter fra Skatteetaten, eller på fakturaer fra leverandører. Dette er valgfritt å fylle inn nå, men anbefales for bedre regnskapsføring.',
                ),
              ],
            ),
            const SizedBox(height: 8),
            MoreInfoButton(
              topic: 'MVA-nummer - alt du trenger å vite',
              context: 'Brukeren lurer på MVA-nummer. Forklar hva det er, hvor man finner det, og hvorfor det er viktig.',
              detailedInfo: 'MVA-nummeret er et unikt identifikasjonsnummer som MVA-registrerte bedrifter får fra Skatteetaten. Det brukes til å identifisere bedriften i MVA-meldinger og offisielle dokumenter.\n\nHvor finner du det?\n- På altinn.no (logg inn og se bedriftsinformasjon)\n- I dokumenter fra Skatteetaten\n- På fakturaer fra leverandører\n- I MVA-meldinger\n\nHvorfor er det viktig?\n- Gjør MVA-meldinger enklere\n- Hjelper med automatisk matching av MVA-transaksjoner\n- Kreves for offisielle MVA-rapporter\n\nHva skjer hvis du ikke fyller det inn?\n- Du kan fortsatt opprette bedriftsprofilen\n- Men MVA-funksjonalitet kan være begrenset\n- Du kan alltid legge det til senere',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
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
              const HelpTooltip(
                question: 'Hvorfor trenger vi bransje?',
                context: 'Bransjen påvirker hvilke regler og regnskapsregler som gjelder for bedriften din.',
                staticHelp:
                    'Bransjen din påvirker hvilke regler som gjelder for regnskapsføringen. For eksempel har restauranter og transport spesielle MVA-regler. Velg den bransjen som best beskriver hovedaktiviteten til bedriften din. Hvis du ikke er sikker, velg \"Andre tjenester\" - du kan alltid endre dette senere.',
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
                    _addChatMessage('assistant', 
                        'Perfekt! Jeg ser at bedriften din er i bransjen "$value". '
                        'Dette hjelper oss med å tilpasse regnskapet til din bransje.');
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

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

