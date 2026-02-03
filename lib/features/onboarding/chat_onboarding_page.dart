import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/company_service.dart';
import '../../core/services/api_service.dart';

class ChatOnboardingPage extends StatefulWidget {
  const ChatOnboardingPage({super.key});

  @override
  State<ChatOnboardingPage> createState() => _ChatOnboardingPageState();
}

class _ChatOnboardingPageState extends State<ChatOnboardingPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;

  // Onboarding data
  String? _companyName;
  String? _organizationNumber;
  String? _legalForm;
  DateTime? _fiscalYearStart;
  String? _accountingStandard;
  bool? _vatRegistered;
  String? _vatNumber;
  String? _industry;

  // Current step context
  String _currentStep = 'introduction';

  @override
  void initState() {
    super.initState();
    _startOnboarding();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _startOnboarding() {
    _addMessage(
      'assistant',
      'Hei! 👋 Jeg er din AI-regnskapsassistent. Jeg skal hjelpe deg sette opp regnskapet ditt steg for steg. Det tar bare noen minutter, og jeg forklarer alt underveis.\n\nLa oss starte! Hva heter bedriften din?',
      showTyping: false,
    );
    _currentStep = 'company_name';
  }

  void _addMessage(String role, String content, {bool showTyping = false}) {
    setState(() {
      _messages.add(ChatMessage(
        role: role,
        content: content,
        timestamp: DateTime.now(),
      ));
      if (showTyping) {
        _isTyping = true;
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    _addMessage('user', message);
    _messageController.clear();
    setState(() => _isLoading = true);

    try {
      // Send til AI med kontekst
      final response = await ApiService.post('/ai/chat', data: {
        'message': message,
        'context': {
          'currentStep': _currentStep,
          'filledData': {
            'companyName': _companyName,
            'organizationNumber': _organizationNumber,
            'legalForm': _legalForm,
            'fiscalYearStart': _fiscalYearStart?.toIso8601String(),
            'accountingStandard': _accountingStandard,
            'vatRegistered': _vatRegistered,
            'vatNumber': _vatNumber,
            'industry': _industry,
          },
        },
      });

      final aiResponse = response.data['response'] as String? ?? 
          'Takk for informasjonen! La meg hjelpe deg videre.';
      final suggestions = response.data['suggestions'] as List<dynamic>?;

      setState(() => _isLoading = false);
      _isTyping = false;

      // Oppdater kontekst basert på meldingen hvis vi er på første steg
      if ((_currentStep == 'company_name' || _currentStep == 'introduction') && 
          message.trim().isNotEmpty && 
          _companyName == null) {
        setState(() {
          _companyName = message.trim();
        });
      }

      _addMessage('assistant', aiResponse);

      // Hvis AI foreslår valg, legg dem til
      if (suggestions != null && suggestions.isNotEmpty) {
        _addSuggestions(suggestions);
      }

      // Sjekk om vi kan fullføre onboarding
      if (_canCompleteOnboarding()) {
        Future.delayed(const Duration(seconds: 1), () {
          _completeOnboarding();
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _isTyping = false;
      
      // Fallback: Bruk enkel logikk hvis backend ikke svarer
      _handleMessageWithFallback(message);
    }
  }

  void _handleMessageWithFallback(String message) {
    // Enkel fallback-logikk som fungerer uten backend
    if (_currentStep == 'company_name' || _currentStep == 'introduction') {
      // Hvis vi er på første steg og brukeren skriver noe, behandle det som bedriftsnavn
      if (message.trim().isNotEmpty) {
        setState(() {
          _companyName = message.trim();
          _currentStep = 'legal_form';
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          _addMessage('assistant', 
              'Flott! Jeg ser at bedriften din heter "${message.trim()}". '
              'Hvilken juridisk form har bedriften din?');
          _addSuggestions([
            {'type': 'fill_field', 'label': 'AS (Aksjeselskap)', 'data': {'field': 'legalForm', 'value': 'AS'}},
            {'type': 'fill_field', 'label': 'ENK (Enkeltpersonforetak)', 'data': {'field': 'legalForm', 'value': 'ENK'}},
            {'type': 'fill_field', 'label': 'DA (Ansvarlig selskap)', 'data': {'field': 'legalForm', 'value': 'DA'}},
            {'type': 'fill_field', 'label': 'ANS (Ansvarlig selskap)', 'data': {'field': 'legalForm', 'value': 'ANS'}},
          ]);
        });
        return;
      }
    } else if (_currentStep == 'legal_form' && _legalForm == null) {
      // Sjekk om meldingen matcher en juridisk form
      final legalForms = {'AS': 'AS', 'ENK': 'ENK', 'DA': 'DA', 'ANS': 'ANS'};
      final matchedForm = legalForms.entries.firstWhere(
        (entry) => message.toUpperCase().contains(entry.key),
        orElse: () => const MapEntry('', ''),
      );
      
      if (matchedForm.key.isNotEmpty) {
        setState(() {
          _legalForm = matchedForm.value;
          _currentStep = 'accounting_standard';
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          _addMessage('assistant', 
              'Perfekt! Du har valgt ${matchedForm.value}. '
              'Hvilken regnskapsstandard skal bedriften din bruke?');
          _addSuggestions([
            {'type': 'fill_field', 'label': 'NRS (Norsk Regnskapsstandard)', 'data': {'field': 'accountingStandard', 'value': 'NRS'}},
            {'type': 'fill_field', 'label': 'IFRS (International Financial Reporting Standards)', 'data': {'field': 'accountingStandard', 'value': 'IFRS'}},
            {'type': 'fill_field', 'label': 'K3 (Kunngjøringsforskriften)', 'data': {'field': 'accountingStandard', 'value': 'K3'}},
          ]);
        });
      } else {
        _addMessage('assistant', 
            'Jeg forstod ikke hvilken juridisk form du mente. '
            'Vennligst velg en av alternativene over, eller skriv AS, ENK, DA, eller ANS.');
      }
    } else if (_currentStep == 'accounting_standard' && _accountingStandard == null) {
      final standards = {'NRS': 'NRS', 'IFRS': 'IFRS', 'K3': 'K3'};
      final matchedStandard = standards.entries.firstWhere(
        (entry) => message.toUpperCase().contains(entry.key),
        orElse: () => const MapEntry('', ''),
      );
      
      if (matchedStandard.key.isNotEmpty) {
        setState(() {
          _accountingStandard = matchedStandard.value;
          _currentStep = 'vat';
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          _addMessage('assistant', 
              'Bra valg! Er bedriften din MVA-registrert?');
          _addSuggestions([
            {'type': 'fill_field', 'label': 'Ja, jeg er MVA-registrert', 'data': {'field': 'vatRegistered', 'value': true}},
            {'type': 'fill_field', 'label': 'Nei, jeg er ikke MVA-registrert', 'data': {'field': 'vatRegistered', 'value': false}},
          ]);
        });
      }
    } else if (_currentStep == 'vat' && _vatRegistered == null) {
      if (message.toLowerCase().contains('ja') || message.toLowerCase().contains('yes')) {
        setState(() {
          _vatRegistered = true;
          _currentStep = 'industry';
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          _addMessage('assistant', 
              'Takk! Hvilken bransje er bedriften din i?');
          _addSuggestions([
            {'type': 'fill_field', 'label': 'Konsulenttjenester', 'data': {'field': 'industry', 'value': 'Konsulenttjenester'}},
            {'type': 'fill_field', 'label': 'Varehandel', 'data': {'field': 'industry', 'value': 'Varehandel'}},
            {'type': 'fill_field', 'label': 'Restaurant', 'data': {'field': 'industry', 'value': 'Restaurant'}},
            {'type': 'fill_field', 'label': 'Bygge og anlegg', 'data': {'field': 'industry', 'value': 'Bygge og anlegg'}},
            {'type': 'fill_field', 'label': 'Annet', 'data': {'field': 'industry', 'value': 'Annet'}},
          ]);
        });
      } else if (message.toLowerCase().contains('nei') || message.toLowerCase().contains('no')) {
        setState(() {
          _vatRegistered = false;
          _currentStep = 'industry';
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          _addMessage('assistant', 
              'Takk! Hvilken bransje er bedriften din i?');
          _addSuggestions([
            {'type': 'fill_field', 'label': 'Konsulenttjenester', 'data': {'field': 'industry', 'value': 'Konsulenttjenester'}},
            {'type': 'fill_field', 'label': 'Varehandel', 'data': {'field': 'industry', 'value': 'Varehandel'}},
            {'type': 'fill_field', 'label': 'Restaurant', 'data': {'field': 'industry', 'value': 'Restaurant'}},
            {'type': 'fill_field', 'label': 'Bygge og anlegg', 'data': {'field': 'industry', 'value': 'Bygge og anlegg'}},
            {'type': 'fill_field', 'label': 'Annet', 'data': {'field': 'industry', 'value': 'Annet'}},
          ]);
        });
      }
    } else if (_currentStep == 'industry' && _industry == null && _canCompleteOnboarding()) {
      setState(() {
        _industry = message.trim();
      });
      _completeOnboarding();
    } else {
      // Hvis vi ikke forstår meldingen, gi en hjelpsom respons basert på nåværende steg
      if (_currentStep == 'company_name' || _currentStep == 'introduction') {
        _addMessage('assistant', 
            'Jeg trenger navnet på bedriften din. Skriv navnet på bedriften, for eksempel "Min Bedrift AS".');
      } else if (_currentStep == 'legal_form') {
        _addMessage('assistant', 
            'Vennligst velg juridisk form ved å trykke på en av knappene over, eller skriv AS, ENK, DA, eller ANS.');
      } else if (_currentStep == 'accounting_standard') {
        _addMessage('assistant', 
            'Vennligst velg regnskapsstandard ved å trykke på en av knappene over, eller skriv NRS, IFRS, eller K3.');
      } else if (_currentStep == 'vat') {
        _addMessage('assistant', 
            'Er bedriften din MVA-registrert? Trykk på "Ja" eller "Nei" over, eller skriv ja/nei.');
      } else if (_currentStep == 'industry') {
        _addMessage('assistant', 
            'Vennligst velg bransje ved å trykke på en av knappene over.');
      } else {
        _addMessage('assistant', 
            'Beklager, jeg forstod ikke. Kan du prøve igjen eller velge et av alternativene?');
      }
    }
  }

  void _addSuggestions(List<dynamic> suggestions) {
    setState(() {
      _messages.add(ChatMessage(
        role: 'suggestions',
        content: '',
        suggestions: suggestions,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  bool _canCompleteOnboarding() {
    return _companyName != null &&
        _companyName!.isNotEmpty &&
        _legalForm != null &&
        _legalForm!.isNotEmpty;
  }

  void _handleSuggestion(dynamic suggestion) {
    // Håndter forslag basert på type
    final type = suggestion['type'] as String?;
    final data = suggestion['data'] as Map<String, dynamic>?;

    if (type == 'fill_field') {
      final field = data?['field'] as String?;
      final value = data?['value'];
      
      setState(() {
        if (field == 'companyName') {
          _companyName = value as String?;
        } else if (field == 'legalForm') {
          _legalForm = value as String?;
        } else if (field == 'accountingStandard') {
          _accountingStandard = value as String?;
        } else if (field == 'vatRegistered') {
          _vatRegistered = value as bool?;
        } else if (field == 'industry') {
          _industry = value as String?;
        }
      });

      // Send melding til AI om at brukeren har valgt
      _sendMessage('Jeg velger: ${suggestion['label'] ?? value}');
    } else if (type == 'next_step') {
      setState(() {
        _currentStep = data?['step'] as String? ?? _currentStep;
      });
      _sendMessage('Jeg er klar for neste steg');
    }
  }

  Future<void> _completeOnboarding() async {
    if (_companyName == null || _legalForm == null) {
      _addMessage('assistant', 'Vi trenger litt mer informasjon først. La meg hjelpe deg videre!');
      return;
    }

    setState(() => _isLoading = true);
    _addMessage('assistant', 'Perfekt! Jeg setter opp bedriftsprofilen din nå...');

    try {
      await CompanyService.createCompany(
        name: _companyName!,
        organizationNumber: _organizationNumber,
        industry: _industry,
        vatRegistered: _vatRegistered ?? false,
        defaultSettings: {
          'legal_form': _legalForm,
          'fiscal_year_start': _fiscalYearStart?.toIso8601String(),
          'accounting_standard': _accountingStandard,
          'vat_number': _vatNumber,
        },
      );

      _addMessage('assistant', '🎉 Flott! Bedriftsprofilen din er nå opprettet. La meg ta deg videre til dashboardet!');
      
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _addMessage('assistant', 'Beklager, det oppstod en feil ved opprettelse av bedriftsprofilen. Prøv igjen!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opprett bedriftsprofil'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessage(_messages[index]);
              },
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Skriv et spørsmål eller svar...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: _isLoading ? null : (text) => _sendMessage(text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isLoading
                        ? null
                        : () => _sendMessage(_messageController.text),
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    if (message.role == 'suggestions') {
      return _buildSuggestions(message.suggestions ?? []);
    }

    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.smart_toy,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : null,
                  bottomLeft: !isUser ? const Radius.circular(4) : null,
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.person,
                size: 18,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestions(List<dynamic> suggestions) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((suggestion) {
          return ChoiceChip(
            label: Text(suggestion['label'] ?? ''),
            selected: false,
            onSelected: (_) => _handleSuggestion(suggestion),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.smart_toy,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const SizedBox(
              width: 40,
              height: 20,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;
  final List<dynamic>? suggestions;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.suggestions,
  });
}

